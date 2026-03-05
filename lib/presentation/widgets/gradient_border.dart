import 'package:flutter/material.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';

/// A custom BoxBorder that paints a gradient border around containers
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  final double radius;

  const GradientBoxBorder({
    required this.gradient,
    this.width = 2,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final RRect rrect = RRect.fromRectAndRadius(
        rect, borderRadius?.topLeft ?? Radius.circular(radius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  ShapeBorder scale(double t) => GradientBoxBorder(
        gradient: gradient,
        width: width * t,
        radius: radius * t,
      );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  bool get isUniform => true;
}

/// A reusable gradient box widget that creates a gradient border effect
/// with an inner container that adapts to theme (dark/light mode)
class GradientBox extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry innerPadding;

  const GradientBox({
    super.key,
    required this.child,
    this.gradientColors = AppColors.gradientBluePink,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(2),
    this.innerPadding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        padding: innerPadding,
        decoration: BoxDecoration(
          color: themeProvider.getCardColor(),
          borderRadius: BorderRadius.circular(borderRadius - 2),
        ),
        child: child,
      ),
    );
  }
}

/// A convenience widget for gradient text with the app's gradient colors
class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final List<Color> gradientColors;

  const GradientText(
    this.text, {
    super.key,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.gradientColors = AppColors.gradientBluePink,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        foreground: Paint()
          ..shader = LinearGradient(colors: gradientColors)
              .createShader(const Rect.fromLTWH(0, 0, 200, 0)),
      ),
    );
  }
}