import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;

enum ModelType { int8, float16, float32 }

class ModelResult {
  final ModelType modelType;
  final List<Map<String, dynamic>> detections;
  final Duration processingTime;
  final bool success;
  final String? errorMessage;

  ModelResult({
    required this.modelType,
    required this.detections,
    required this.processingTime,
    required this.success,
    this.errorMessage,
  });
}

class MultiModelComparison {
  final ModelResult? int8Result;
  final ModelResult? float16Result;
  final ModelResult? float32Result;
  final Duration totalProcessingTime;

  MultiModelComparison({
    this.int8Result,
    this.float16Result,
    this.float32Result,
    required this.totalProcessingTime,
  });
}

class MultiModelYoloService {
  static final Map<ModelType, FlutterVision> _visions = {};
  static final Map<ModelType, bool> _isInitialized = {};
  static bool _isDetecting = false;
  static final Random _random = Random();
  static final Map<String, Color> _colorMap = {};

  static const Map<ModelType, String> _modelPaths = {
    ModelType.int8: 'assets/models/best_int8.tflite',
    ModelType.float16: 'assets/models/best_float16.tflite',
    ModelType.float32: 'assets/models/best_float32.tflite',
  };

  static Future<bool> initializeModel(ModelType modelType) async {
    if (_isInitialized[modelType] == true) return true;

    try {
      final vision = FlutterVision();

      bool useGpu = modelType != ModelType.int8;
      bool quantization = modelType == ModelType.int8;

      try {
        await vision.loadYoloModel(
          labels: 'assets/models/labels.txt',
          modelPath: _modelPaths[modelType]!,
          modelVersion: "yolov8",
          quantization: quantization,
          numThreads: 1,
          useGpu: useGpu,
        );
      } catch (gpuError) {
        if (useGpu) {
          await vision.loadYoloModel(
            labels: 'assets/models/labels.txt',
            modelPath: _modelPaths[modelType]!,
            modelVersion: "yolov8",
            quantization: quantization,
            numThreads: 4,
            useGpu: false,
          );
          useGpu = false;
        } else {
          rethrow;
        }
      }

      _visions[modelType] = vision;
      _isInitialized[modelType] = true;
      return true;
    } catch (e) {
      _isInitialized[modelType] = false;
      return false;
    }
  }

  static Future<bool> initializeAllModels() async {
    final results = await Future.wait([
      initializeModel(ModelType.int8),
      initializeModel(ModelType.float16),
      initializeModel(ModelType.float32),
    ]);

    return results.every((result) => result);
  }

  static bool isModelInitialized(ModelType modelType) {
    return _isInitialized[modelType] == true;
  }

  static bool get areAllModelsInitialized {
    return ModelType.values.every((type) => _isInitialized[type] == true);
  }

  static Future<ModelResult> _detectWithModel(
    ModelType modelType,
    String base64Image,
  ) async {
    final DateTime startTime = DateTime.now();

    try {
      if (!isModelInitialized(modelType)) {
        return ModelResult(
          modelType: modelType,
          detections: [],
          processingTime: DateTime.now().difference(startTime),
          success: false,
          errorMessage: 'Model not initialized',
        );
      }

      final Uint8List imageBytes = base64Decode(base64Image);
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return ModelResult(
          modelType: modelType,
          detections: [],
          processingTime: DateTime.now().difference(startTime),
          success: false,
          errorMessage: 'Failed to decode image',
        );
      }

      final result = await _visions[modelType]!.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: originalImage.height,
        imageWidth: originalImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.5,
        classThreshold: 0.5,
      );

      final DateTime endTime = DateTime.now();

      return ModelResult(
        modelType: modelType,
        detections: result,
        processingTime: endTime.difference(startTime),
        success: true,
      );
    } catch (e) {
      final DateTime endTime = DateTime.now();
      return ModelResult(
        modelType: modelType,
        detections: [],
        processingTime: endTime.difference(startTime),
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<MultiModelComparison?> compareAllModels(
      String base64Image) async {
    if (_isDetecting) return null;
    if (!areAllModelsInitialized) return null;

    _isDetecting = true;
    final DateTime startTime = DateTime.now();

    try {
      final int8Result = await _detectWithModel(ModelType.int8, base64Image);
      final float16Result =
          await _detectWithModel(ModelType.float16, base64Image);
      final float32Result =
          await _detectWithModel(ModelType.float32, base64Image);

      final DateTime endTime = DateTime.now();

      return MultiModelComparison(
        int8Result: int8Result,
        float16Result: float16Result,
        float32Result: float32Result,
        totalProcessingTime: endTime.difference(startTime),
      );
    } catch (e) {
      return null;
    } finally {
      _isDetecting = false;
    }
  }

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

  static String getModelDisplayName(ModelType modelType) {
    switch (modelType) {
      case ModelType.int8:
        return 'INT8 (Quantized)';
      case ModelType.float16:
        return 'FLOAT16 (Half Precision)';
      case ModelType.float32:
        return 'FLOAT32 (Full Precision)';
    }
  }

  static String getModelDescription(ModelType modelType) {
    switch (modelType) {
      case ModelType.int8:
        return 'เร็วที่สุด แต่แม่นยำน้อยกว่า';
      case ModelType.float16:
        return 'สมดุลระหว่างความเร็วและความแม่นยำ';
      case ModelType.float32:
        return 'แม่นยำที่สุด แต่ช้ากว่า';
    }
  }

  static Color getModelColor(ModelType modelType) {
    switch (modelType) {
      case ModelType.int8:
        return Colors.orange;
      case ModelType.float16:
        return Colors.blue;
      case ModelType.float32:
        return Colors.green;
    }
  }

  static Future<void> disposeModel(ModelType modelType) async {
    final vision = _visions[modelType];
    if (vision != null) {
      await vision.closeYoloModel();
      _visions.remove(modelType);
    }
    _isInitialized[modelType] = false;
  }

  static Future<void> disposeAllModels() async {
    await Future.wait(
      ModelType.values.map((type) => disposeModel(type)),
    );
    _colorMap.clear();
  }
}
