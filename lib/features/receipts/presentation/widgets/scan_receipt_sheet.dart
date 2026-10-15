import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/receipts/data/services/ocr_service.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:lumina/features/receipts/presentation/screens/fiscal_qr_scan_screen.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ScanReceiptSheet {
  ScanReceiptSheet._();

  static Future<ScannedReceipt?> pick(BuildContext context) {
    return showModalBottomSheet<ScannedReceipt>(
      context: context,
      backgroundColor: LuminaColors.surface,
      // Во время распознавания шит нельзя смахнуть: результат бы потерялся.
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ScanReceiptBody(),
    );
  }
}

class _ScanReceiptBody extends StatefulWidget {
  const _ScanReceiptBody();

  @override
  State<_ScanReceiptBody> createState() => _ScanReceiptBodyState();
}

class _ScanReceiptBodyState extends State<_ScanReceiptBody> {
  final _service = ReceiptOcrService();
  bool _busy = false;
  String? _error;

  Future<void> _ocr(ImageSource source) async {
    if (_busy) return;
    final loc = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final receipt = await _service.pickAndParse(source);
      if (!mounted) return;
      if (receipt == null) {
        setState(() => _busy = false); // пользователь закрыл выбор фото
        return;
      }
      Navigator.of(context).pop(receipt);
    } on ReceiptOcrException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (e.reason) {
          ReceiptOcrFailure.cameraDenied => loc.permissionCameraDenied,
          ReceiptOcrFailure.unavailable => loc.scanUnavailable,
          ReceiptOcrFailure.failed => loc.scanFailed,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = loc.scanFailed;
      });
    }
  }

  Future<void> _qr() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    final receipt = await navigator.push<ScannedReceipt>(
      MaterialPageRoute(builder: (_) => const FiscalQrScanScreen()),
    );
    if (!mounted || receipt == null) return;
    navigator.pop(receipt);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LuminaColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.scanReceipt,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: LuminaColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: LuminaColors.errorDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_busy)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        loc.scanningReceipt,
                        style: const TextStyle(
                          color: LuminaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _SourceTile(
                  icon: Icons.photo_camera_rounded,
                  label: loc.scanFromCamera,
                  onTap: () => _ocr(ImageSource.camera),
                ),
                _SourceTile(
                  icon: Icons.photo_library_rounded,
                  label: loc.scanFromGallery,
                  onTap: () => _ocr(ImageSource.gallery),
                ),
                _SourceTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: loc.scanQrCode,
                  onTap: _qr,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: LuminaColors.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: LuminaColors.primary),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: LuminaColors.textMain,
        ),
      ),
      onTap: onTap,
    );
  }
}
