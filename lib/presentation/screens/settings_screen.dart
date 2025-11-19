import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});

@override
State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
final Color _pink = const Color(0xFFFF0057);
final Color _blue = const Color(0xFF009DFF);

bool _notificationsEnabled = true;
bool _darkThemeEnabled = false;

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,
appBar: AppBar(
leading: IconButton(
icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
onPressed: () => Navigator.pop(context),
),
title: const Text(
"Settings",
style: TextStyle(
fontWeight: FontWeight.bold,
color: Colors.black87,
),
),
backgroundColor: Colors.white,
elevation: 0,
centerTitle: true,
),
body: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
child: Column(
children: [
// -------- NOTIFICATION & THEME TOGGLES --------
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(20),
border: GradientBoxBorder(
gradient: LinearGradient(colors: [_pink, _blue]),
width: 2,
),
color: Colors.white,
boxShadow: [
BoxShadow(
color: Colors.grey.withOpacity(0.15),
blurRadius: 6,
offset: const Offset(0, 3),
)
],
),
child: Column(
children: [
_buildToggleRow(
"Notifications",
_notificationsEnabled,
(value) => setState(() => _notificationsEnabled = value),
),
const Divider(),
_buildToggleRow(
"Dark Theme",
_darkThemeEnabled,
(value) => setState(() => _darkThemeEnabled = value),
),
],
),
),

        const SizedBox(height: 30),

        // -------- INFO OPTIONS --------
        _buildOptionItem(Icons.description_outlined, "Terms & Policy"),
        _buildOptionItem(Icons.help_outline, "Help Center"),
        _buildOptionItem(Icons.info_outline, "About App"),
      ],
    ),
  ),
);

}

Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 55,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: value
                ? LinearGradient(colors: [_pink, _blue])
                : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


Widget _buildOptionItem(IconData icon, String title) {
return Container(
margin: const EdgeInsets.only(bottom: 16),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(20),
border: GradientBoxBorder(
gradient: LinearGradient(colors: [_pink, _blue]),
width: 2,
),
color: Colors.white,
boxShadow: [
BoxShadow(
color: Colors.grey.withOpacity(0.1),
blurRadius: 5,
offset: const Offset(0, 3),
)
],
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(
children: [
Icon(icon, color: Colors.black87),
const SizedBox(width: 10),
Text(title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w500,
color: Colors.black87)),
],
),
const Icon(Icons.chevron_right, color: Colors.black54),
],
),
);
}
}

// -------- GRADIENT BORDER --------
class GradientBoxBorder extends BoxBorder {
final Gradient gradient;
final double width;

const GradientBoxBorder({required this.gradient, this.width = 2});

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
    rect, borderRadius?.topLeft ?? const Radius.circular(0));
canvas.drawRRect(rrect, paint);

}

@override
ShapeBorder scale(double t) => this;

@override
EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

@override
BorderSide get top => BorderSide.none;

@override
BorderSide get bottom => BorderSide.none;

@override
bool get isUniform => true;
}
