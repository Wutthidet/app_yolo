# เอกสารการพัฒนาเชิงลึก: การผสาน YOLOv8 เข้ากับ Flutter (Deep Dive)

เอกสารฉบับนี้มีเป้าหมายเพื่อให้ความเข้าใจในระดับลึกเกี่ยวกับการนำโมเดล YOLOv8 มาใช้งานในโปรเจกต์ Flutter ผ่านไลบรารี `flutter_vision` โดยจะครอบคลุมตั้งแต่แนวคิดพื้นฐาน, สถาปัตยกรรม, การทำงานภายใน, การนำไปใช้, และเทคนิคการปรับจูนประสิทธิภาพ

---

### **สารบัญ**
1.  [**ภาพรวมสถาปัตยกรรม (Architecture Overview)**](#1-ภาพรวมสถาปัตยกรรม-architecture-overview)
2.  [**แนวคิดหลักที่ควรรู้ (Core Concepts Explained)**](#2-แนวคิดหลักที่ควรรู้-core-concepts-explained)
3.  [**การตั้งค่าโปรเจกต์โดยละเอียด (Detailed Project Setup)**](#3-การตั้งค่าโปรเจกต์โดยละเอียด-detailed-project-setup)
4.  [**การทำงานของ `YoloService` (Inside `YoloService.dart`)**](#4-การทำงานของ-yoloservice-inside-yoloservicedart)
5.  [**การนำไปใช้ใน UI (Practical UI Implementation)**](#5-การนำไปใช้ใน-ui-practical-ui-implementation)
6.  [**เทคนิคการปรับจูนประสิทธิภาพ (Performance Tuning Techniques)**](#6-เทคนิคการปรับจูนประสิทธิภาพ-performance-tuning-techniques)
7.  [**การแก้ไขปัญหาเชิงลึก (Advanced Troubleshooting)**](#7-การแก้ไขปัญหาเชิงลึก-advanced-troubleshooting)

---

### **1. ภาพรวมสถาปัตยกรรม (Architecture Overview)**

สถาปัตยกรรมของระบบตรวจจับวัตถุในแอปนี้แบ่งออกเป็น 4 ชั้น (Layers):

1.  **UI Layer (Flutter Widgets)**:
    -   ทำหน้าที่รับ Input จากผู้ใช้ (เช่น การกดปุ่มเลือกรูป) และแสดงผลลัพธ์ (วาด `CameraPreview` และ Bounding Boxes)
    -   จัดการ State ของหน้าจอ เช่น สถานะการโหลด, รูปภาพที่เลือก, ผลลัพธ์การตรวจจับ
2.  **Service Layer (`YoloService.dart`)**:
    -   เป็นตัวกลาง (Facade) ที่ซ่อนความซับซ้อนทั้งหมดไว้
    -   จัดการ Lifecycle ของโมเดล (โหลด, ปิด) และเป็นจุดเดียวที่ UI Layer จะเข้ามาเรียกใช้งาน (Single Point of Access)
3.  **Vision Layer (`flutter_vision` library)**:
    -   ไลบรารีที่ทำหน้าที่เป็น Bridge เชื่อมระหว่างโค้ด Dart และ Native Code (Java/Kotlin)
    -   จัดการงานหนักๆ เช่น การส่งข้อมูลรูปภาพไปยัง TFLite, การเรียกใช้ Interpreter, และการทำ Post-processing (NMS)
4.  **Inference Engine (TensorFlow Lite)**:
    -   เป็น Engine ที่ทำงานอยู่บน Native Layer (Android/iOS)
    -   ทำหน้าที่รันโมเดล `.tflite` บน CPU หรือ GPU ของอุปกรณ์เพื่อทำการคำนวณและส่งผลลัพธ์กลับมา

![Architecture Diagram](https://i.imgur.com/9gZ3e4E.png) <!-- เป็นเพียงตัวอย่างภาพประกอบ -->

---

### **2. แนวคิดหลักที่ควรรู้ (Core Concepts Explained)**

-   **YOLOv8 (You Only Look Once v8)**:
    -   เป็นสถาปัตยกรรมโมเดล Object Detection แบบ Single-stage ที่มีความเร็วและความแม่นยำสูง
    -   **Anchor-Free**: แตกต่างจากเวอร์ชันเก่าๆ YOLOv8 ไม่ได้ใช้ Anchor Boxes ที่กำหนดไว้ล่วงหน้า แต่จะทำนายจุดศูนย์กลางของวัตถุโดยตรง ทำให้มีความยืดหยุ่นกับวัตถุที่มีรูปร่างหลากหลาย
    -   **Decoupled Head**: ส่วนหัวของโมเดล (ส่วนที่ทำนายผล) ถูกแยกการทำงานระหว่างการทำนาย Bounding Box และการจำแนกคลาสออกจากกัน ซึ่งช่วยเพิ่มความแม่นยำ
-   **TensorFlow Lite (TFLite)**:
    -   เป็น Framework ของ Google ที่ถูกออกแบบมาเพื่อรันโมเดล Machine Learning บนอุปกรณ์พกพา (Edge Devices) โดยเฉพาะ มีขนาดเล็กและใช้ทรัพยากรน้อย
    -   **Interpreter**: คือแกนหลักของ TFLite ที่ทำหน้าที่โหลดโมเดล `.tflite` และรันการคำนวณ (Inference) ตาม Operation ที่กำหนดไว้ในโมเดล
    -   **Delegates (GPU/NNAPI)**: เป็นกลไกที่ TFLite ใช้เพื่อเร่งความเร็วในการประมวลผลโดยการย้ายภาระงานไปยัง Hardware เฉพาะทาง เช่น GPU หรือ Neural Processing Unit (NPU) การตั้งค่า `useGpu: true` ใน `flutter_vision` คือการสั่งให้ TFLite ใช้ GPU Delegate
-   **Image Pre-processing (การเตรียมข้อมูลภาพ)**:
    -   ก่อนที่รูปภาพจะถูกส่งเข้าโมเดล มันต้องผ่านการประมวลผลก่อน ซึ่ง `flutter_vision` จัดการให้เราโดยอัตโนมัติ:
        1.  **Resizing**: รูปภาพจะถูกปรับขนาดให้เท่ากับขนาด Input ที่โมเดลต้องการ (เช่น 640x640 pixels)
        2.  **Normalization**: ค่าสีของแต่ละ Pixel ซึ่งปกติมีค่า 0-255 จะถูกแปลงให้อยู่ในช่วง 0.0-1.0 โดยการหารด้วย 255.0
        3.  **Tensor Conversion**: ข้อมูลรูปภาพจะถูกแปลงเป็นโครงสร้างข้อมูลที่เรียกว่า "Tensor" (ในที่นี้คือ `[1, 640, 640, 3]`) เพื่อส่งเข้าโมเดล
-   **Post-processing & Non-Max Suppression (NMS)**:
    -   หลังจากโมเดลประมวลผลเสร็จ มันจะให้ Output เป็น Tensor ขนาดใหญ่ (`[1, 84, 8400]` สำหรับ YOLOv8n ที่มี 80 คลาส) ซึ่งยังใช้งานไม่ได้ทันที
    -   `flutter_vision` จะทำ Post-processing ให้เรา:
        1.  **Decoding**: แปลง Tensor ดิบให้เป็นข้อมูลที่เข้าใจง่าย (พิกัด Box, Confidence Score, Class Scores)
        2.  **Filtering**: คัดกรองผลลัพธ์ที่มีค่า Confidence ต่ำกว่า `confThreshold` ทิ้งไป
        3.  **NMS**: ในตอนแรก โมเดลอาจตรวจเจอวัตถุเดียวกันหลายครั้งและสร้าง Bounding Box ซ้อนกันจำนวนมาก NMS คืออัลกอริทึมที่ใช้แก้ปัญหานี้ โดยจะเลือก Box ที่มี Confidence สูงสุดไว้ และลบ Box อื่นที่ซ้อนทับกัน (วัดด้วย IoU) เกินค่า `iouThreshold` ทิ้งไป

---

### **3. การตั้งค่าโปรเจกต์โดยละเอียด (Detailed Project Setup)**

#### **`android/app/build.gradle`**
การตั้งค่า `aaptOptions` เป็นสิ่งจำเป็นอย่างยิ่ง

```groovy
android {
    // ...
    // ส่วนนี้จะป้องกันไม่ให้ Android บีบอัดไฟล์โมเดล ซึ่งจะทำให้ไฟล์เสียหาย
    aaptOptions {
        noCompress 'tflite'
    }
    // ...
    defaultConfig {
        // ...
        // API 21 เป็นขั้นต่ำที่แนะนำสำหรับ TFLite
        minSdkVersion 21
        // ...
    }
}
```

#### **`android/app/src/main/AndroidManifest.xml`**
ต้องมีการขออนุญาตใช้กล้องอย่างชัดเจน

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ขออนุญาตใช้กล้อง -->
    <uses-permission android:name="android.permission.CAMERA" />
    <application ...>
        <!-- ... -->
    </application>
</manifest>
```

---

### **4. การทำงานของ `YoloService` (Inside `YoloService.dart`)**

`YoloService` ถูกออกแบบให้เป็น Static Class เพื่อให้เป็น Global Access Point สำหรับการจัดการโมเดล

#### **`initialize()`**
ฟังก์ชันนี้เปรียบเสมือน "สวิตช์หลัก" ที่ต้องเปิดก่อนใช้งาน

```dart
// lib/services/yolo_service.dart

static Future<bool> initialize() async {
  // ป้องกันการโหลดซ้ำซ้อน
  if (_isInitialized) return true;

  try {
    _vision = FlutterVision();
    // โหลดโมเดลจาก Assets พร้อมตั้งค่าพารามิเตอร์
    await _vision!.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/best_float32.tflite',
      modelVersion: "yolov8", // สำคัญมาก! ต้องตรงกับเวอร์ชันโมเดล
      quantization: false, // โมเดลเป็น float32
      numThreads: 1,       // ใช้ 1 thread สำหรับงาน inference
      useGpu: true,        // เปิดใช้งาน GPU Delegate เพื่อประสิทธิภาพสูงสุด
    );
    _isInitialized = true;
    return true;
  } catch (e) {
    // หากเกิดข้อผิดพลาดในการโหลด
    print("Error initializing YoloService: $e");
    _isInitialized = false;
    return false;
  }
}
```

#### **`detectObjects(CameraImage image)`**
ฟังก์ชันนี้ถูกออกแบบมาเพื่อทำงานกับ Stream ภาพจากกล้อง

```dart
// lib/services/yolo_service.dart

static Future<List<Map<String, dynamic>>?> detectObjects(CameraImage image) async {
  // ตรวจสอบว่าโมเดลพร้อมและไม่มีการประมวลผลอื่นค้างอยู่
  if (!_isInitialized || _vision == null || _isDetecting) {
    return null;
  }

  _isDetecting = true; // ล็อกเพื่อป้องกันการรันซ้อน
  try {
    // ส่งข้อมูลภาพ (planes), ขนาด, และ Thresholds ไปยัง flutter_vision
    final result = await _vision!.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,      // กรอง Box ที่ซ้อนกันเกิน 40%
      confThreshold: 0.5,   // กรองวัตถุที่ความมั่นใจต่ำกว่า 50%
      classThreshold: 0.5,
    );

    _lastResults = result; // เก็บผลลัพธ์ล่าสุด
    return result;
  } catch (e) {
    print("Error during object detection: $e");
    return null;
  } finally {
    _isDetecting = false; // ปลดล็อก
  }
}
```

---

### **5. การนำไปใช้ใน UI (Practical UI Implementation)**

#### **การจัดการ `CameraController` และ Image Stream**

ใน `StatefulWidget` ของหน้าจอที่ใช้กล้อง:

```dart
// lib/screens/real_time_screen.dart (ตัวอย่าง)

class RealTimeScreen extends StatefulWidget {
  // ...
}

class _RealTimeScreenState extends State<RealTimeScreen> {
  CameraController? _cameraController;
  bool _isModelInitialized = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. โหลดโมเดล YOLO
    await YoloService.initialize();
    setState(() {
      _isModelInitialized = YoloService.isInitialized;
    });

    if (!_isModelInitialized) return;

    // 2. ตั้งค่ากล้อง
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController!.initialize();

    // 3. เริ่มต้น Image Stream เพื่อรับภาพแบบ Real-time
    _cameraController!.startImageStream((CameraImage image) {
      // เรียกใช้ YoloService เพื่อตรวจจับวัตถุ
      YoloService.detectObjects(image).then((results) {
        if (results != null && mounted) {
          setState(() {
            _results = results;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    // หยุด Stream และคืนทรัพยากรกล้องและโมเดล
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    YoloService.dispose();
    super.dispose();
  }

  // ... build method ...
}
```

#### **การวาด Bounding Box ด้วย `CustomPaint` (วิธีที่แนะนำ)**

การใช้ `CustomPaint` มีประสิทธิภาพดีกว่าการสร้าง Widget จำนวนมาก

1.  **สร้าง `BoxPainter` Class:**

    ```dart
    // lib/widgets/box_painter.dart

    import 'package:flutter/material.dart';

    class BoxPainter extends CustomPainter {
      final List<Map<String, dynamic>> results;
      final Size imageSize;

      BoxPainter({required this.results, required this.imageSize});

      @override
      void paint(Canvas canvas, Size size) {
        final double scaleX = size.width / imageSize.width;
        final double scaleY = size.height / imageSize.height;

        for (var result in results) {
          final box = result['box'];
          final tag = result['tag'];
          final confidence = (result['confidence'] * 100).toStringAsFixed(0);

          // แปลงพิกัดที่ได้จากโมเดลให้ตรงกับขนาดของ Widget ที่แสดงผล
          final rect = Rect.fromLTWH(
            box[0] * scaleX,
            box[1] * scaleY,
            box[2] * scaleX,
            box[3] * scaleY,
          );

          final paint = Paint()
            ..color = YoloService.getColorForLabel(tag) // ใช้สีที่สุ่มไว้
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

          // วาดสี่เหลี่ยม
          canvas.drawRect(rect, paint);

          // วาดพื้นหลังและข้อความ
          TextSpan span = TextSpan(
            text: '$tag $confidence%',
            style: TextStyle(color: Colors.white, fontSize: 12),
          );
          TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, Offset(rect.left, rect.top - 15));
        }
      }

      @override
      bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
    }
    ```

2.  **นำ `CustomPaint` ไปใช้ใน `build` method:**

    ```dart
    // ใน build method ของ _RealTimeScreenState

    @override
    Widget build(BuildContext context) {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return Center(child: CircularProgressIndicator());
      }

      return Stack(
        children: [
          // แสดงภาพจากกล้อง
          CameraPreview(_cameraController!),
          // วาด Bounding Box ทับลงไป
          if (_results.isNotEmpty)
            CustomPaint(
              painter: BoxPainter(
                results: _results,
                // ส่งขนาดของภาพจากกล้องเข้าไป
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
              ),
            ),
        ],
      );
    }
    ```

---

### **6. เทคนิคการปรับจูนประสิทธิภาพ (Performance Tuning Techniques)**

-   **เลือกขนาดโมเดลให้เหมาะสม**:
    -   **YOLOv8n (nano)**: เร็วที่สุด, แม่นยำน้อยที่สุด, เหมาะสำหรับ Real-time บนอุปกรณ์รุ่นเก่า
    -   **YOLOv8s (small)**: สมดุลที่ดีระหว่างความเร็วและความแม่นยำ
    -   **YOLOv8m/l/x**: แม่นยำสูง แต่ช้าลงตามลำดับ เหมาะสำหรับงานที่ต้องการความแม่นยำสูงสุดและรันบนอุปกรณ์ที่มีประสิทธิภาพ
-   **ใช้โมเดล Quantized (`int8`)**:
    -   โมเดลที่ผ่านการ Quantization จะมีขนาดเล็กลงและทำงานบน CPU ได้เร็วกว่า `float32` มาก แต่อาจแลกมาด้วยความแม่นยำที่ลดลงเล็กน้อย หากจะใช้ ต้องตั้งค่า `quantization: true`
-   **ปรับ `ResolutionPreset` ของกล้อง**:
    -   การใช้ความละเอียดสูง (`high`, `max`) ทำให้โมเดลต้องประมวลผลข้อมูลมากขึ้นโดยไม่จำเป็น การใช้ `medium` หรือ `low` จะเพิ่ม FPS (Frames Per Second) ได้อย่างมาก
-   **Frame Throttling (การข้ามเฟรม)**:
    -   ไม่จำเป็นต้องรัน Inference บนทุกเฟรมที่มาจากกล้อง การรันทุกๆ 2-3 เฟรมก็เพียงพอสำหรับ Real-time และช่วยลดภาระงาน, ประหยัดแบตเตอรี่, และลดความร้อนได้
    ```dart
    // ตัวอย่างการทำ Frame Throttling
    int frameCounter = 0;
    _cameraController!.startImageStream((CameraImage image) {
      frameCounter++;
      if (frameCounter % 3 == 0) { // ประมวลผลทุกๆ 3 เฟรม
        YoloService.detectObjects(image).then(...);
        frameCounter = 0;
      }
    });
    ```

---

### **7. การแก้ไขปัญหาเชิงลึก (Advanced Troubleshooting)**

-   **ปัญหา: `PlatformException` เกี่ยวกับ TFLite หรือ GPU Delegate**
    -   **สาเหตุ**: อุปกรณ์บางรุ่นอาจไม่มีไดรเวอร์ GPU ที่เข้ากันได้กับ TFLite GPU Delegate
    -   **วิธีแก้**: ลองปิดการใช้งาน GPU โดยตั้งค่า `useGpu: false` ใน `YoloService.initialize()` เพื่อบังคับให้รันบน CPU ซึ่งจะช้าลงแต่เข้ากันได้กับทุกอุปกรณ์
-   **ปัญหา: Bounding Box ไม่ตรงกับวัตถุบนหน้าจอ**
    -   **สาเหตุ**: อาจเกิดจากขนาดภาพ (`imageSize`) ที่ส่งเข้าไปใน `BoxPainter` ไม่ถูกต้อง หรือการหมุนของภาพจากกล้องไม่สอดคล้องกับการแสดงผล
    -   **วิธีแก้**: ตรวจสอบให้แน่ใจว่า `_cameraController.value.previewSize` มีค่าที่ถูกต้อง และอาจต้องสลับค่า `width` กับ `height` หากอุปกรณ์หมุนในแนวนอน
-   **ปัญหา: Memory Leak หรือแอปช้าลงเรื่อยๆ**
    -   **สาเหตุ**: ลืมเรียก `_cameraController.dispose()` หรือ `YoloService.dispose()` ใน `dispose` method ของ `StatefulWidget` ทำให้ทรัพยากรไม่ถูกคืนสู่ระบบ
    -   **วิธีแก้**: ตรวจสอบ Lifecycle ของ Widget และ Controller ทั้งหมดให้แน่ใจว่ามีการ `dispose` อย่างถูกต้องเสมอ
