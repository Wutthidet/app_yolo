import 'package:app_yolo/models/image_data.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SimplePreviewScreen extends StatelessWidget {
  final ImageData imageData;

  const SimplePreviewScreen({
    super.key,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('รูปภาพ'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppConstants.modernBorderRadius,
                    border: Border.all(
                      color: AppConstants.dividerColor,
                      width: 2,
                    ),
                    boxShadow: [AppConstants.cardShadow],
                  ),
                  child: ClipRRect(
                    borderRadius: AppConstants.modernBorderRadius,
                    child: Image.memory(
                      imageData.bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('ถ่ายรูปใหม่'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
