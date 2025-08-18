import 'dart:typed_data';

class ImageData {
  final String base64;
  final Uint8List bytes;

  ImageData({required this.base64, required this.bytes});
}
