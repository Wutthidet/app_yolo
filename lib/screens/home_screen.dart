import 'package:app_yolo/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/processing_mode.dart';
import 'camera_screen.dart';
import 'real_time_screen.dart';

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
                              const SizedBox(
                                  height: AppConstants.paddingLarge),
                              Text(
                                'เลือกโหมดการทำงาน',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppConstants.padding),
                              Text(
                                'เลือกวิธีการตรวจจับวัตถุที่คุณต้องการ',
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
                              _buildModeButton(
                                context,
                                icon: Icons.cloud_upload_rounded,
                                title: 'โหมดวิเคราะห์ภาพ (API)',
                                subtitle: 'ถ่ายหรือเลือกภาพเพื่อส่งวิเคราะห์',
                                gradient: AppConstants.primaryGradient,
                                onTap: () => _navigateTo(const CameraScreen(
                                    processingMode: ProcessingMode.api)),
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingLarge),
                              _buildModeButton(
                                context,
                                icon: Icons.camera_alt_rounded,
                                title: 'โหมดวิเคราะห์ภาพ (Local)',
                                subtitle: 'ประมวลผลภาพบนอุปกรณ์ของคุณ',
                                gradient: AppConstants.secondaryGradient,
                                onTap: () => _navigateTo(const CameraScreen(
                                    processingMode: ProcessingMode.local)),
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingLarge),
                              _buildModeButton(
                                context,
                                icon: Icons.login_rounded,
                                title: 'โหมดวิเคราะห์ภาพ (Local) + Login',
                                subtitle: 'เข้าสู่ระบบเพื่อใช้งาน',
                                gradient: AppConstants.secondaryGradient,
                                onTap: () => _navigateTo(const LoginScreen()),
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingLarge),
                              _buildModeButton(
                                context,
                                icon: Icons.document_scanner_rounded,
                                title: 'โหมดวิเคราะห์ภาพ + OCR',
                                subtitle: 'ตรวจจับวัตถุและอ่านตัวอักษร',
                                gradient: AppConstants.accentGradient,
                                onTap: () => _navigateTo(const CameraScreen(
                                    processingMode: ProcessingMode.ocr)),
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingLarge),
                              _buildModeButton(
                                context,
                                icon: Icons.smart_screen_rounded,
                                title: 'โหมดเรียลไทม์',
                                subtitle: 'ตรวจจับวัตถุจากกล้องแบบสดๆ',
                                gradient: AppConstants.accentGradient,
                                onTap: () =>
                                    _navigateTo(const RealTimeScreen()),
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

  Widget _buildModeButton(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppConstants.padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppConstants.textSecondaryColor),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppConstants.textSecondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
