import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/presentation/screens/welcome_screen.dart';
import 'package:gms_mobile/presentation/screens/registration_screen.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool obscurePassword = true;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ===================== LOGIN =====================
  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.apiLogin(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showError(auth.error ?? 'Login failed');
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      body: Column(
        children: [
          _header(size, themeProvider),
          const SizedBox(height: 40),
          _tabs(themeProvider),
          const SizedBox(height: 20),
          Expanded(child: _pages(themeProvider)),
        ],
      ),
    );
  }

  Widget _header(Size size, ThemeProvider themeProvider) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: size.height * .4,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/gym_header.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: themeProvider.getBackgroundColor(),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
          Positioned(
            bottom: -75,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/GMS_logo.png',
              height: 170,
              color: themeProvider.getTextColor(),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ],
      );

  Widget _tabs(ThemeProvider themeProvider) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tab('Sign In', 0, AppColors.primaryPink, themeProvider),
          Text('|', style: TextStyle(color: themeProvider.getTextColor())),
          _tab('Sign Up', 1, AppColors.secondaryBlue, themeProvider),
        ],
      );

  Widget _tab(String text, int page, Color color, ThemeProvider themeProvider) =>
      GestureDetector(
        onTap: () => _switchPage(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight:
                  _currentPage == page ? FontWeight.bold : FontWeight.normal,
              color: _currentPage == page
                  ? color
                  : themeProvider.getTextColor(),
            ),
          ),
        ),
      );

  Widget _pages(ThemeProvider themeProvider) => PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        children: [
          _wrap(_signInForm(themeProvider)),
          _wrap(const RegistrationForm()),
        ],
      );

  Widget _wrap(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      );

  // ===================== LOGIN FORM =====================
  Widget _signInForm(ThemeProvider themeProvider) => Column(
        children: [
          _field(_email, 'Username or Email', Icons.person, themeProvider),
          _passwordField(_password, 'Password', themeProvider),
          _space(20),
          GradientButton(
            label: 'Sign In',
            onPressed: _login,
          ),
        ],
      );

  // ===================== WIDGET HELPERS =====================
  Widget _field(TextEditingController c, String label, IconData icon,
          ThemeProvider themeProvider) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          style: TextStyle(color: themeProvider.getTextColor()),
          decoration: _decoration(label, icon, themeProvider),
        ),
      );

  Widget _passwordField(TextEditingController c, String label,
          ThemeProvider themeProvider) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          obscureText: obscurePassword,
          style: TextStyle(color: themeProvider.getTextColor()),
          decoration: _decoration(label, Icons.lock, themeProvider).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
            ),
          ),
        ),
      );

  InputDecoration _decoration(String label, IconData icon,
          ThemeProvider themeProvider) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: themeProvider.getSurfaceColor(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  // ===================== HELPERS =====================
  void _switchPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _space([double h = 16]) => SizedBox(height: h);
}
