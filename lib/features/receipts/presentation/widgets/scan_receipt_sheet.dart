import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/receipts/data/services/ocr_service.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:lumina/features/receipts/presentation/screens/fiscal_qr_scan_screen.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ScanReceiptSheet {
  static Future<ScannedReceipt?> pick(BuildContext context) {
    return showModalBottomSheet<ScannedReceipt>(
      context: context,
      backgroundColor: LuminaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return SafeArea(
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
                _tile(
                  icon: Icons.photo_camera_rounded,
                  label: loc.scanFromCamera,
                  onTap: () => _ocr(ctx, ImageSource.camera),
                ),
                _tile(
                  icon: Icons.photo_library_rounded,
                  label: loc.scanFromGallery,
                  onTap: () => _ocr(ctx, ImageSource.gallery),
                ),
                _tile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: loc.scanQrCode,
                  onTap: () => _qr(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }

  static Future<void> _ocr(BuildContext ctx, ImageSource source) async {
    final loc = AppLocalizations.of(ctx)!;
    showDialog<void>(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final receipt = await ReceiptOcrService().pickAndParse(source);
      if (!ctx.mounted) return;
      Navigator.of(ctx, rootNavigator: true).pop();
      if (receipt == null) return;
      Navigator.pop(ctx, receipt);
    } catch (_) {
      if (!ctx.mounted) return;
      Navigator.of(ctx, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(loc.scanFailed)));
    }
  }

  static Future<void> _qr(BuildContext ctx) async {
    final receipt = await Navigator.of(ctx).push<ScannedReceipt>(
      MaterialPageRoute(builder: (_) => const FiscalQrScanScreen()),
    );
    if (!ctx.mounted || receipt == null) return;
    Navigator.pop(ctx, receipt);
  }
}
