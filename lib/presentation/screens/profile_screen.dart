import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'membership_screen.dart';
import 'send_review_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
const ProfileScreen({super.key});

@override
State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

final TextEditingController _nameController =
TextEditingController(text: "Yohaan");
final TextEditingController _genderController =
TextEditingController(text: "Male");
final TextEditingController _dobController =
TextEditingController(text: "16/02/2006");
final TextEditingController _phoneController =
TextEditingController(text: "+230 58374465");
final TextEditingController _emailController =
TextEditingController(text: "yohaan@gmail.com");

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDarkMode = themeProvider.isDarkMode;
  
  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: theme.appBarTheme.foregroundColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Profile",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.appBarTheme.foregroundColor,
        ),
      ),
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      centerTitle: true,
    ),
body: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
child: Column(
children: [
const CircleAvatar(
radius: 45,
backgroundImage: AssetImage(AppConstants.imgGymHeader),
),
const SizedBox(height: 10),
Text(
_nameController.text,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: isDarkMode ? Colors.white : AppColors.textPrimary,
),
),
const SizedBox(height: 4),
Text(
_emailController.text,
style: TextStyle(color: isDarkMode ? Colors.white70 : AppColors.textLight),
),
const SizedBox(height: 20),

        // ---------- INFO CONTAINER ----------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: GradientBoxBorder(
              gradient: LinearGradient(colors: AppColors.gradientPinkPurple),
              width: 2,
            ),
            color: isDarkMode ? AppColors.darkSurface : AppColors.bgWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoField("Full Name", _nameController),
              _buildInfoField("Gender", _genderController),
              _buildInfoField("Date of Birth", _dobController),
              _buildInfoField("Phone Number", _phoneController),
              _buildInfoField("Email", _emailController),
              const SizedBox(height: 10),
              SizedBox(
                height: 45,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ).copyWith(
                    backgroundColor:
                        WidgetStateProperty.resolveWith((_) => null),
                    foregroundColor:
                        WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () {
                    setState(() => _isEditing = !_isEditing);
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.gradientPinkPurple),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        _isEditing ? "Save" : "Edit Profile",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // ---------- OPTIONS ----------
        _buildOptionItem(context, "Membership", Icons.card_membership, const MembershipScreen(), isDarkMode),
        _buildOptionItem(context, "Settings", Icons.settings, const SettingsScreen(), isDarkMode),
        _buildOptionItem(context, "Change Password", Icons.password, const ChangePasswordScreen(), isDarkMode),
        _buildOptionItem(context, "Send Review", Icons.reviews_outlined, const SendReviewScreen(), isDarkMode),
        _buildOptionItem(context, "Log Out", Icons.logout, const LoginScreen(), isDarkMode),

      ],
    ),
  ),
);

}

Widget _buildInfoField(String label, TextEditingController controller) {
return Padding(
padding: const EdgeInsets.only(bottom: 14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(label,
style: TextStyle(
fontWeight: FontWeight.w500, 
color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
const SizedBox(height: 6),
TextField(
controller: controller,
enabled: _isEditing,
decoration: InputDecoration(
filled: true,
fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceLight : Colors.grey[100],
contentPadding:
const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: BorderSide.none,
),
),
),
],
),
);
}

void _navigateWithSlide(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}

Widget _buildOptionItem(
    BuildContext context, String title, IconData icon, Widget page, bool isDarkMode) {
  return GestureDetector(
    onTap: () => _navigateWithSlide(context, page),
    child: Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    border: GradientBoxBorder(
    gradient: LinearGradient(colors: AppColors.gradientPinkPurple),
    width: 2,
    ),
    color: isDarkMode ? AppColors.darkSurface : AppColors.bgWhite,
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
    Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black87),
    const SizedBox(width: 10),
    Text(title,
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: isDarkMode ? Colors.white : Colors.black87)),
    ],
    ),
    Icon(Icons.chevron_right, color: isDarkMode ? Colors.white54 : Colors.black54),
    ],
    ),
    )
  );
}
}

// ---------- GRADIENT BORDER ----------
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
