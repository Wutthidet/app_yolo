import 'package:app_yolo/models/image_data.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/ocr_detection_result.dart';
import '../services/yolo_service.dart';
import '../utils/constants.dart';

class OcrResultScreen extends StatefulWidget {
  final ImageData imageData;
  final List<OcrDetectionResult> ocrDetectionResults;
  final DateTime timestamp;

  const OcrResultScreen({
    super.key,
    required this.imageData,
    required this.ocrDetectionResults,
    required this.timestamp,
  });

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  img.Image? _originalImage;

  @override
  void initState() {
    super.initState();
    _decodeImage();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _decodeImage() {
    _originalImage = img.decodeImage(widget.imageData.bytes);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.modernBorderRadius,
        ),
        backgroundColor: AppConstants.glassSurfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppConstants.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.save_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'บันทึกผลลัพธ์',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'ฟีเจอร์บันทึกจะพัฒนาในอนาคต',
          style: TextStyle(color: AppConstants.textSecondaryColor),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppConstants.modernShadow],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ตกลง'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.successColor.withOpacity(0.05),
              AppConstants.backgroundColor,
              AppConstants.accentColor.withOpacity(0.03),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppConstants.glassMorphGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [AppConstants.modernShadow],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(
                    Icons.home_rounded,
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppConstants.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.accentColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _showSaveDialog(context),
                    icon: const Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppConstants.accentGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [AppConstants.glassShadow],
                  ),
                  child: const Text(
                    'ผลการวิเคราะห์ (OCR)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppConstants.successColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 80,
                      color: AppConstants.successColor.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(AppConstants.paddingLarge),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppConstants.successColor.withOpacity(0.1),
                                  AppConstants.accentColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: AppConstants.largeBorderRadius,
                              border: Border.all(
                                color:
                                    AppConstants.successColor.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [AppConstants.modernShadow],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: AppConstants.accentGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppConstants.accentColor
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ประมวลผลสำเร็จ',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'เวลา: ${_formatTime(widget.timestamp)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color:
                                              AppConstants.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingXLarge),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppConstants.modernCardGradient,
                            borderRadius: AppConstants.largeBorderRadius,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                            boxShadow: [AppConstants.cardShadow],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingLarge),
                                decoration: BoxDecoration(
                                  gradient: AppConstants.accentGradient,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(
                                        AppConstants.borderRadiusLarge),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'ตรวจพบ ${widget.ocrDetectionResults.length} วัตถุ',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 380,
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingLarge),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius),
                                  child: _originalImage == null
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : LayoutBuilder(
                                          builder: (context, constraints) {
                                          return Stack(
                                            children: [
                                              Image.memory(
                                                widget.imageData.bytes,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                              CustomPaint(
                                                size: Size(
                                                  constraints.maxWidth,
                                                  constraints.maxHeight,
                                                ),
                                                painter: OcrDetectionPainter(
                                                  results: widget
                                                      .ocrDetectionResults,
                                                  originalImageSize: Size(
                                                    _originalImage!.width
                                                        .toDouble(),
                                                    _originalImage!.height
                                                        .toDouble(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingXLarge),
                        _buildResultsList(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppConstants.modernCardGradient,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusXLarge),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [AppConstants.floatingShadow],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Container(
                  width: double.infinity,
                  height: AppConstants.buttonHeightLarge,
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: AppConstants.modernBorderRadius,
                    boxShadow: [AppConstants.buttonShadow],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppConstants.modernBorderRadius,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ถ่ายรูปใหม่',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายละเอียดผลลัพธ์',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: AppConstants.padding),
        if (widget.ocrDetectionResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppConstants.glassSurfaceColor,
              borderRadius: AppConstants.modernBorderRadius,
              border: Border.all(color: AppConstants.dividerColor),
            ),
            child: const Center(
              child: Text(
                'ไม่พบวัตถุในภาพ',
                style: TextStyle(color: AppConstants.textSecondaryColor),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.ocrDetectionResults.length,
            itemBuilder: (context, index) {
              final result = widget.ocrDetectionResults[index];
              return _buildResultCard(result);
            },
          ),
      ],
    );
  }

  Widget _buildResultCard(OcrDetectionResult result) {
    final String label = result.detectionResult['tag'];
    final Color color = YoloService.getColorForLabel(label);
    final String ocrText = result.ocrText.isNotEmpty ? result.ocrText : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        gradient: AppConstants.modernCardGradient,
        borderRadius: AppConstants.modernBorderRadius,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [AppConstants.modernShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppConstants.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OCR: $ocrText',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppConstants.dividerColor,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class OcrDetectionPainter extends CustomPainter {
  final List<OcrDetectionResult> results;
  final Size originalImageSize;

  OcrDetectionPainter({required this.results, required this.originalImageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double imageAspectRatio =
        originalImageSize.width / originalImageSize.height;
    final double canvasAspectRatio = size.width / size.height;
    double scale;
    double dx = 0;
    double dy = 0;

    if (imageAspectRatio > canvasAspectRatio) {
      scale = size.height / originalImageSize.height;
      dx = (size.width - originalImageSize.width * scale) / 2;
    } else {
      scale = size.width / originalImageSize.width;
      dy = (size.height - originalImageSize.height * scale) / 2;
    }

    for (var result in results) {
      final detection = result.detectionResult;
      final String label = detection['tag'];
      final Color color = YoloService.getColorForLabel(label);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final rect = Rect.fromLTWH(
        detection["box"][0] * scale + dx,
        detection["box"][1] * scale + dy,
        (detection["box"][2] - detection["box"][0]) * scale,
        (detection["box"][3] - detection["box"][1]) * scale,
      );

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: " $label ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            backgroundColor: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final textOffset = Offset(rect.left, rect.top - textPainter.height);

      final finalTextOffsetX =
          textOffset.dx.clamp(0.0, size.width - textPainter.width);
      final finalTextOffsetY =
          textOffset.dy.clamp(0.0, size.height - textPainter.height);

      textPainter.paint(canvas, Offset(finalTextOffsetX, finalTextOffsetY));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
