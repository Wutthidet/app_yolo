import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<String> _recognizeTextInIsolate(Map<String, dynamic> params) async {
  final Uint8List imageBytes = params['imageBytes'];
  final Rect boundingBox = params['boundingBox'];
  final RootIsolateToken token = params['token'];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  try {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      return '';
    }

    if (boundingBox.width <= 0 || boundingBox.height <= 0) {
      return '';
    }

    final croppedImage = img.copyCrop(
      originalImage,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );

    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${boundingBox.hashCode}.jpg';
    final jpgBytes = img.encodeJpg(croppedImage);
    await File(tempPath).writeAsBytes(jpgBytes);

    final inputImage = InputImage.fromFilePath(tempPath);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await File(tempPath).delete();

    return recognizedText.text;
  } catch (e) {
    return '';
  } finally {
    await textRecognizer.close();
  }
}

class OcrService {
  static final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  static Future<String> recognizeTextFromImage(String base64Image) async {
    try {
      final Uint8List imageBytes = base64Decode(base64Image);
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return '';
      }

      return await _recognizeTextFromImg(image);
    } catch (e) {
      return '';
    }
  }

  static Future<String> recognizeTextFromCroppedImage({
    required Uint8List imageBytes,
    required Rect boundingBox,
  }) async {
    final RootIsolateToken? token = RootIsolateToken.instance;
    if (token == null) {
      return '';
    }
    return await compute(_recognizeTextInIsolate, {
      'imageBytes': imageBytes,
      'boundingBox': boundingBox,
      'token': token,
    });
  }

  static Future<String> _recognizeTextFromImg(img.Image image) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final jpgBytes = img.encodeJpg(image);
    await File(tempPath).writeAsBytes(jpgBytes);

    final inputImage = InputImage.fromFilePath(tempPath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    await File(tempPath).delete();

    return recognizedText.text;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
