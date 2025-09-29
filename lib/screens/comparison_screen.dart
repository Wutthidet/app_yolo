import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/api_detection_result.dart';
import '../services/api_service.dart';
import '../services/multi_model_yolo_service.dart';
import '../utils/constants.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  File? _selectedImage;
  String? _base64Image;
  bool _isProcessing = false;

  ComparisonResult? _results;
  MultiModelComparison? _modelResults;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _results = null;
        });
        await _prepareImageData();
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเลือกรูปภาพ');
    }
  }

  Future<void> _prepareImageData() async {
    if (_selectedImage == null) return;

    try {
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();
      _base64Image = base64Encode(imageBytes);
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเตรียมข้อมูลรูปภาพ');
    }
  }

  Future<void> _processComparison() async {
    if (_base64Image == null) return;

    setState(() {
      _isProcessing = true;
      _results = null;
      _modelResults = null;
    });

    try {
      final DateTime startTime = DateTime.now();

      await MultiModelYoloService.initializeAllModels();

      final List<Future> futures = [
        _processApiCpu(),
        _processApiGpu(),
      ];

      final apiResults = await Future.wait(futures);
      final modelComparison = await MultiModelYoloService.compareAllModels(_base64Image!);

      final DateTime endTime = DateTime.now();

      setState(() {
        _results = ComparisonResult(
          localResult: null,
          apiCpuResult: apiResults[0] as ProcessingResult?,
          apiGpuResult: apiResults[1] as ProcessingResult?,
          totalProcessingTime: endTime.difference(startTime),
        );
        _modelResults = modelComparison;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('เกิดข้อผิดพลาดในการประมวลผล');
    }
  }


  Future<ProcessingResult?> _processApiCpu() async {
    final DateTime startTime = DateTime.now();
    try {
      final result = await ApiService.detectAndOcr(_base64Image!);
      final DateTime endTime = DateTime.now();

      return ProcessingResult(
        success: result != null,
        apiResult: result,
        processingTime: endTime.difference(startTime),
        errorMessage: result == null ? 'API CPU ล้มเหลว' : null,
      );
    } catch (e) {
      final DateTime endTime = DateTime.now();
      return ProcessingResult(
        success: false,
        processingTime: endTime.difference(startTime),
        errorMessage: 'เกิดข้อผิดพลาด: ${e.toString()}',
      );
    }
  }

  Future<ProcessingResult?> _processApiGpu() async {
    final DateTime startTime = DateTime.now();
    try {
      final result = await ApiService.detectAndOcrGpu(_base64Image!);
      final DateTime endTime = DateTime.now();

      return ProcessingResult(
        success: result != null,
        apiResult: result,
        processingTime: endTime.difference(startTime),
        errorMessage: result == null ? 'API GPU ล้มเหลว' : null,
      );
    } catch (e) {
      final DateTime endTime = DateTime.now();
      return ProcessingResult(
        success: false,
        processingTime: endTime.difference(startTime),
        errorMessage: 'เกิดข้อผิดพลาด: ${e.toString()}',
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'เลือกแหล่งที่มาของรูปภาพ',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.camera_alt_rounded,
                    title: 'กล้อง',
                    onTap: () {
                      Navigator.pop(context);
                      _selectImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.padding),
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.photo_library_rounded,
                    title: 'แกลเลอรี่',
                    onTap: () {
                      Navigator.pop(context);
                      _selectImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: AppConstants.primaryGradient,
          borderRadius: AppConstants.modernBorderRadius,
          boxShadow: [AppConstants.modernShadow],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เกิดข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เปรียบเทียบผลลัพธ์'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withValues(alpha: 0.1),
              AppConstants.backgroundColor,
              AppConstants.secondaryColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Column(
              children: [
                _buildImageSection(),
                const SizedBox(height: AppConstants.paddingXLarge),
                if (_selectedImage != null && !_isProcessing)
                  _buildProcessButton(),
                if (_isProcessing) _buildLoadingSection(),
                if (_results != null) _buildResultsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: AppConstants.modernCardGradient,
        borderRadius: AppConstants.largeBorderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [AppConstants.modernShadow],
      ),
      child: _selectedImage == null
          ? _buildImagePlaceholder()
          : _buildSelectedImage(),
    );
  }

  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: AppConstants.largeBorderRadius,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 64,
            color: AppConstants.textSecondaryColor,
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'แตะเพื่อเลือกรูปภาพ',
            style: TextStyle(
              color: AppConstants.textSecondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppConstants.largeBorderRadius,
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processComparison,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.modernBorderRadius,
          ),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return AppConstants.primaryColor;
          }),
        ),
        child: const Text(
          'เริ่มเปรียบเทียบ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingXLarge),
          decoration: BoxDecoration(
            gradient: AppConstants.modernCardGradient,
            borderRadius: AppConstants.largeBorderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [AppConstants.modernShadow],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              Text(
                'กำลังเปรียบเทียบประสิทธิภาพ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.padding),
              const Text(
                'ระบบกำลังประมวลผลด้วย 3 วิธีพร้อมกัน',
                style: TextStyle(
                  color: AppConstants.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        _buildProcessingMethods(),
      ],
    );
  }

  Widget _buildProcessingMethods() {
    return Column(
      children: [
        _buildMethodProgressCard(
          'FLOAT32 Model',
          'โมเดลความแม่นยำสูง (32-bit)',
          Icons.memory_rounded,
          Colors.green,
          true,
        ),
        const SizedBox(height: AppConstants.padding),
        _buildMethodProgressCard(
          'FLOAT16 Model',
          'โมเดลสมดุลประสิทธิภาพ (16-bit)',
          Icons.speed_rounded,
          Colors.blue,
          true,
        ),
        const SizedBox(height: AppConstants.padding),
        _buildMethodProgressCard(
          'INT8 Model',
          'โมเดลประสิทธิภาพสูง (8-bit)',
          Icons.flash_on_rounded,
          Colors.orange,
          true,
        ),
        const SizedBox(height: AppConstants.padding),
        _buildMethodProgressCard(
          'API CPU',
          'ประมวลผลด้วยเซิร์ฟเวอร์ CPU',
          Icons.cloud_rounded,
          Colors.indigo,
          true,
        ),
        const SizedBox(height: AppConstants.padding),
        _buildMethodProgressCard(
          'API GPU',
          'ประมวลผลด้วยเซิร์ฟเวอร์ GPU',
          Icons.rocket_launch_rounded,
          Colors.purple,
          true,
        ),
      ],
    );
  }

  Widget _buildMethodProgressCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isProcessing,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppConstants.modernBorderRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppConstants.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (isProcessing)
                  LinearProgressIndicator(
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
              ],
            ),
          ),
          if (isProcessing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_results == null && _modelResults == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ผลลัพธ์การเปรียบเทียบ',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        _buildSummaryCard(),
        const SizedBox(height: AppConstants.paddingLarge),
        if (_modelResults != null) ...[
          _buildModelResultCard('FLOAT32 Model', _modelResults!.float32Result, Colors.green),
          const SizedBox(height: AppConstants.padding),
          _buildModelResultCard('FLOAT16 Model', _modelResults!.float16Result, Colors.blue),
          const SizedBox(height: AppConstants.padding),
          _buildModelResultCard('INT8 Model', _modelResults!.int8Result, Colors.orange),
          const SizedBox(height: AppConstants.padding),
        ],
        if (_results != null) ...[
          _buildMethodCard('API CPU', _results!.apiCpuResult, Colors.indigo),
          const SizedBox(height: AppConstants.padding),
          _buildMethodCard('API GPU', _results!.apiGpuResult, Colors.purple),
        ],
      ],
    );
  }

  Widget _buildSummaryCard() {
    final allResults = [
      _modelResults?.int8Result?.success,
      _modelResults?.float16Result?.success,
      _modelResults?.float32Result?.success,
      _results?.apiCpuResult?.success,
      _results?.apiGpuResult?.success,
    ].where((s) => s == true).length;

    final totalResults = [
      _modelResults?.int8Result,
      _modelResults?.float16Result,
      _modelResults?.float32Result,
      _results?.apiCpuResult,
      _results?.apiGpuResult,
    ].where((r) => r != null).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppConstants.accentGradient,
        borderRadius: AppConstants.modernBorderRadius,
        boxShadow: [AppConstants.modernShadow],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: AppConstants.padding),
          Text(
            'สรุปผลลัพธ์',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppConstants.padding),
          Text(
            'ประมวลผลสำเร็จ: $allResults/$totalResults วิธี',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (_results?.totalProcessingTime != null)
            Text(
              'เวลารวม: ${_results!.totalProcessingTime.inMilliseconds} ms',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          if (_modelResults?.totalProcessingTime != null)
            Text(
              'เวลาโมเดล: ${_modelResults!.totalProcessingTime.inMilliseconds} ms',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String title, ProcessingResult? result, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.modernBorderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result?.success == true
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      result?.success == true ? 'สำเร็จ' : 'ล้มเหลว',
                      style: TextStyle(
                        color: result?.success == true ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${result?.processingTime.inMilliseconds ?? 0} ms',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (result?.errorMessage != null) ...[
            const SizedBox(height: AppConstants.padding),
            Text(
              'ข้อผิดพลาด: ${result!.errorMessage}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (result?.success == true) ...[
            const SizedBox(height: AppConstants.padding),
            if (result!.detections?.isNotEmpty == true)
              Text('ตรวจพบวัตถุ: ${result.detections!.length} ชิ้น'),
            if (result.apiResult?.detections.isNotEmpty == true)
              Text('ตรวจพบวัตถุ: ${result.apiResult!.detections.length} ชิ้น'),
            if (result.ocrText?.isNotEmpty == true)
              Text('พบข้อความ: ${result.ocrText!.length} ตัวอักษร'),
            if (result.apiResult?.detections.isNotEmpty == true)
              Text('พบข้อความ: ${result.apiResult!.detections.where((d) => d.text.isNotEmpty).length} รายการ'),
          ],
        ],
      ),
    );
  }

  Widget _buildModelResultCard(String title, ModelResult? result, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.modernBorderRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result?.success == true
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      result?.success == true ? 'สำเร็จ' : 'ล้มเหลว',
                      style: TextStyle(
                        color: result?.success == true ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${result?.processingTime.inMilliseconds ?? 0} ms',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (result?.errorMessage != null) ...[
            const SizedBox(height: AppConstants.padding),
            Text(
              'ข้อผิดพลาด: ${result!.errorMessage}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (result?.success == true) ...[
            const SizedBox(height: AppConstants.padding),
            Text('ตรวจพบวัตถุ: ${result!.detections.length} ชิ้น'),
            if (result.detections.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'รายการที่ตรวจพบ: ${result.detections.map((d) => d['tag']).toSet().join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class ComparisonResult {
  final ProcessingResult? localResult;
  final ProcessingResult? apiCpuResult;
  final ProcessingResult? apiGpuResult;
  final Duration totalProcessingTime;

  ComparisonResult({
    this.localResult,
    this.apiCpuResult,
    this.apiGpuResult,
    required this.totalProcessingTime,
  });
}

class ProcessingResult {
  final bool success;
  final List<Map<String, dynamic>>? detections;
  final String? ocrText;
  final ApiDetectionResult? apiResult;
  final Duration processingTime;
  final String? errorMessage;

  ProcessingResult({
    required this.success,
    this.detections,
    this.ocrText,
    this.apiResult,
    required this.processingTime,
    this.errorMessage,
  });
}