import 'dart:convert';
import 'package:app_yolo/models/image_data.dart';
import 'package:app_yolo/screens/api_preview_screen.dart';
import 'package:app_yolo/screens/ocr_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../utils/constants.dart';
import '../utils/processing_mode.dart';
import 'package:app_yolo/screens/local_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final ProcessingMode processingMode;

  const CameraScreen({
    super.key,
    required this.processingMode,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
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
    Widget screen;
    switch (widget.processingMode) {
      case ProcessingMode.local:
        screen = LocalPreviewScreen(imageData: imageData);
        break;
      case ProcessingMode.ocr:
        screen = OcrPreviewScreen(imageData: imageData);
        break;
      case ProcessingMode.api:
        screen = ApiPreviewScreen(imageData: imageData);
        break;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'กำลังเตรียมกล้อง...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        setState(() {
                          _isInitialized = false;
                        });
                        await _initializeCamera();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _isLoading ? null : _pickFromGallery,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonAnimation.value,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _takePicture,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _isLoading
                                    ? LinearGradient(
                                        colors: [
                                          Colors.grey.withOpacity(0.6),
                                          Colors.grey.withOpacity(0.4),
                                        ],
                                      )
                                    : AppConstants.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 3,
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 60),
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
