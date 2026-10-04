import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Keep the original proportions and pin the sprite's feet to its placement box.
Rect fitSprite(Rect source, Rect box) {
  final scale = math.min(box.width / source.width, box.height / source.height);
  final width = source.width * scale, height = source.height * scale;
  return Rect.fromLTWH(box.center.dx - width / 2, box.bottom - height, width, height);
}

/// Read alpha only. Atlas files stay intact; transparent padding is not geometry.
Rect spriteInkBounds(ByteData rgba, int width, int height, Rect cell) {
  final left = cell.left.ceil().clamp(0, width - 1);
  final top = cell.top.ceil().clamp(0, height - 1);
  final right = cell.right.floor().clamp(left + 1, width);
  final bottom = cell.bottom.floor().clamp(top + 1, height);
  final columns = List<int>.filled(right - left, 0);
  final rows = List<int>.filled(bottom - top, 0);
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      if (rgba.getUint8((y * width + x) * 4 + 3) >= 180) {
        columns[x - left]++; rows[y - top]++;
      }
    }
  }
  final minColumn = math.max(1, ((bottom - top) * .025).ceil());
  final minRow = math.max(1, ((right - left) * .025).ceil());
  final x0 = columns.indexWhere((n) => n >= minColumn);
  final x1 = columns.lastIndexWhere((n) => n >= minColumn);
  final y0 = rows.indexWhere((n) => n >= minRow);
  final y1 = rows.lastIndexWhere((n) => n >= minRow);
  if (x0 < 0 || y0 < 0) return cell;
  return Rect.fromLTRB((left + x0 - 2).clamp(left, right).toDouble(),
    (top + y0 - 2).clamp(top, bottom).toDouble(),
    (left + x1 + 3).clamp(left, right).toDouble(),
    (top + y1 + 3).clamp(top, bottom).toDouble());
}

/// Breathing, blink and tail gestures have different periods; no direction frames.
int catIdleFrame(double seconds) {
  final blink = seconds % 7.3;
  if (blink >= 5.8 && blink < 5.96) return 3;
  if (blink >= 5.96 && blink < 6.12) return 4;
  if (blink >= 6.12 && blink < 6.28) return 3;
  final tail = seconds % 10.7;
  if (tail >= 2.5 && tail < 4.3) {
    const swish = [5, 6, 7, 6, 5, 0];
    return swish[((tail - 2.5) / .3).floor().clamp(0, 5)];
  }
  const breath = [0, 1, 2, 1];
  return breath[(seconds / .8).floor() % breath.length];
}
