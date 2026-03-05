import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.getIconColor(),
          ),
        ),
        backgroundColor: themeProvider.getBackgroundColor(),
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
                  gradient: LinearGradient(colors: AppColors.gradientPinkPurple),
                  width: 2,
                ),
                color: themeProvider.getCardColor(),
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
                    themeProvider,
                  ),
                  const Divider(),
                  _buildToggleRow(
                    "Dark Theme",
                    isDarkMode,
                    (value) => themeProvider.toggleTheme(),
                    themeProvider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // -------- INFO OPTIONS --------
            _buildOptionItem(Icons.description_outlined, "Terms & Policy", themeProvider),
            _buildOptionItem(Icons.help_outline, "Help Center", themeProvider),
            _buildOptionItem(Icons.info_outline, "About App", themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeProvider themeProvider,
  ) {
    final isDarkMode = themeProvider.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: themeProvider.getTextColor(),
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
                  ? LinearGradient(colors: AppColors.gradientPinkPurple)
                  : LinearGradient(
                      colors: [
                        Colors.grey[isDarkMode ? 600 : 300]!,
                        Colors.grey[isDarkMode ? 700 : 400]!
                      ],
                    ),
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

  Widget _buildOptionItem(IconData icon, String title, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: GradientBoxBorder(
          gradient: LinearGradient(colors: AppColors.gradientPinkPurple),
          width: 2,
        ),
        color: themeProvider.getCardColor(),
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
              Icon(
                icon,
                color: themeProvider.getTextColor(isPrimary: false),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.getTextColor(isPrimary: false),
                ),
              ),
            ],
          ),
          Icon(
            Icons.chevron_right,
            color: themeProvider.getTextColor(isPrimary: false),
          ),
        ],
      ),
    );
  }
}
