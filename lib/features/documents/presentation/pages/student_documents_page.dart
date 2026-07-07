import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/documents/data/student_documents_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class StudentDocumentsPage extends StatefulWidget {
  const StudentDocumentsPage({super.key});

  @override
  State<StudentDocumentsPage> createState() => _StudentDocumentsPageState();
}

class _StudentDocumentsPageState extends State<StudentDocumentsPage> {
  late final StudentDocumentsRepository _repository;
  late Future<StudentDocumentsResult> _future;
  final _searchController = TextEditingController();
  String _query = '';
  String _subject = 'All';

  @override
  void initState() {
    super.initState();
    _repository = StudentDocumentsRepository();
    _future = _repository.fetchDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchDocuments();
    setState(() => _future = future);
    await future;
  }

  List<StudentDocument> _filter(List<StudentDocument> documents) {
    final query = _query.trim().toLowerCase();
    return documents.where((document) {
      final matchesSubject = _subject == 'All' || document.subject == _subject;
      final matchesQuery =
          query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.subject.toLowerCase().contains(query) ||
          document.teacher.toLowerCase().contains(query) ||
          document.originalName.toLowerCase().contains(query);
      return matchesSubject && matchesQuery;
    }).toList();
  }

  Future<void> _preview(StudentDocument document) async {
    if (!document.canPreview) {
      await _download(document, openAfterSave: true);
      return;
    }

    try {
      final bytes = await _repository.preview(document);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentDocumentPreviewPage(
            document: document,
            bytes: bytes,
            onDownload: () => _download(document, openAfterSave: true),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(_errorMessage(error));
    }
  }

  Future<void> _download(
    StudentDocument document, {
    bool openAfterSave = false,
  }) async {
    try {
      final bytes = await _repository.download(document);
      final file = await _saveFile(document, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Document downloaded')),
          action: SnackBarAction(
            label: context.tr('Open'),
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
      if (openAfterSave) await OpenFilex.open(file.path);
    } catch (error) {
      if (!mounted) return;
      _showError(_errorMessage(error));
    }
  }

  Future<File> _saveFile(StudentDocument document, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/student_documents');
    if (!await folder.exists()) await folder.create(recursive: true);
    final fileName = _safeFileName(document);
    final file = File('${folder.path}/$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  String _safeFileName(StudentDocument document) {
    final raw = document.originalName.isNotEmpty
        ? document.originalName
        : '${document.title}.${document.ext}';
    final safe = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return safe.isEmpty ? 'document_${document.id}.${document.ext}' : safe;
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return context.tr(error.message);
    return '$error'.replaceFirst('Exception: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Documents')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<StudentDocumentsResult>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }

              final result = snapshot.data!;
              final documents = _filter(result.documents);
              final subjects = ['All', ...result.subjects];

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _SummaryBand(result: result),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: context.tr('Search documents'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: context.tr('Clear search'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final subject in subjects) ...[
                          ChoiceChip(
                            label: Text(
                              subject == 'All' ? context.tr('All') : subject,
                            ),
                            selected: _subject == subject,
                            onSelected: (_) =>
                                setState(() => _subject = subject),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (documents.isEmpty)
                    _EmptyState(
                      hasQuery: _query.isNotEmpty || _subject != 'All',
                    )
                  else
                    for (final document in documents) ...[
                      _DocumentCard(
                        document: document,
                        onPreview: () => _preview(document),
                        onDownload: () => _download(document),
                        onOpen: () => _download(document, openAfterSave: true),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigationForRole(
        current: StudentNavDestination.documents,
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.result});

  final StudentDocumentsResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24145DA0),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder_copy_outlined, color: AppColors.surface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Documents'),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.format('{count} documents available', {
                    'count': '${result.counts.all}',
                  }),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onPreview,
    required this.onDownload,
    required this.onOpen,
  });

  final StudentDocument document;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _documentColor(document.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_documentIcon(document.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.subject} - ${document.teacher}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (document.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              document.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.bodyText,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(text: document.ext.toUpperCase()),
              _MetaChip(text: document.size),
              if (document.date != null)
                _MetaChip(text: _dateLabel(document.date!)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: Icon(
                    document.canPreview
                        ? Icons.visibility_outlined
                        : Icons.open_in_new_rounded,
                    size: 18,
                  ),
                  label: Text(
                    document.canPreview
                        ? context.tr('Preview')
                        : context.tr('Open'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                tooltip: context.tr('Download'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class StudentDocumentPreviewPage extends StatelessWidget {
  const StudentDocumentPreviewPage({
    required this.document,
    required this.bytes,
    required this.onDownload,
    super.key,
  });

  final StudentDocument document;
  final Uint8List bytes;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded),
            tooltip: context.tr('Download'),
          ),
        ],
      ),
      body: document.isPdf
          ? SfPdfViewer.memory(bytes)
          : document.isImage
          ? InteractiveViewer(child: Center(child: Image.memory(bytes)))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr('Preview is not available for this file type.'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasQuery
              ? context.tr('No documents match your search.')
              : context.tr('No documents available yet.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              context.tr('Could not load student documents'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _documentIcon(String type) {
  return switch (type) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' => Icons.description_outlined,
    'ppt' => Icons.slideshow_outlined,
    'image' => Icons.image_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

Color _documentColor(String type) {
  return switch (type) {
    'pdf' => AppColors.rose,
    'doc' => AppColors.brandBlue,
    'ppt' => AppColors.orange,
    'image' => AppColors.green,
    _ => AppColors.mutedText,
  };
}

String _dateLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
