# App YOLO: Real-time Object Detection with Flutter & YOLOv8

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter-based mobile application demonstrating real-time object detection using the YOLOv8 model. This project showcases the power of integrating advanced computer vision capabilities into cross-platform mobile apps.

<!-- You can add a screenshot or GIF of the app here -->
<!-- ![App Screenshot](link_to_your_screenshot.png) -->

---

## ✨ Features

This application provides the following functionalities:

-   **Real-time Object Detection**: Utilizes the device's camera to detect objects in real-time.
-   **Image-based Detection**: Allows users to pick an image from their gallery for object detection.
-   **Custom YOLOv8 Model**: Implements a custom-trained YOLOv8 model (`best_float32.tflite`).
-   **Optimized Performance**: Leverages GPU acceleration for faster inference on supported devices.
-   **Dynamic Bounding Boxes**: Renders colored bounding boxes with class labels and confidence scores over detected objects.

In addition to object detection, this project also integrates **Google ML Kit Text Recognition**, allowing for OCR (Optical Character Recognition) functionalities.

## 🛠️ Tech Stack & Libraries

-   **Framework**: [Flutter](https://flutter.dev/)
-   **Computer Vision Engine**: [TensorFlow Lite](https://www.tensorflow.org/lite)
-   **Core Vision Library**: [`flutter_vision`](https://pub.dev/packages/flutter_vision) for seamless YOLOv8 model integration.
-   **Camera & Image**:
    -   [`camera`](https://pub.dev/packages/camera) for real-time camera stream.
    -   [`image_picker`](https://pub.dev/packages/image_picker) for selecting images from the gallery.
-   **Text Recognition**: [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition) for OCR.

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

-   [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.x or higher)
-   An editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
-   A physical device or emulator for testing.

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/app_yolo.git
    cd app_yolo
    ```
    *(Replace `your-username` with your actual GitHub username)*

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Run the app:**
    ```sh
    flutter run
    ```

## ⚙️ Project Configuration

For the YOLOv8 model to function correctly, specific configurations have been made:

### Model and Assets

-   The YOLOv8 TFLite model (`best_float32.tflite`) and its corresponding labels (`labels.txt`) are located in the `assets/models/` directory.
-   These assets are registered in `pubspec.yaml` to be included in the application bundle.

### Android Configuration

To prevent the TFLite model from being compressed (which would corrupt it), the following option must be added to `android/app/build.gradle`:

```groovy
android {
    // ...
    aaptOptions {
        noCompress 'tflite'
    }
}
```

The minimum Android SDK version is set to `21`.

## 🏛️ Project Structure

The project follows a feature-driven structure to keep the codebase organized and scalable.

```
lib/
├── models/         # Data models for API results, image data, etc.
├── screens/        # UI for each screen of the application.
├── services/       # Business logic and third-party service integrations.
│   ├── api_service.dart
│   ├── camera_service.dart
│   ├── ocr_service.dart
│   └── yolo_service.dart # Core logic for YOLO model handling.
├── utils/          # Utility classes and constants.
└── widgets/        # Reusable UI components.
```

For a deep dive into the technical implementation of YOLOv8 in this project, please refer to the [**YOLO Implementation Guide**](./YOLO_IMPLEMENTATION_GUIDE.md).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.