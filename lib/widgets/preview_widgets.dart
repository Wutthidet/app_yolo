import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ImagePreviewCard extends StatelessWidget {
  final Uint8List imageBytes;
  final Gradient headerGradient;

  const ImagePreviewCard({
    super.key,
    required this.imageBytes,
    required this.headerGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              gradient: headerGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'รูปภาพที่เลือก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Container(
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessingInfoCard extends StatelessWidget {
  final String title;
  final String description;
  const ProcessingInfoCard(
      {super.key,
      this.title = 'พร้อมประมวลผล',
      this.description = 'ระบบ AI จะวิเคราะห์และตรวจจับวัตถุในรูปภาพ'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingXLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.accentColor.withOpacity(0.1),
            AppConstants.successColor.withOpacity(0.05),
          ],
        ),
        borderRadius: AppConstants.largeBorderRadius,
        border: Border.all(
          color: AppConstants.accentColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [AppConstants.modernShadow],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppConstants.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.accentColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondaryColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PreviewBottomBar extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onProcess;
  final VoidCallback onRetake;
  final String processButtonText;

  const PreviewBottomBar({
    super.key,
    required this.isProcessing,
    required this.onProcess,
    required this.onRetake,
    this.processButtonText = 'เริ่มประมวลผล',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: AppConstants.buttonHeightLarge,
                        decoration: BoxDecoration(
                          gradient: AppConstants.accentGradient,
                          borderRadius: AppConstants.modernBorderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.accentColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : onProcess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppConstants.modernBorderRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                processButtonText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: AppConstants.buttonHeightLarge,
                      width: AppConstants.buttonHeightLarge,
                      decoration: BoxDecoration(
                        gradient: AppConstants.glassMorphGradient,
                        borderRadius: AppConstants.modernBorderRadius,
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [AppConstants.modernShadow],
                      ),
                      child: IconButton(
                        onPressed: isProcessing ? null : onRetake,
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppConstants.primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
