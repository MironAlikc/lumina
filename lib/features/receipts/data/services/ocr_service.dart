import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/features/receipts/data/services/receipt_parser.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';
import 'package:path_provider/path_provider.dart';

enum ReceiptOcrFailure { cameraDenied, unavailable, failed }

class ReceiptOcrException implements Exception {
  const ReceiptOcrException(this.reason, [this.cause]);

  final ReceiptOcrFailure reason;
  final Object? cause;

  @override
  String toString() => 'ReceiptOcrException($reason, $cause)';
}

class ReceiptOcrService {
  ReceiptOcrService({ImagePicker? picker, MethodChannel? channel})
      : _picker = picker ?? ImagePicker(),
        _channel = channel ?? const MethodChannel('lumina/ocr');

  final ImagePicker _picker;
  final MethodChannel _channel;

  /// Возвращает null, если пользователь закрыл выбор фото.
  /// Бросает [ReceiptOcrException] при сбое.
  Future<ScannedReceipt?> pickAndParse(ImageSource source) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );
    } on PlatformException catch (e) {
      final denied = e.code.startsWith('camera_access');
      throw ReceiptOcrException(
        denied ? ReceiptOcrFailure.cameraDenied : ReceiptOcrFailure.failed,
        e,
      );
    }
    if (file == null) return null;

    try {
      return await parseFile(file.path);
    } finally {
      await _deleteTemp(file.path);
    }
  }

  Future<ScannedReceipt> parseFile(String path) async {
    String text;
    try {
      text = await _channel.invokeMethod<String>('recognize', {'path': path}) ??
          '';
    } on MissingPluginException catch (e) {
      throw ReceiptOcrException(ReceiptOcrFailure.unavailable, e);
    } on PlatformException catch (e) {
      throw ReceiptOcrException(ReceiptOcrFailure.failed, e);
    }

    // Текст чека - личные данные: в release-сборке не логируем.
    if (kDebugMode) debugPrint('OCR text (${text.length} chars)');
    return ReceiptParser.parse(text);
  }

  /// Удаляет только копии во временной папке, оригиналы пользователя не трогаем.
  Future<void> _deleteTemp(String path) async {
    try {
      final tmp = await getTemporaryDirectory();
      if (!path.startsWith(tmp.path)) return;
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Очистка best-effort.
    }
  }
}
