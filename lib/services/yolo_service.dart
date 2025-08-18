import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;

class YoloService {
  static FlutterVision? _vision;
  static bool _isInitialized = false;
  static bool _isDetecting = false;
  static List<Map<String, dynamic>> _lastResults = [];
  static final Random _random = Random();
  static final Map<String, Color> _colorMap = {};

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _vision = FlutterVision();
      await _vision!.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 1,
        useGpu: true,
      );
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  static bool get isInitialized => _isInitialized;

  static Future<List<Map<String, dynamic>>?> detectObjects(
      CameraImage image) async {
    if (!_isInitialized || _vision == null || _isDetecting) {
      return null;
    }

    _isDetecting = true;
    try {
      final result = await _vision!.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.5,
        classThreshold: 0.5,
      );

      _lastResults = result;
      return result;
    } catch (e) {
      return null;
    } finally {
      _isDetecting = false;
    }
  }

  static Future<List<Map<String, dynamic>>?> detectObjectsOnImage(
      {required String base64Image}) async {
    if (!_isInitialized || _vision == null || _isDetecting) {
      return null;
    }

    _isDetecting = true;
    try {
      final Uint8List imageBytes = base64Decode(base64Image);
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return null;
      }

      final result = await _vision!.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: originalImage.height,
        imageWidth: originalImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.5,
        classThreshold: 0.5,
      );

      _lastResults = result;
      return result;
    } catch (e) {
      return null;
    } finally {
      _isDetecting = false;
    }
  }

  static List<Map<String, dynamic>> get lastResults => _lastResults;

  static Color getColorForLabel(String label) {
    if (_colorMap.containsKey(label)) {
      return _colorMap[label]!;
    } else {
      final color = Color.fromARGB(
        255,
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
      );
      _colorMap[label] = color;
      return color;
    }
  }

  static void clearResults() {
    _lastResults.clear();
  }

  static Future<void> dispose() async {
    if (_vision != null) {
      await _vision!.closeYoloModel();
      _vision = null;
    }
    _isInitialized = false;
    _isDetecting = false;
    _lastResults.clear();
    _colorMap.clear();
  }
}
