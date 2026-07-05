import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';

class AppErrorPage extends StatelessWidget {
  const AppErrorPage({
    super.key,
    this.title,
    this.message,
    this.details,
    this.onRetry,
    this.showHomeButton = true,
  });

  final String? title;
  final String? message;
  final String? details;
  final VoidCallback? onRetry;
  final bool showHomeButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title ?? context.tr('Something went wrong'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: _ErrorPanel(
              title: title ?? context.tr('Something went wrong'),
              message:
                  message ??
                  context.tr('The app could not open this page right now.'),
              details: details,
              onRetry: onRetry,
              showHomeButton: showHomeButton,
            ),
          ),
        ),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.title, this.message, this.details});

  final String? title;
  final String? message;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: _ErrorPanel(
              title: title ?? context.tr('Something went wrong'),
              message:
                  message ??
                  context.tr(
                    'The app found a problem while opening this view.',
                  ),
              details: details,
              showHomeButton: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.title,
    required this.message,
    required this.showHomeButton,
    this.details,
    this.onRetry,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final bool showHomeButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F172033),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.rose,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.bodyText,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (details != null && details!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                details!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (Navigator.of(context).canPop())
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(context.tr('Back')),
                ),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('Retry')),
                ),
              if (showHomeButton)
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(context.tr('Home')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
