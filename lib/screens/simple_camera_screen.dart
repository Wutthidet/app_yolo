import 'dart:convert';
import 'package:app_yolo/models/image_data.dart';
import 'package:app_yolo/screens/simple_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../utils/constants.dart';

class SimpleCameraScreen extends StatefulWidget {
  const SimpleCameraScreen({super.key});

  @override
  State<SimpleCameraScreen> createState() => _SimpleCameraScreenState();
}

class _SimpleCameraScreenState extends State<SimpleCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isInitialized = false;
  bool _isLoading = false;
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reinitializeCameraIfNeeded();
    }
  }

  Future<void> _initializeCamera() async {
    final success = await CameraService.initializeCamera();
    if (mounted) {
      setState(() {
        _isInitialized = success;
      });
    }
  }

  Future<void> _reinitializeCameraIfNeeded() async {
    if (CameraService.controller == null ||
        !CameraService.controller!.value.isInitialized) {
      await _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (_isLoading) return;

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    setState(() {
      _isLoading = true;
    });

    final base64Image = await CameraService.takePicture();

    setState(() {
      _isLoading = false;
    });

    if (base64Image != null && mounted) {
      final imageData =
          ImageData(base64: base64Image, bytes: base64Decode(base64Image));
      _navigateToPreview(imageData);
    } else {
      _showErrorDialog('ไม่สามารถถ่ายรูปได้');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final base64Image = await CameraService.pickImageFromGallery();

    setState(() {
      _isLoading = false;
    });

    if (base64Image != null && mounted) {
      final imageData =
          ImageData(base64: base64Image, bytes: base64Decode(base64Image));
      _navigateToPreview(imageData);
    }
  }

  void _navigateToPreview(ImageData imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplePreviewScreen(imageData: imageData),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppConstants.errorColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppConstants.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _buttonController.dispose();
    CameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && CameraService.controller != null)
            SizedBox.expand(
              child: ClipRRect(
                child: CameraPreview(CameraService.controller!),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: IconButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              color: Colors.black.withOpacity(0.5),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _isLoading ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 32),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _takePicture,
                      child: ScaleTransition(
                        scale: _buttonAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey,
                              width: 4,
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppConstants.primaryColor),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
