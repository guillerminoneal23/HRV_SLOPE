library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/shared/instructions/instructions_content.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final _searchController = TextEditingController();
  String _selectedChapterId = instructionsChapters.first.id;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _filteredChapters();
    final selected = chapters.firstWhere(
      (chapter) => chapter.id == _selectedChapterId,
      orElse: () =>
          chapters.isEmpty ? instructionsChapters.first : chapters.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Instructions Book')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _disclaimerCard(),
          _workflowCard(),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search instructions',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          _chapterSelector(chapters),
          const SizedBox(height: 12),
          if (chapters.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No instruction sections match this search.'),
              ),
            )
          else
            _chapterContent(selected),
        ],
      ),
    );
  }

  Widget _disclaimerCard() {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                kInstructionsDisclaimer,
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workflowCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.route, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recommended workflow',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(kInstructionsRecommendedWorkflow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chapterSelector(List<InstructionChapter> chapters) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chapters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chapter in chapters)
                  ChoiceChip(
                    label: Text(chapter.title),
                    selected: chapter.id == _selectedChapterId,
                    onSelected: (_) =>
                        setState(() => _selectedChapterId = chapter.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chapterContent(InstructionChapter chapter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final section in chapter.sections) _sectionCard(section),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(InstructionSection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            section.summary,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(section.body, style: const TextStyle(height: 1.45)),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('- '),
                    Expanded(child: Text(bullet)),
                  ],
                ),
              ),
          ],
          if (section.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in section.warnings)
              Text(
                warning,
                style: const TextStyle(color: AppColors.warning, fontSize: 13),
              ),
          ],
          if (section.relatedScreens.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Related: ${section.relatedScreens.join(', ')}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  List<InstructionChapter> _filteredChapters() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return instructionsChapters;
    return [
      for (final chapter in instructionsChapters)
        if (chapter.title.toLowerCase().contains(query))
          chapter
        else
          InstructionChapter(
            id: chapter.id,
            title: chapter.title,
            sections: [
              for (final section in chapter.sections)
                if (_sectionMatches(section, query)) section,
            ],
          ),
    ].where((chapter) => chapter.sections.isNotEmpty).toList();
  }

  bool _sectionMatches(InstructionSection section, String query) {
    return [
      section.title,
      section.summary,
      section.body,
      ...section.bullets,
      ...section.warnings,
    ].any((text) => text.toLowerCase().contains(query));
  }
}
