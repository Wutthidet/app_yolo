import 'package:app_yolo/models/image_data.dart';
import 'package:app_yolo/widgets/preview_widgets.dart';
import 'package:flutter/material.dart';
import '../services/yolo_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import 'local_result_screen.dart';

class LocalPreviewScreen extends StatefulWidget {
  final ImageData imageData;

  const LocalPreviewScreen({
    super.key,
    required this.imageData,
  });

  @override
  State<LocalPreviewScreen> createState() => _LocalPreviewScreenState();
}

class _LocalPreviewScreenState extends State<LocalPreviewScreen>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  bool _showProcessButton = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    final yoloSuccess = await YoloService.initialize();
    if (!yoloSuccess) {
      _showErrorDialog('ไม่สามารถโหลด AI Model ได้');
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final results = await YoloService.detectObjectsOnImage(
        base64Image: widget.imageData.base64);

    setState(() {
      _isProcessing = false;
    });

    if (results != null && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LocalResultScreen(
            imageData: widget.imageData,
            detectionResults: results,
            timestamp: DateTime.now(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      );
    } else {
      _showErrorDialog('ไม่สามารถประมวลผลรูปภาพได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  void _showErrorDialog(String message) {
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppConstants.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
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
          Container(
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.05),
                  AppConstants.backgroundColor,
                  AppConstants.accentColor.withOpacity(0.03),
                ],
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppConstants.textColor,
                      size: 20,
                    ),
                  ),
                ),
                actions: [
                  Container(
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
                        setState(() {
                          _showProcessButton = !_showProcessButton;
                        });
                      },
                      icon: Icon(
                        _showProcessButton
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppConstants.textColor,
                        size: 20,
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
                      gradient: AppConstants.secondaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [AppConstants.glassShadow],
                    ),
                    child: const Text(
                      'ตรวจสอบรูปภาพ (Local)',
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
                          AppConstants.secondaryColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.preview_rounded,
                        size: 80,
                        color: AppConstants.secondaryColor.withOpacity(0.2),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: ImagePreviewCard(
                              imageBytes: widget.imageData.bytes,
                              headerGradient: AppConstants.secondaryGradient,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingXLarge),
                          const ProcessingInfoCard(),
                          SizedBox(height: _showProcessButton ? 140 : 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showProcessButton)
            PreviewBottomBar(
              isProcessing: _isProcessing,
              onProcess: _processImage,
              onRetake: () => Navigator.pop(context),
            ),
          if (_isProcessing) const LoadingWidget(),
        ],
      ),
    );
  }
}

