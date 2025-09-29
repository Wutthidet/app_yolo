import 'package:app_yolo/models/image_data.dart';
import 'package:app_yolo/screens/api_result_screen.dart';
import 'package:app_yolo/services/api_service.dart';
import 'package:app_yolo/widgets/enhanced_preview_screen.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ApiPreviewScreen extends StatefulWidget {
  final ImageData imageData;
  final bool useGpu;

  const ApiPreviewScreen({
    super.key,
    required this.imageData,
    this.useGpu = false,
  });

  @override
  State<ApiPreviewScreen> createState() => _ApiPreviewScreenState();
}

class _ApiPreviewScreenState extends State<ApiPreviewScreen> {
  bool _isProcessing = false;

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = widget.useGpu
          ? await ApiService.detectAndOcrGpu(widget.imageData.base64)
          : await ApiService.detectAndOcr(widget.imageData.base64);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (result != null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ApiResultScreen(
                imageData: widget.imageData,
                apiResult: result,
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
          _showErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.modernBorderRadius,
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppConstants.errorColor,
                size: 24,
              ),
              SizedBox(width: AppConstants.padding),
              Text('เกิดข้อผิดพลาด'),
            ],
          ),
          content: Text(
            widget.useGpu
                ? 'ไม่สามารถประมวลผลภาพผ่าน API GPU ได้\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต'
                : 'ไม่สามารถประมวลผลภาพผ่าน API ได้\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
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
      title: widget.useGpu ? 'API GPU Detection' : 'API CPU Detection',
      subtitle: widget.useGpu
          ? 'ประมวลผลด้วย GPU บนเซิร์ฟเวอร์'
          : 'ประมวลผลด้วย CPU บนเซิร์ฟเวอร์',
      icon: widget.useGpu ? Icons.rocket_launch_rounded : Icons.cloud_rounded,
      gradient: widget.useGpu
          ? const LinearGradient(
              colors: [Colors.purple, Colors.purpleAccent],
            )
          : AppConstants.primaryGradient,
      onProcess: _processImage,
      onRetake: _retakePhoto,
      isProcessing: _isProcessing,
      processingText: widget.useGpu
          ? 'กำลังประมวลผลด้วย GPU...'
          : 'กำลังประมวลผลด้วย API...',
    );
  }
}
