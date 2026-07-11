import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';


class QrUpload extends StatelessWidget {
  final String? qrCode;
  final ValueChanged<String?> onChange;
  final String label;

  const QrUpload({super.key, required this.qrCode, required this.onChange, this.label = 'Payment QR code'});

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    onChange('data:image/png;base64,$b64');
  }

  ImageProvider? _imageProvider(String dataUrl) {
    try {
      final comma = dataUrl.indexOf(',');
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final img = qrCode != null ? _imageProvider(qrCode!) : null;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: img != null
              ? Image(image: img, fit: BoxFit.cover)
              : Icon(Icons.qr_code_rounded, size: 22, color: c.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.textPrimary)),
              Text(
                qrCode != null ? 'Uploaded · shown when others settle up' : 'Upload so friends can pay you instantly',
                style: AppFonts.body(size: 11, color: c.textMuted),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _pick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.upload_rounded, size: 15, color: c.textSecondary),
          ),
        ),
        if (qrCode != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onChange(null),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.dangerBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.delete_outline_rounded, size: 15, color: c.danger),
            ),
          ),
        ],
      ],
    );
  }
}