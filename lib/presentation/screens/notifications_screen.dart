// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

const Color _blue = Color(0xFF3A86FF);
const Color _purple = Color(0xFF8338EC);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Workout Reminder',
      'message': 'Don’t forget your leg workout today at 6:00 PM! Warm up well and hydrate.',
      'time': '10:15 AM'
    },
    {
      'title': 'Goal Achieved!',
      'message': 'Congratulations! You hit your 10,000 steps milestone today. Keep it up!',
      'time': '9:00 AM'
    },
    {
      'title': 'Water Intake Alert',
      'message': 'You’re halfway there — drink 1.5L more to reach your goal!',
      'time': 'Yesterday'
    },
    {
      'title': 'New Class Added',
      'message': 'A new Powerlifting class has been added on Saturday at 8:00 AM.',
      'time': '2 days ago'
    },
  ];

  late final List<bool> _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = List<bool>.filled(notifications.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);
    final gradientColors = [_purple, _blue];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final expanded = _isExpanded[index];

          // Use a normal Container (not AnimatedContainer) to avoid BoxBorder.lerp issues.
          return GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded[index] = !_isExpanded[index];
              });
            },
            child: Container(
              // small visual animation for size change still comes from AnimatedCrossFade below
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: GradientBoxBorder(
                  gradient: LinearGradient(colors: gradientColors),
                  width: 1.6,
                  radius: 16,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with rotating chevron on the left
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 220),
                        turns: expanded ? 0.25 : 0.0, // 0.25 * 360 = 90deg
                        child: Icon(
                          FontAwesomeIcons.chevronRight,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          notification['title']!,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        notification['time']!,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Animated expand/collapse for message body
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10, left: 26, right: 4),
                      child: Text(
                        notification['message']!,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    crossFadeState:
                        expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// GradientBoxBorder
/// - draws a rounded gradient border by painting an RRect stroke
/// - implements required BoxBorder members and accepts optional borderRadius/shape
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  final double radius;

  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
    this.radius = 8.0,
  });

  Paint _createPaint(Rect rect) {
    return Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    BorderRadius? borderRadius,
    BoxShape shape = BoxShape.rectangle,
    TextDirection? textDirection,
  }) {
    final paint = _createPaint(rect);

    if (shape == BoxShape.circle) {
      final center = rect.center;
      final r = rect.shortestSide / 2;
      canvas.drawCircle(center, r - width / 2, paint);
      return;
    }

    final r = borderRadius ?? BorderRadius.circular(radius);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: r.topLeft,
      topRight: r.topRight,
      bottomLeft: r.bottomLeft,
      bottomRight: r.bottomRight,
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t, radius: radius * t);

  // Provide default sides (not used by our single-stroke painter)
  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  BorderSide get left => BorderSide.none;

  BorderSide get right => BorderSide.none;

  @override
  bool get isUniform => true;
}
