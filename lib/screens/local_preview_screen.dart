import 'package:app_yolo/models/image_data.dart';
import 'package:app_yolo/widgets/enhanced_preview_screen.dart';
import 'package:flutter/material.dart';
import '../services/yolo_service.dart';
import '../utils/constants.dart';
import '../utils/processing_mode.dart';
import 'local_result_screen.dart';

class LocalPreviewScreen extends StatefulWidget {
  final ImageData imageData;
  final ProcessingMode? processingMode;

  const LocalPreviewScreen({
    super.key,
    required this.imageData,
    this.processingMode,
  });

  @override
  State<LocalPreviewScreen> createState() => _LocalPreviewScreenState();
}

class _LocalPreviewScreenState extends State<LocalPreviewScreen> {
  bool _isProcessing = false;

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      String? modelType;
      switch (widget.processingMode) {
        case ProcessingMode.localInt8:
          modelType = 'int8';
          break;
        case ProcessingMode.localFloat16:
          modelType = 'float16';
          break;
        case ProcessingMode.localFloat32:
          modelType = 'float32';
          break;
        default:
          modelType = 'float32';
      }

      final yoloSuccess = await YoloService.initialize(modelType: modelType);
      if (!yoloSuccess) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _showErrorDialog('ไม่สามารถโหลด AI Model ได้',
              'กรุณาตรวจสอบไฟล์โมเดลและลองใหม่อีกครั้ง');
        }
        return;
      }

      final results = await YoloService.detectObjectsOnImage(
        base64Image: widget.imageData.base64,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (results != null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  LocalResultScreen(
                imageData: widget.imageData,
                detectionResults: results,
                timestamp: DateTime.now(),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        } else {
          _showErrorDialog('ไม่พบวัตถุในภาพ',
              'ไม่สามารถตรวจจับวัตถุในภาพนี้ได้ กรุณาลองใช้ภาพอื่น');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('เกิดข้อผิดพลาดในการประมวลผล',
            'กรุณาลองใหม่อีกครั้ง หรือเปลี่ยนไปใช้ API mode');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.modernBorderRadius,
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppConstants.errorColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.padding),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  void _retakePhoto() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedPreviewScreen(
      imageBytes: widget.imageData.bytes,
      title: 'Local Detection',
      subtitle: 'ประมวลผลด้วย AI บนอุปกรณ์ของคุณ',
      icon: Icons.phone_android_rounded,
      gradient: AppConstants.accentGradient,
      onProcess: _processImage,
      onRetake: _retakePhoto,
      isProcessing: _isProcessing,
      processingText: 'กำลังประมวลผลบนเครื่อง...',
    );
  }
}
