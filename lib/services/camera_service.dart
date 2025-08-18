import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:convert';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static final ImagePicker _picker = ImagePicker();

  static Future<bool> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) return false;

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  static CameraController? get controller => _controller;

  static Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      final success = await initializeCamera();
      if (!success) return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      return await _convertToBase64(File(image.path));
    } catch (e) {
      return null;
    }
  }

  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _convertToBase64(File(image.path));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> _convertToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      image = img.bakeOrientation(image);

      final fixedBytes = img.encodeJpg(image, quality: 85);
      return base64Encode(fixedBytes);
    }

    return base64Encode(bytes);
  }

  static String fixBase64ImageOrientation(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        image = img.bakeOrientation(image);

        final fixedBytes = img.encodeJpg(image, quality: 85);
        return base64Encode(fixedBytes);
      }
    } catch (e) {}

    return base64String;
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
