import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/sync_merge.dart';

Future<void> showScanQrModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _ScanQrModal(),
  );
}

class _ScanQrModal extends StatefulWidget {
  const _ScanQrModal();

  @override
  State<_ScanQrModal> createState() => _ScanQrModalState();
}

class _ScanQrModalState extends State<_ScanQrModal> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processPayload(String payload) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final backup = BackupData.fromJson(data);
      if (!mounted) return;
      await context.read<AppStore>().importData(backup);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline sync completed! Merged data from QR code.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code. Please scan a valid Spiliby QR backup.')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final capture = await _controller.analyzeImage(file.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        for (final b in capture.barcodes) {
          if (b.rawValue != null && b.rawValue!.isNotEmpty) {
            await _processPayload(b.rawValue!);
            return;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid QR code found in that image.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze QR from image.')),
        );
      }
    }
  }

  Future<void> _pastePayload() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste QR / JSON Data'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste copied JSON or QR text here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Import')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _processPayload(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scan Spiliby QR',
                      style: AppFonts.display(size: 18, weight: FontWeight.w600, color: c.textPrimary),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at a Spiliby QR code to sync data.',
                textAlign: TextAlign.center,
                style: AppFonts.body(size: 13, color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                height: 260,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                            _processPayload(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    ),
                    if (_processing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Pick Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _pastePayload,
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      label: const Text('Paste Text'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
