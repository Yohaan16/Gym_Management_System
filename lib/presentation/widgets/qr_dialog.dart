import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart' as qr_pkg;

/// Dialog that shows a short-lived QR token and countdown.
/// Public (non-underscore) so it can be used from other files.
class QrDialog extends StatefulWidget {
  final String token;
  final DateTime? expiresAt;
  const QrDialog({required this.token, this.expiresAt, super.key});

  @override
  State<QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends State<QrDialog> {
  late int _remaining;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _remaining = widget.expiresAt != null
        ? widget.expiresAt!.difference(now).inSeconds
        : 120;
    if (_remaining < 0) _remaining = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - 1;
        if (_remaining <= 0) _ticker?.cancel();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _buildQrWidget() {
    try {
      // Use a higher error-correction level to tolerate scanning artifacts
      final qcode = qr_pkg.QrCode.fromData(
        data: widget.token,
        errorCorrectLevel: qr_pkg.QrErrorCorrectLevel.H,
      );
      final dataImage = qr_pkg.QrImage(qcode);
      // Debug logging removed in production build.
      // Use a simple CustomPainter so we don't depend on a specific qr_flutter Widget API
      return SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _RawQrPainter(dataImage),
          size: const Size.square(220),
        ),
      );
    } catch (e) {
      return SizedBox(
        width: 220,
        height: 220,
        child: Center(
          child: Text(
            'QR unavailable',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Show this QR to the scanner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQrWidget(),
          const SizedBox(height: 12),
          Text(
            _remaining > 0 ? 'Expires in $_remaining s' : 'Expired',
            style: TextStyle(
                color: _remaining > 0 ? Colors.green : Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

// Lightweight CustomPainter that renders a `qr` package QrCode to the canvas.
class _RawQrPainter extends CustomPainter {
  final qr_pkg.QrImage _image;
  final Color _dark;
  final Color _light;

  _RawQrPainter(this._image, {Color dark = Colors.black, Color light = Colors.white})
      : _dark = dark,
        _light = light;

  @override
  void paint(Canvas canvas, Size size) {
    final int moduleCount = _image.moduleCount;
    if (moduleCount == 0) return;

    // Standard QR spec requires a 4-module quiet zone (margin) around the code.
    const int quietModules = 4;
    final double pixel = size.width / (moduleCount + quietModules * 2);
    final double offset = quietModules * pixel;

    final paintDark = Paint()..color = _dark;
    final paintLight = Paint()..color = _light;

    // Fill background (including quiet zone)
    canvas.drawRect(Offset.zero & size, paintLight);

    // Draw modules at offset to preserve quiet zone
    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (_image.isDark(x, y)) {
          final rect = Rect.fromLTWH(offset + x * pixel, offset + y * pixel, pixel, pixel);
          canvas.drawRect(rect, paintDark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RawQrPainter oldDelegate) {
    return oldDelegate._image != _image || oldDelegate._dark != _dark || oldDelegate._light != _light;
  }
}
