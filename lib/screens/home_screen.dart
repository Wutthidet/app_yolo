// ignore_for_file: deprecated_member_use

import 'package:app_yolo/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/processing_mode.dart';
import 'camera_screen.dart';
import 'real_time_screen.dart';
import 'comparison_screen.dart';
import 'model_comparison_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withOpacity(0.1),
              AppConstants.backgroundColor,
              AppConstants.secondaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingXLarge),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: AppConstants.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [AppConstants.glassShadow],
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                              Text(
                                'YOLO Object Detection',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppConstants.padding),
                              Text(
                                'เลือกวิธีการตรวจจับวัตถุ',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppConstants.textSecondaryColor,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingXLarge * 1.5),
                              _buildMainModeButton(
                                context,
                                icon: Icons.camera_alt_rounded,
                                title: '📸 ถ่ายรูป/เลือกรูป',
                                subtitle: 'ตรวจจับวัตถุจากรูปภาพ',
                                gradient: AppConstants.primaryGradient,
                                onTap: () => _showModeDialog(),
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                              _buildMainModeButton(
                                context,
                                icon: Icons.videocam_rounded,
                                title: '🎥 เรียลไทม์',
                                subtitle: 'ตรวจจับวัตถุจากกล้องสด (บนเครื่อง)',
                                gradient: AppConstants.accentGradient,
                                onTap: () =>
                                    _navigateTo(const RealTimeScreen()),
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                              _buildMainModeButton(
                                context,
                                icon: Icons.text_fields_rounded,
                                title: '📝 ตรวจจับข้อความ',
                                subtitle: 'OCR + Object Detection (บนเครื่อง)',
                                gradient: AppConstants.secondaryGradient,
                                onTap: () => _navigateTo(const CameraScreen(
                                    processingMode: ProcessingMode.ocr)),
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                              _buildMainModeButton(
                                context,
                                icon: Icons.compare_arrows_rounded,
                                title: '⚖️ เปรียบเทียบผลลัพธ์',
                                subtitle:
                                    'ประมวลผล 3 วิธีพร้อมกัน + เปรียบเทียบเวลา',
                                gradient: const LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrange],
                                ),
                                onTap: () =>
                                    _navigateTo(const ComparisonScreen()),
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                              _buildMainModeButton(
                                context,
                                icon: Icons.model_training_rounded,
                                title: '🔧 เปรียบเทียบโมเดล',
                                subtitle: 'ทดสอบประสิทธิภาพโมเดล 3 ตัว (Local)',
                                gradient: const LinearGradient(
                                  colors: [Colors.deepPurple, Colors.indigo],
                                ),
                                onTap: () =>
                                    _navigateTo(const ModelComparisonScreen()),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainModeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: AppConstants.modernCardGradient,
          borderRadius: AppConstants.largeBorderRadius,
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
          boxShadow: [AppConstants.modernShadow],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppConstants.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.paddingLarge),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXLarge),
              child: Text(
                'เลือกโหมดการประมวลผล',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingXLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogOption(
                      icon: Icons.memory_rounded,
                      title: 'FLOAT32 Model',
                      subtitle: 'โมเดลความแม่นยำสูง (32-bit)',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const CameraScreen(
                            processingMode: ProcessingMode.localFloat32));
                      },
                    ),
                    const SizedBox(height: AppConstants.padding),
                    _buildDialogOption(
                      icon: Icons.speed_rounded,
                      title: 'FLOAT16 Model',
                      subtitle: 'โมเดลสมดุลประสิทธิภาพ (16-bit)',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const CameraScreen(
                            processingMode: ProcessingMode.localFloat16));
                      },
                    ),
                    const SizedBox(height: AppConstants.padding),
                    _buildDialogOption(
                      icon: Icons.flash_on_rounded,
                      title: 'INT8 Model',
                      subtitle: 'โมเดลประสิทธิภาพสูง (8-bit)',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const CameraScreen(
                            processingMode: ProcessingMode.localInt8));
                      },
                    ),
                    const SizedBox(height: AppConstants.padding),
                    _buildDialogOption(
                      icon: Icons.cloud_rounded,
                      title: 'API_CPU (เซิร์เวอร์)',
                      subtitle: 'ประมวลผลด้วย CPU',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const CameraScreen(
                            processingMode: ProcessingMode.api));
                      },
                    ),
                    const SizedBox(height: AppConstants.padding),
                    _buildDialogOption(
                      icon: Icons.rocket_launch_rounded,
                      title: 'API_GPU (เซิร์ฟเวอร์)',
                      subtitle: 'ประมวลผลด้วย GPU',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const CameraScreen(
                            processingMode: ProcessingMode.apiGpu));
                      },
                    ),
                    const SizedBox(height: AppConstants.padding),
                    _buildDialogOption(
                      icon: Icons.login_rounded,
                      title: 'Local + Login',
                      subtitle: 'ต้องเข้าสู่ระบบก่อน ประมวลผล',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateTo(const LoginScreen());
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppConstants.modernBorderRadius,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppConstants.paddingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppConstants.textSecondaryColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
