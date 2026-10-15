import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/receipts/data/services/fiscal_qr_service.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FiscalQrScanScreen extends StatefulWidget {
  const FiscalQrScanScreen({super.key});

  @override
  State<FiscalQrScanScreen> createState() => _FiscalQrScanScreenState();
}

class _FiscalQrScanScreenState extends State<FiscalQrScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    var sawOther = false;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final receipt = FiscalQrService.parse(raw);
      if (receipt == null) {
        sawOther = true;
        continue;
      }

      _handled = true;
      HapticFeedback.mediumImpact();
      await _controller.stop();
      if (!mounted) return;
      Navigator.of(context).pop<ScannedReceipt>(receipt);
      return;
    }

    // Отвечаем на чужой QR, чтобы пользователь не гадал, что происходит.
    if (sawOther && mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(loc.qrNotFiscal)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(loc.scanQrCode),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: LuminaColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
