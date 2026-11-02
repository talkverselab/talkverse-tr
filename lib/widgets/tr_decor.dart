import 'package:flutter/material.dart';

import '../core/theme.dart';

// 일본어앱 lib/widgets/japanese_decor.dart 에서 옮긴 장식(2026-11-03) — 워드마크 글자·구분선.
// 홈 상단 메시(MeshBackdrop)는 spanish_decor.dart 에 이미 있다.

/// 지그재그 디바이더(수평 패턴) — 일본어앱 AsanohaDivider 를 이름 그대로 옮김
class AsanohaDivider extends StatelessWidget {
  final double height;
  final Color color;
  const AsanohaDivider({super.key, this.height = 16, this.color = AppColors.kin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _AsanohaPainter(color: color)),
    );
  }
}

class _AsanohaPainter extends CustomPainter {
  final Color color;
  _AsanohaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final h = size.height;
    final unit = h * 0.9;
    final path = Path()..moveTo(0, h * 0.85);
    var up = true;
    for (var x = 0.0; x <= size.width + unit; x += unit) {
      path.lineTo(x, up ? h * 0.15 : h * 0.85);
      up = !up;
    }
    canvas.drawPath(path, paint);
    // 하단 얇은 기준선
    canvas.drawLine(Offset(0, h * 0.95), Offset(size.width, h * 0.95),
        paint..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 붓 분리선 — 붓터치 느낌 그라데이션 라인
class BrushDivider extends StatelessWidget {
  final double height;
  final Color? color; // null 이면 워드마크 그라데이션(진한 청록 → 청록)
  const BrushDivider({super.key, this.height = 3, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: c == null
            ? AppColors.wordmark
            : LinearGradient(
                colors: [
                  c.withValues(alpha: 0),
                  c.withValues(alpha: 0.6),
                  c,
                  c.withValues(alpha: 0.6),
                  c.withValues(alpha: 0),
                ],
              ),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

/// 「터키어」 워드마크처럼 진한 청록 → 청록 그라데이션으로 칠한 글자(사이트 `.hero h1 .grad`).
class GradText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => AppColors.wordmark.createShader(Rect.fromLTWH(0, 0, r.width, r.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
