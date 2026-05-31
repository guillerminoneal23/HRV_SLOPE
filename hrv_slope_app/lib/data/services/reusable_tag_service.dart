library;

import 'dart:convert';

import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/daos/settings_dao.dart';

enum ReusableTagCategory {
  sessionTask('SessionTask'),
  sport('Sport'),
  protocol('Protocol'),
  contextEnvironment('ContextEnvironment');

  final String key;
  const ReusableTagCategory(this.key);

  static ReusableTagCategory? fromKey(String key) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return null;
  }
}

class ReusableTag {
  final String name;
  final String normalizedName;
  final ReusableTagCategory category;
  final bool isSystem;
  final bool isActive;
  final String createdAt;

  const ReusableTag({
    required this.name,
    required this.normalizedName,
    required this.category,
    required this.isSystem,
    required this.isActive,
    required this.createdAt,
  });

  factory ReusableTag.create({
    required ReusableTagCategory category,
    required String name,
    bool isSystem = false,
    DateTime? createdAt,
  }) {
    return ReusableTag(
      name: ReusableTagService.displayName(name),
      normalizedName: ReusableTagService.normalizeName(name),
      category: category,
      isSystem: isSystem,
      isActive: true,
      createdAt: (createdAt ?? DateTime.now()).toIso8601String(),
    );
  }

  factory ReusableTag.fromJson(
    ReusableTagCategory category,
    Map<String, Object?> json,
  ) {
    final name = (json['name'] as String?) ?? '';
    return ReusableTag(
      name: ReusableTagService.displayName(name),
      normalizedName:
          (json['normalizedName'] as String?) ??
          ReusableTagService.normalizeName(name),
      category: category,
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'normalizedName': normalizedName,
      'isSystem': isSystem,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

class ReusableTagCatalog {
  final Map<ReusableTagCategory, List<ReusableTag>> tagsByCategory;

  const ReusableTagCatalog(this.tagsByCategory);

  factory ReusableTagCatalog.empty() {
    return ReusableTagCatalog({
      for (final category in ReusableTagCategory.values) category: [],
    });
  }

  factory ReusableTagCatalog.fromJson(Map<String, Object?> json) {
    final catalog = ReusableTagCatalog.empty().tagsByCategory.map(
      (key, value) => MapEntry(key, List<ReusableTag>.from(value)),
    );
    for (final entry in json.entries) {
      final category = ReusableTagCategory.fromKey(entry.key);
      final rawTags = entry.value;
      if (category == null || rawTags is! List) continue;
      catalog[category] = rawTags
          .whereType<Map>()
          .map(
            (raw) =>
                ReusableTag.fromJson(category, raw.cast<String, Object?>()),
          )
          .where((tag) => tag.name.isNotEmpty && tag.normalizedName.isNotEmpty)
          .toList();
    }
    return ReusableTagCatalog(catalog);
  }

  List<ReusableTag> getTagsByCategory(ReusableTagCategory category) {
    final tags = tagsByCategory[category] ?? const <ReusableTag>[];
    return tags.where((tag) => tag.isActive).toList(growable: false);
  }

  Map<String, Object?> toJson() {
    return {
      for (final category in ReusableTagCategory.values)
        category.key: (tagsByCategory[category] ?? const <ReusableTag>[])
            .map((tag) => tag.toJson())
            .toList(),
    };
  }
}

class ReusableTagService {
  static const settingsKey = 'reusable_tag_catalog_v1';

  final SettingsDao settingsDao;

  const ReusableTagService(this.settingsDao);

  Future<ReusableTagCatalog> getCatalog() async {
    final catalog = await _readCatalog();
    final seeded = _withSystemTags(catalog);
    if (!_catalogEquals(catalog, seeded)) {
      await _writeCatalog(seeded);
    }
    return seeded;
  }

  Future<List<ReusableTag>> getTagsByCategory(
    ReusableTagCategory category,
  ) async {
    final catalog = await getCatalog();
    return catalog.getTagsByCategory(category);
  }

  Future<bool> containsTag(ReusableTagCategory category, String name) async {
    final normalized = normalizeName(name);
    if (normalized.isEmpty) return false;
    final tags = await getTagsByCategory(category);
    return tags.any((tag) => tag.normalizedName == normalized);
  }

  Future<ReusableTag?> addTagIfMissing(
    ReusableTagCategory category,
    String name, {
    bool isSystem = false,
  }) async {
    final display = displayName(name);
    final normalized = normalizeName(display);
    if (normalized.isEmpty) return null;

    final catalog = await getCatalog();
    final current = catalog.tagsByCategory[category] ?? <ReusableTag>[];
    final existing = current
        .where((tag) => tag.normalizedName == normalized)
        .firstOrNull;
    if (existing != null) return existing;

    final tag = ReusableTag.create(
      category: category,
      name: display,
      isSystem: isSystem,
    );
    final updated = _replaceCategory(catalog, category, [...current, tag]);
    await _writeCatalog(updated);
    return tag;
  }

  Future<void> ensureSystemTags() async {
    final catalog = await _readCatalog();
    final seeded = _withSystemTags(catalog);
    await _writeCatalog(seeded);
  }

  static String normalizeName(String value) {
    return displayName(value).toLowerCase();
  }

  static String displayName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> tagNamesIncludingValue(
    List<ReusableTag> tags,
    String? value,
  ) {
    final names = tags.map((tag) => tag.name).toList();
    final display = value == null ? '' : displayName(value);
    final normalized = normalizeName(display);
    if (normalized.isNotEmpty &&
        !names.any((name) => normalizeName(name) == normalized)) {
      names.add(display);
    }
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Future<ReusableTagCatalog> _readCatalog() async {
    final raw = await settingsDao.getSetting(settingsKey);
    if (raw == null || raw.trim().isEmpty) {
      return ReusableTagCatalog.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return ReusableTagCatalog.fromJson(decoded);
      }
      if (decoded is Map) {
        return ReusableTagCatalog.fromJson(decoded.cast<String, Object?>());
      }
    } on FormatException {
      // Keep the app usable if a setting is manually corrupted.
    }
    return ReusableTagCatalog.empty();
  }

  Future<void> _writeCatalog(ReusableTagCatalog catalog) {
    return settingsDao.setSetting(settingsKey, jsonEncode(catalog.toJson()));
  }

  ReusableTagCatalog _withSystemTags(ReusableTagCatalog catalog) {
    var next = catalog;
    for (final tagName in SessionTypeOptions.systemTaskTagNames) {
      next = _withTag(
        next,
        ReusableTag.create(
          category: ReusableTagCategory.sessionTask,
          name: tagName,
          isSystem: true,
        ),
      );
    }
    return next;
  }

  ReusableTagCatalog _withTag(ReusableTagCatalog catalog, ReusableTag tag) {
    final current = catalog.tagsByCategory[tag.category] ?? <ReusableTag>[];
    if (current.any((t) => t.normalizedName == tag.normalizedName)) {
      return catalog;
    }
    return _replaceCategory(catalog, tag.category, [...current, tag]);
  }

  ReusableTagCatalog _replaceCategory(
    ReusableTagCatalog catalog,
    ReusableTagCategory category,
    List<ReusableTag> tags,
  ) {
    final next = <ReusableTagCategory, List<ReusableTag>>{
      for (final entry in catalog.tagsByCategory.entries)
        entry.key: List<ReusableTag>.from(entry.value),
    };
    next[category] = _dedupeAndSort(tags);
    return ReusableTagCatalog(next);
  }

  List<ReusableTag> _dedupeAndSort(List<ReusableTag> tags) {
    final byNormalizedName = <String, ReusableTag>{};
    for (final tag in tags) {
      if (tag.normalizedName.isEmpty) continue;
      byNormalizedName.putIfAbsent(tag.normalizedName, () => tag);
    }
    final sorted = byNormalizedName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  bool _catalogEquals(ReusableTagCatalog a, ReusableTagCatalog b) {
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }
}

// TODO: Explicit note tags can be added in a later phase. Notes remain free
// text for now and are intentionally not converted into reusable tags.
