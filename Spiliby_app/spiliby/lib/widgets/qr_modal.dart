import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_modal.dart';

Future<void> showQrModal(BuildContext context, {required String name, String? qrCode}) {
  return showAppModal(
    context: context,
    title: 'Pay $name',
    builder: (ctx) => _QrModalBody(name: name, qrCode: qrCode),
  );
}

class _QrModalBody extends StatelessWidget {
  final String name;
  final String? qrCode;
  const _QrModalBody({required this.name, this.qrCode});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    if (qrCode == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.qr_code_rounded, size: 28, color: c.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              "$name hasn't uploaded a payment QR yet.",
              textAlign: TextAlign.center,
              style: AppFonts.body(size: 13, color: c.textMuted),
            ),
          ],
        ),
      );
    }

    Uint8List? bytes;
    try {
      final comma = qrCode!.indexOf(',');
      bytes = base64Decode(qrCode!.substring(comma + 1));
    } catch (_) {
      bytes = null;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.chipBg),
          ),
          child: bytes != null
              ? Image.memory(bytes, width: 256, height: 256, fit: BoxFit.contain)
              : SizedBox(width: 256, height: 256, child: Icon(Icons.qr_code_rounded, color: c.textMuted)),
        ),
        const SizedBox(height: 16),
        Text(
          'Scan this code in any UPI app to pay $name.',
          textAlign: TextAlign.center,
          style: AppFonts.body(size: 12, color: c.textMuted),
        ),
      ],
    );
  }
}