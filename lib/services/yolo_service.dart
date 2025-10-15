import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;

enum ModelType { int8, float16, float32 }

class YoloConfig {
  static const String labelsPath = 'assets/models/labels.txt';
  static const String modelVersion = 'yolov8';
  static const double iouThreshold = 0.4;
  static const double confThreshold = 0.5;
  static const double classThreshold = 0.5;

  static const Map<ModelType, String> modelPaths = {
    ModelType.int8: 'assets/models/best_int8_10_15_2025.tflite',
    ModelType.float16: 'assets/models/best_float16_10_15_2025.tflite',
    ModelType.float32: 'assets/models/best_float32_10_15_2025.tflite',
  };

  static int get cpuThreads {
    final processors = Platform.numberOfProcessors;
    if (processors <= 2) return processors;
    if (processors <= 4) return processors - 1;
    return (processors * 0.75).ceil();
  }

  static int get gpuThreads => 2;

  static bool shouldUseGpu(ModelType type) => type != ModelType.int8;
  static bool isQuantized(ModelType type) => type == ModelType.int8;

  static ModelType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'int8':
        return ModelType.int8;
      case 'float16':
        return ModelType.float16;
      case 'float32':
      default:
        return ModelType.float32;
    }
  }
}

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

  factory ModelResult.failure({
    required ModelType modelType,
    required Duration processingTime,
    required String errorMessage,
  }) {
    return ModelResult(
      modelType: modelType,
      detections: [],
      processingTime: processingTime,
      success: false,
      errorMessage: errorMessage,
    );
  }

  int get detectionCount => detections.length;

  Set<String> get detectedClasses =>
      detections.map((d) => d['tag'] as String? ?? 'unknown').toSet();
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

  List<ModelResult> get allResults => [int8Result, float16Result, float32Result]
      .whereType<ModelResult>()
      .toList();

  int get successCount => allResults.where((r) => r.success).length;

  ModelResult? get fastestResult {
    final successful = allResults.where((r) => r.success).toList();
    if (successful.isEmpty) return null;
    return successful
        .reduce((a, b) => a.processingTime < b.processingTime ? a : b);
  }
}

class YoloService {
  static FlutterVision? _singleModelVision;
  static bool _isSingleModelInitialized = false;
  static bool _isDetecting = false;
  static List<Map<String, dynamic>> _lastResults = [];

  static final Map<ModelType, FlutterVision> _multiModelVisions = {};
  static final Map<ModelType, bool> _multiModelInitialized = {};

  static final Random _random = Random();
  static final Map<String, Color> _colorMap = {};

  static bool get isInitialized => _isSingleModelInitialized;
  static List<Map<String, dynamic>> get lastResults =>
      List.unmodifiable(_lastResults);

  static Future<bool> initialize({String? modelType}) async {
    final type = YoloConfig.fromString(modelType);
    _log('Initializing single model: $type');

    try {
      await _disposeSingleModel();

      _singleModelVision = FlutterVision();
      final success = await _loadModel(
        _singleModelVision!,
        type,
        'Single model ${type.name}',
      );

      if (success) {
        _isSingleModelInitialized = true;
        _log('Single model initialization successful: $type');
        return true;
      } else {
        _isSingleModelInitialized = false;
        _log('Single model initialization failed: $type', isError: true);
        return false;
      }
    } catch (e, stackTrace) {
      _logError('Single model initialization error', e, stackTrace);
      _isSingleModelInitialized = false;
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> detectObjects(
      CameraImage image) async {
    if (!_isSingleModelInitialized || _singleModelVision == null) {
      _log('Detection failed: Model not initialized', isError: true);
      return null;
    }

    if (_isDetecting) {
      _log('Detection skipped: Already processing');
      return null;
    }

    _isDetecting = true;
    try {
      final result = await _singleModelVision!.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: YoloConfig.iouThreshold,
        confThreshold: YoloConfig.confThreshold,
        classThreshold: YoloConfig.classThreshold,
      );

      _lastResults = result;
      _log('Frame detection completed: ${result.length} objects');
      return result;
    } catch (e, stackTrace) {
      _logError('Frame detection error', e, stackTrace);
      return null;
    } finally {
      _isDetecting = false;
    }
  }

  static Future<List<Map<String, dynamic>>?> detectObjectsOnImage({
    required String base64Image,
  }) async {
    if (!_isSingleModelInitialized || _singleModelVision == null) {
      _log('Detection failed: Model not initialized', isError: true);
      return null;
    }

    if (_isDetecting) {
      _log('Detection skipped: Already processing');
      return null;
    }

    _isDetecting = true;
    try {
      final imageBytes = base64Decode(base64Image);
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        _log('Image decode failed', isError: true);
        return null;
      }

      final result = await _singleModelVision!.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: YoloConfig.iouThreshold,
        confThreshold: YoloConfig.confThreshold,
        classThreshold: YoloConfig.classThreshold,
      );

      _lastResults = result;
      _log('Image detection completed: ${result.length} objects');
      return result;
    } catch (e, stackTrace) {
      _logError('Image detection error', e, stackTrace);
      return null;
    } finally {
      _isDetecting = false;
    }
  }

  static void clearResults() => _lastResults.clear();

  static Future<void> dispose() async {
    _log('Disposing all resources');
    await _disposeSingleModel();
    await disposeAllModels();
    _colorMap.clear();
  }

  static Future<bool> initializeModel(ModelType modelType) async {
    if (_multiModelInitialized[modelType] == true) {
      _log('Model already initialized: $modelType');
      return true;
    }

    _log('Initializing model: $modelType');

    try {
      final vision = FlutterVision();
      final success = await _loadModel(
        vision,
        modelType,
        'Multi-model ${modelType.name}',
      );

      if (success) {
        _multiModelVisions[modelType] = vision;
        _multiModelInitialized[modelType] = true;
        _log('Model initialization successful: $modelType');
        return true;
      } else {
        _multiModelInitialized[modelType] = false;
        _log('Model initialization failed: $modelType', isError: true);
        return false;
      }
    } catch (e, stackTrace) {
      _logError('Model initialization error: $modelType', e, stackTrace);
      _multiModelInitialized[modelType] = false;
      return false;
    }
  }

  static Future<bool> initializeAllModels() async {
    _log('Initializing all models sequentially');
    final results = <bool>[];

    for (final modelType in ModelType.values) {
      final success = await initializeModel(modelType);
      results.add(success);
    }

    final allSuccess = results.every((r) => r);
    _log('All models initialization ${allSuccess ? "successful" : "failed"}');
    return allSuccess;
  }

  static bool isModelInitialized(ModelType modelType) {
    return _multiModelInitialized[modelType] == true;
  }

  static bool get areAllModelsInitialized {
    return ModelType.values.every((type) => isModelInitialized(type));
  }

  static Future<MultiModelComparison?> compareAllModels(
      String base64Image) async {
    if (_isDetecting) {
      _log('Comparison skipped: Already processing');
      return null;
    }

    if (!areAllModelsInitialized) {
      _log('Comparison failed: Not all models initialized', isError: true);
      return null;
    }

    _isDetecting = true;
    _log('Starting model comparison (sequential)');
    final startTime = DateTime.now();

    try {
      final imageBytes = base64Decode(base64Image);
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        _log('Image decode failed', isError: true);
        return null;
      }

      final int8Result = await _detectWithModel(
        ModelType.int8,
        imageBytes,
        decodedImage,
      );
      final float16Result = await _detectWithModel(
        ModelType.float16,
        imageBytes,
        decodedImage,
      );
      final float32Result = await _detectWithModel(
        ModelType.float32,
        imageBytes,
        decodedImage,
      );

      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);

      _log('Model comparison completed in ${totalTime.inMilliseconds}ms');

      return MultiModelComparison(
        int8Result: int8Result,
        float16Result: float16Result,
        float32Result: float32Result,
        totalProcessingTime: totalTime,
      );
    } catch (e, stackTrace) {
      _logError('Model comparison error', e, stackTrace);
      return null;
    } finally {
      _isDetecting = false;
    }
  }

  static Future<void> disposeModel(ModelType modelType) async {
    final vision = _multiModelVisions[modelType];
    if (vision != null) {
      await vision.closeYoloModel();
      _multiModelVisions.remove(modelType);
      _log('Model disposed: $modelType');
    }
    _multiModelInitialized[modelType] = false;
  }

  static Future<void> disposeAllModels() async {
    _log('Disposing all multi-models');
    for (final modelType in ModelType.values) {
      await disposeModel(modelType);
    }
  }

  static Color getColorForLabel(String label) {
    return _colorMap.putIfAbsent(
      label,
      () => Color.fromARGB(
        255,
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
      ),
    );
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

  static Future<bool> _loadModel(
    FlutterVision vision,
    ModelType modelType,
    String context,
  ) async {
    final modelPath = YoloConfig.modelPaths[modelType]!;
    final useGpu = YoloConfig.shouldUseGpu(modelType);
    final quantization = YoloConfig.isQuantized(modelType);

    _log('Loading model: $context (GPU: $useGpu, Quantized: $quantization)');

    try {
      await vision.loadYoloModel(
        labels: YoloConfig.labelsPath,
        modelPath: modelPath,
        modelVersion: YoloConfig.modelVersion,
        quantization: quantization,
        numThreads: useGpu ? YoloConfig.gpuThreads : YoloConfig.cpuThreads,
        useGpu: useGpu,
      );
      return true;
    } catch (gpuError) {
      if (useGpu) {
        _log('GPU loading failed, retrying with CPU: $context');
        try {
          await vision.loadYoloModel(
            labels: YoloConfig.labelsPath,
            modelPath: modelPath,
            modelVersion: YoloConfig.modelVersion,
            quantization: quantization,
            numThreads: YoloConfig.cpuThreads,
            useGpu: false,
          );
          return true;
        } catch (cpuError) {
          _logError('CPU loading also failed: $context', cpuError, null);
          return false;
        }
      } else {
        _logError('Model loading failed: $context', gpuError, null);
        return false;
      }
    }
  }

  static Future<ModelResult> _detectWithModel(
    ModelType modelType,
    Uint8List imageBytes,
    img.Image decodedImage,
  ) async {
    final startTime = DateTime.now();

    try {
      if (!isModelInitialized(modelType)) {
        return ModelResult.failure(
          modelType: modelType,
          processingTime: Duration.zero,
          errorMessage: 'Model not initialized',
        );
      }

      final result = await _multiModelVisions[modelType]!.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: YoloConfig.iouThreshold,
        confThreshold: YoloConfig.confThreshold,
        classThreshold: YoloConfig.classThreshold,
      );

      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      _log(
          '${modelType.name} detection: ${result.length} objects in ${processingTime.inMilliseconds}ms');

      return ModelResult(
        modelType: modelType,
        detections: result,
        processingTime: processingTime,
        success: true,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      _logError('Detection error: ${modelType.name}', e, null);

      return ModelResult.failure(
        modelType: modelType,
        processingTime: processingTime,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<void> _disposeSingleModel() async {
    if (_singleModelVision != null) {
      await _singleModelVision!.closeYoloModel();
      _singleModelVision = null;
      _log('Single model disposed');
    }
    _isSingleModelInitialized = false;
    _isDetecting = false;
    _lastResults.clear();
  }

  static void _log(String message, {bool isError = false}) {
    developer.log(
      message,
      name: 'YoloService',
      level: isError ? 1000 : 0,
    );
  }

  static void _logError(String message, Object error, StackTrace? stackTrace) {
    developer.log(
      message,
      name: 'YoloService',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
