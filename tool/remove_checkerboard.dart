import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/bike_loading.png');
  final bytes = file.readAsBytesSync();
  final image = img.decodePng(bytes)!;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // 체크무늬는 보통 (204,204,204) + (255,255,255) 또는 비슷한 밝은 회색
      // 밝은 무채색(회색~흰색) 픽셀을 투명으로 변환
      if (_isCheckerboard(r, g, b)) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  final output = img.encodePng(image);
  file.writeAsBytesSync(output);
  print('Done: removed checkerboard background (${image.width}x${image.height})');
}

bool _isCheckerboard(int r, int g, int b) {
  final maxDiff = [r - g, g - b, r - b].map((d) => d.abs()).reduce((a, b) => a > b ? a : b);
  if (maxDiff > 15) return false;

  // 체크무늬: 밝은 회색(~204) + 어두운 회색(~153) 또는 흰색(255)
  final brightness = (r + g + b) / 3;
  return brightness >= 140;
}
