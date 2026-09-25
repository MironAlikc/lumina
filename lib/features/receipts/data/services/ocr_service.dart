import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/features/receipts/data/services/receipt_parser.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';

class ReceiptOcrService {
  ReceiptOcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<ScannedReceipt?> pickAndParse(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2400,
    );
    if (file == null) return null;
    return parseFile(file.path);
  }

  Future<ScannedReceipt> parseFile(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      return ReceiptParser.parse(recognized.text);
    } finally {
      await recognizer.close();
    }
  }
}
