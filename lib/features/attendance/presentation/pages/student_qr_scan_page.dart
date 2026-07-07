import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/attendance/data/student_qr_attendance_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StudentQrScanPage extends StatefulWidget {
  const StudentQrScanPage({super.key});

  @override
  State<StudentQrScanPage> createState() => _StudentQrScanPageState();
}

class _StudentQrScanPageState extends State<StudentQrScanPage> {
  late final StudentQrAttendanceRepository _repository;
  late final MobileScannerController _scannerController;
  bool _isSubmitting = false;
  String _message = '';
  DateTime? _lastInvalidScanAt;

  @override
  void initState() {
    super.initState();
    _repository = StudentQrAttendanceRepository();
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

    final raw = capture.barcodes
        .map(_safeBarcodeValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    final payload = parseStudentQrPayload(raw);
    if (payload == null) {
      final now = DateTime.now();
      if (_lastInvalidScanAt != null &&
          now.difference(_lastInvalidScanAt!) < const Duration(seconds: 2)) {
        return;
      }
      _lastInvalidScanAt = now;
      HapticFeedback.selectionClick();
      _setMessage(context.tr('This is not a student attendance QR code.'));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isSubmitting = true;
      _message = context.tr('Reading attendance QR...');
    });

    try {
      await _scannerController.stop();
      final result = await _repository.verify(
        sessionId: payload.sessionId,
        qrToken: payload.token,
      );
      if (!mounted) return;
      await _showSuccess(result);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final message = _errorMessage(error);
      setState(() {
        _isSubmitting = false;
        _message = message;
      });
      await _showFailure(message);
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

  String _errorMessage(Object error) {
    if (error is ApiException) return context.tr(error.message);
    return '$error'.replaceFirst('Exception: ', '');
  }

  Future<void> _showSuccess(StudentQrCheckInResult result) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScanResultSheet(
        icon: Icons.check_circle_rounded,
        color: AppColors.green,
        title: context.tr('Check-in successful'),
        message: _successMessage(context, result),
        primaryLabel: context.tr('Done'),
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _showFailure(String message) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScanResultSheet(
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
        title: context.tr('Could not verify attendance QR.'),
        message: message,
        primaryLabel: context.tr('Scan again'),
        onPrimary: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.tr('Student QR attendance')),
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
            icon: const Icon(Icons.flash_on_rounded),
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
                  _setMessage(_friendlyScannerError(context, error));
                },
                errorBuilder: (context, error) => _ScannerError(error: error),
                placeholderBuilder: (context) => const _ScannerPlaceholder(),
                scanWindow: scanWindow,
                tapToFocus: true,
              ),
              _SecureScannerOverlay(scanWindow: scanWindow),
              Positioned(left: 18, right: 18, top: 18, child: _SecureBadge()),
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
}

class _SecureScannerOverlay extends StatelessWidget {
  const _SecureScannerOverlay({required this.scanWindow});

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SecureScannerOverlayPainter(scanWindow));
  }
}

class _SecureScannerOverlayPainter extends CustomPainter {
  const _SecureScannerOverlayPainter(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, cutout),
      Paint()..color = Colors.black.withValues(alpha: 0.56),
    );

    final paint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = scanWindow.deflate(2);
    const corner = 34.0;

    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, corner),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight - const Offset(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, corner),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - const Offset(0, corner),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - const Offset(0, corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SecureScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
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
                context.tr('Could not start camera. Check permission.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _safeBarcodeValue(Barcode barcode) {
  try {
    return barcode.rawValue;
  } catch (_) {
    return null;
  }
}

String _friendlyScannerError(BuildContext context, Object error) {
  if (error is MobileScannerException) {
    return context.tr('Could not read QR. Try again.');
  }

  final message = '$error'.replaceFirst('Exception: ', '').trim();
  if (message.isEmpty ||
      message.contains('null object reference') ||
      message.contains('Attempt to invoke virtual method')) {
    return context.tr('Could not read QR. Try again.');
  }

  return message;
}

class _SecureBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: AppColors.green,
              size: 17,
            ),
            const SizedBox(width: 7),
            Text(
              context.tr('Secure student scan'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel({required this.isSubmitting, required this.message});

  final bool isSubmitting;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isSubmitting)
            SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.isEmpty
                  ? context.tr('Scan the teacher attendance QR code')
                  : message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _successMessage(BuildContext context, StudentQrCheckInResult result) {
  final statusLine = result.status.isEmpty
      ? context.tr(result.message)
      : context.l10n.format('{status} at {time}', {
          'status': context.tr(result.status),
          'time': _timeLabel(result.scanTime),
        });
  if (result.subject.isEmpty) return statusLine;

  final room = result.room.isEmpty
      ? ''
      : '\n${context.l10n.format('Room {room}', {'room': result.room})}';
  return '${result.subject}$room\n$statusLine';
}

String _timeLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? '--:--' : value;
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
