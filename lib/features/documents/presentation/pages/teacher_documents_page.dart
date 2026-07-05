import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/documents/data/teacher_documents_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';

class TeacherDocumentsPage extends StatefulWidget {
  const TeacherDocumentsPage({super.key});

  @override
  State<TeacherDocumentsPage> createState() => _TeacherDocumentsPageState();
}

class _TeacherDocumentsPageState extends State<TeacherDocumentsPage> {
  late final TeacherDocumentsRepository _repository;
  late Future<TeacherDocumentsResult> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = TeacherDocumentsRepository();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Documents')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<TeacherDocumentsResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorState(onRetry: _refresh);
            }

            final result = snapshot.data!;
            final documents = _filterDocuments(result.documents, _query);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _SummaryBand(counts: result.counts),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                if (documents.isEmpty)
                  _EmptyState(hasQuery: _query.trim().isNotEmpty)
                else
                  for (final document in documents) ...[
                    _DocumentCard(document: document),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<TeacherDocument> _filterDocuments(
    List<TeacherDocument> documents,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return documents;

    return documents.where((document) {
      return [
        document.title,
        document.subject,
        document.className,
        document.originalName,
        document.ext,
        document.status,
        document.comment,
      ].any((value) => value.toLowerCase().contains(normalized));
    }).toList();
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.counts});

  final TeacherDocumentCounts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppColors.surface,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Uploaded documents'),
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.format('{count} documents uploaded', {
                        'count': '${counts.all}',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountChip(label: context.tr('All'), value: counts.all),
              _CountChip(label: context.tr('Pending'), value: counts.pending),
              _CountChip(label: context.tr('Approved'), value: counts.approved),
              _CountChip(label: context.tr('Rejected'), value: counts.rejected),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr('Search documents'),
        prefixIcon: Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: Icon(Icons.close_rounded),
                tooltip: context.tr('Clear search'),
              ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final TeacherDocument document;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(document.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_fileIcon(document.type), color: statusColor),
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
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: document.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.class_outlined, label: document.className),
              _InfoChip(
                icon: Icons.insert_drive_file_outlined,
                label: _fileLabel(document),
              ),
              _InfoChip(icon: Icons.sd_storage_outlined, label: document.size),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: _formatDate(context, document.date),
              ),
            ],
          ),
          if (document.originalName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MetadataLine(
              label: context.tr('File name'),
              value: document.originalName,
            ),
          ],
          if (document.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetadataLine(
              label: context.tr('Admin comment'),
              value: document.comment,
            ),
          ],
        ],
      ),
    );
  }

  String _fileLabel(TeacherDocument document) {
    final ext = document.ext.trim().toUpperCase();
    if (ext.isEmpty) return document.type.toUpperCase();
    return ext;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr(_statusLabel(status)),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedText),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.bodyText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.bodyText,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined, color: AppColors.mutedText, size: 42),
          const SizedBox(height: 10),
          Text(
            hasQuery
                ? context.tr('No documents match your search.')
                : context.tr('No uploaded documents yet.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _panelDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: AppColors.rose, size: 42),
              const SizedBox(height: 12),
              Text(
                context.tr('Could not load teacher documents'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('Check your backend API connection and try again.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded),
                label: Text(context.tr('Retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status.toLowerCase()) {
    'approved' => AppColors.green,
    'rejected' => AppColors.rose,
    _ => AppColors.orange,
  };
}

String _statusLabel(String status) {
  return switch (status.toLowerCase()) {
    'approved' => 'Approved',
    'rejected' => 'Rejected',
    _ => 'Pending',
  };
}

IconData _fileIcon(String type) {
  return switch (type.toLowerCase()) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' => Icons.article_outlined,
    'ppt' => Icons.slideshow_outlined,
    'image' => Icons.image_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

String _formatDate(BuildContext context, DateTime? date) {
  if (date == null) return context.tr('N/A');
  final months = [
    context.tr('January'),
    context.tr('February'),
    context.tr('March'),
    context.tr('April'),
    context.tr('May'),
    context.tr('June'),
    context.tr('July'),
    context.tr('August'),
    context.tr('September'),
    context.tr('October'),
    context.tr('November'),
    context.tr('December'),
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0F172033), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}
