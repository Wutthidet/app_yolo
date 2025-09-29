import 'package:app_yolo/models/image_data.dart';
import 'package:app_yolo/models/ocr_detection_result.dart';
import 'package:app_yolo/screens/ocr_result_screen.dart';
import 'package:app_yolo/services/ocr_service.dart';
import 'package:app_yolo/widgets/enhanced_preview_screen.dart';
import 'package:flutter/material.dart';
import '../services/yolo_service.dart';
import '../utils/constants.dart';

class OcrPreviewScreen extends StatefulWidget {
  final ImageData imageData;

  const OcrPreviewScreen({
    super.key,
    required this.imageData,
  });

  @override
  State<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends State<OcrPreviewScreen> {
  bool _isProcessing = false;

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final futures = await Future.wait([
        YoloService.initialize(),
        OcrService.initialize(),
      ]);

      final yoloSuccess = futures[0];
      final ocrSuccess = futures[1];

      if (!yoloSuccess || !ocrSuccess) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _showErrorDialog(
            'ไม่สามารถโหลดโมเดล AI ได้',
            yoloSuccess
                ? 'ไม่สามารถเริ่มต้น OCR Service ได้'
                : 'ไม่สามารถโหลดโมเดล YOLO ได้',
          );
        }
        return;
      }

      final results = await Future.wait([
        YoloService.detectObjectsOnImage(base64Image: widget.imageData.base64),
        OcrService.performOcr(widget.imageData.bytes),
      ]);

      final objectDetectionResults = results[0];
      final ocrResults = results[1];

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        final List<OcrDetectionResult> combinedResults = [];
        final detections = objectDetectionResults ?? [];
        final ocrs = ocrResults ?? [];

        if (detections.isNotEmpty || ocrs.isNotEmpty) {
          if (detections.isNotEmpty) {
            for (var detection in detections) {
              combinedResults.add(OcrDetectionResult(
                objectDetections: [detection],
                ocrResults: ocrs,
                timestamp: DateTime.now(),
              ));
            }
          } else {
            combinedResults.add(OcrDetectionResult(
              objectDetections: [],
              ocrResults: ocrs,
              timestamp: DateTime.now(),
            ));
          }
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                OcrResultScreen(
              imageData: widget.imageData,
              ocrDetectionResults: combinedResults,
              timestamp: DateTime.now(),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog(
          'เกิดข้อผิดพลาดในการประมวลผล',
          'กรุณาลองใหม่อีกครั้ง หากปัญหายังคงอยู่ กรุณาใช้โหมดอื่น',
        );
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
      title: 'OCR + Detection',
      subtitle: 'ตรวจจับวัตถุและอ่านข้อความในภาพ',
      icon: Icons.text_fields_rounded,
      gradient: AppConstants.secondaryGradient,
      onProcess: _processImage,
      onRetake: _retakePhoto,
      isProcessing: _isProcessing,
      processingText: 'กำลังวิเคราะห์ภาพและข้อความ...',
    );
  }
}
