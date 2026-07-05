import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/attendance/data/teacher_attendance_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TeacherQrCheckInPage extends StatefulWidget {
  const TeacherQrCheckInPage({super.key});

  @override
  State<TeacherQrCheckInPage> createState() => _TeacherQrCheckInPageState();
}

class _TeacherQrCheckInPageState extends State<TeacherQrCheckInPage> {
  late final TeacherAttendanceRepository _repository;
  late final MobileScannerController _scannerController;
  bool _isSubmitting = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _repository = TeacherAttendanceRepository();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isSubmitting) return;
    String raw = '';
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        raw = value;
        break;
      }
    }
    final token = _extractTeacherQrToken(raw);
    if (token.isEmpty) {
      _setMessage(context.tr('This is not a teacher attendance QR code.'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = context.tr('Reading attendance QR...');
    });

    try {
      await _scannerController.stop();
      final session = await _repository.qrCheckIn(token);
      if (!mounted) return;
      await _showScanSuccessDialog(session);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = _scanErrorMessage(error);
      setState(() {
        _isSubmitting = false;
        _message = message;
      });
      if (_isNoActiveSessionError(error)) {
        final leavePage = await _showNoActiveSessionDialog(message);
        if (!mounted) return;
        if (leavePage) {
          Navigator.of(context).pop(false);
          return;
        }
      }
      try {
        await _scannerController.start();
      } catch (_) {
        if (!mounted) return;
        _setMessage(context.tr('Could not start camera. Check permission.'));
      }
    }
  }

  void _setMessage(String value) {
    if (_message == value) return;
    setState(() => _message = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.tr('Teacher QR check-in')),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await _scannerController.toggleTorch();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('Flash is not available'))),
                );
              }
            },
            icon: Icon(Icons.flash_on_rounded),
            tooltip: context.tr('Flash'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = math.min(constraints.maxWidth * 0.74, 286.0);
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: frameSize,
            height: frameSize,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                onDetectError: (error, _) {
                  if (!mounted) return;
                  _setMessage('$error');
                },
                errorBuilder: (context, error) => _ScannerError(error: error),
                placeholderBuilder: (context) => const _ScannerPlaceholder(),
                scanWindow: scanWindow,
                tapToFocus: true,
              ),
              _ScannerFrame(scanWindow: scanWindow),
              Positioned(
                left: 18,
                right: 18,
                bottom: 26,
                child: _InstructionPanel(
                  isSubmitting: _isSubmitting,
                  message: _message,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _scanErrorMessage(Object error) {
    if (error is ApiException) return context.tr(error.message);
    return '$error'.replaceFirst('Exception: ', '');
  }

  bool _isNoActiveSessionError(Object error) {
    if (error is! ApiException) return false;
    final message = error.message.toLowerCase();

    return error.code == 'no_active_session' ||
        error.statusCode == 403 ||
        message.contains('no active session') ||
        message.contains('does not belong');
  }

  Future<bool> _showNoActiveSessionDialog(String message) async {
    final leavePage = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('No active session'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isEmpty
                  ? context.tr(
                      'This QR code does not match an active session for your teacher account.',
                    )
                  : message,
              style: TextStyle(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                context.tr(
                  'Ask the admin to open the correct teacher session QR, then scan again.',
                ),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('Scan again')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('Back')),
          ),
        ],
      ),
    );

    return leavePage ?? false;
  }

  Future<void> _showScanSuccessDialog(TeacherAttendanceSession session) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScanResultDialog(session: session),
    );
  }
}

class _ScanResultDialog extends StatelessWidget {
  const _ScanResultDialog({required this.session});

  final TeacherAttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final isCheckout = session.hasCheckOut;
    final title = isCheckout ? 'Check-out successful' : 'Check-in successful';
    final actionLabel = isCheckout ? 'Checked out' : 'Checked in';
    final time = isCheckout ? session.checkOutTime : session.checkInTime;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCheckout
                  ? Icons.logout_rounded
                  : Icons.task_alt_rounded,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(title),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.format(
              isCheckout
                  ? '{subject} checked out at {time}'
                  : '{subject} checked in at {time}',
              {'subject': session.subjectName, 'time': time},
            ),
            style: TextStyle(
              color: AppColors.bodyText,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.mutedText,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.format('{action} at {time}', {
                      'action': context.tr(actionLabel),
                      'time': time,
                    }),
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Done')),
        ),
      ],
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 14),
            Text(
              context.tr('Starting camera...'),
              style: TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final details = error.errorDetails?.message;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                color: AppColors.surface,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                error.errorCode.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  details,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.scanWindow});

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScannerFramePainter(scanWindow),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.46);
    final background = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(18)),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, background, cutout),
      overlay,
    );

    final borderPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accentPaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = scanWindow.deflate(2);
    const corner = 42.0;

    void drawCorner(Paint paint, Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, paint);
      canvas.drawLine(b, c, paint);
    }

    drawCorner(
      accentPaint,
      Offset(rect.left, rect.top + corner),
      rect.topLeft,
      Offset(rect.left + corner, rect.top),
    );
    drawCorner(
      borderPaint,
      Offset(rect.right - corner, rect.top),
      rect.topRight,
      Offset(rect.right, rect.top + corner),
    );
    drawCorner(
      borderPaint,
      Offset(rect.right, rect.bottom - corner),
      rect.bottomRight,
      Offset(rect.right - corner, rect.bottom),
    );
    drawCorner(
      borderPaint,
      Offset(rect.left + corner, rect.bottom),
      rect.bottomLeft,
      Offset(rect.left, rect.bottom - corner),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel({required this.isSubmitting, required this.message});

  final bool isSubmitting;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Icon(Icons.qr_code_scanner_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.isEmpty
                  ? context.tr('Scan the admin teacher attendance QR code')
                  : message,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _extractTeacherQrToken(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);
  if (uri != null) {
    final token = uri.queryParameters['token'];
    if (token != null && token.trim().isNotEmpty) return token.trim();
  }

  return trimmed;
}
