import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool rememberMe = false;
  bool obscurePassword = true;
  int _currentPage = 0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  late final PageController _pageController;

  final _pink = const Color(0xFFff0057);
  final _blue = const Color(0xFF009dff);

  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isDarkMode = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _switchPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ---------- MAIN UI ----------
  @override
  Widget build(BuildContext context) {
    _isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            _buildHeader(size),
            const SizedBox(height: 40),
            _buildTabs(),
            const SizedBox(height: 20),
            Expanded(child: _buildPageView()),
          ],
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader(Size size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: size.height * 0.40,
          width: double.infinity,
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
              color: _isDarkMode ? AppColors.darkBg : const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
            fit: BoxFit.contain,
            color: _isDarkMode ? Colors.white : Colors.black87,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  // ---------- TABS ----------
  Widget _buildTabs() {
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tabButton("Sign In", 0, _pink),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("|", style: TextStyle(color: textColor)),
          ),
          _tabButton("Sign Up", 1, _blue),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int page, Color color) {
    final isActive = _currentPage == page;
    return GestureDetector(
      onTap: () => _switchPage(page),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isActive ? color : (_isDarkMode ? Colors.white : Colors.black),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ---------- PAGEVIEW ----------
  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildScrollContent(_signInForm()),
        _buildScrollContent(_signUpForm()),
      ],
    );
  }

  Widget _buildScrollContent(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      );

  // ---------- SIGN IN FORM ----------
  Widget _signInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(_emailController, "Username or Email", Icons.person_outline),
        _spacer(),
        _passwordField(_passwordController, "Password"),
        _spacer(height: 12),
        _rememberForgotRow(),
        _spacer(height: 20),
        _gradientButton("Sign In", _pink, _blue, onPressed: () {}),
        _spacer(height: 20),
        const Center(
          child: Text("Sign In With Social",
              style: TextStyle(color: Colors.black54)),
        ),
        _spacer(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(FontAwesomeIcons.google, Colors.redAccent),
            const SizedBox(width: 16),
            _socialIcon(FontAwesomeIcons.facebook, Colors.blue),
            const SizedBox(width: 16),
            _socialIcon(FontAwesomeIcons.linkedin, Colors.blueAccent),
          ],
        ),
      ],
    );
  }

  // ---------- SIGN UP FORM ----------
  Widget _signUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(_emailController, "Username or Email", Icons.person_outline),
        _spacer(),
        _inputField(_phoneController, "Phone Number", Icons.phone),
        _spacer(),
        _dobField(),
        _spacer(),
        _passwordField(_passwordController, "Password"),
        _spacer(),
        _passwordField(_confirmPasswordController, "Confirm Password"),
        _spacer(height: 20),
        _gradientButton("Sign Up", _pink, _blue, onPressed: () {}),
      ],
    );
  }

  // ---------- INPUT FIELDS ----------
  Widget _inputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(icon, color: _isDarkMode ? Colors.white54 : Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isDarkMode ? AppColors.darkSurfaceLight : Colors.grey[100],
      ),
    );
  }

  Widget _dobField() {
    return TextField(
      controller: _dobController,
      readOnly: true,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: "Date of Birth",
        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(Icons.calendar_today, color: _isDarkMode ? Colors.white54 : Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isDarkMode ? AppColors.darkSurfaceLight : Colors.grey[100],
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _dobController.text =
                "${picked.day}/${picked.month}/${picked.year}";
          });
        }
      },
    );
  }

  Widget _passwordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: obscurePassword,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(Icons.lock_outline, color: _isDarkMode ? Colors.white54 : Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, 
            color: _isDarkMode ? Colors.white54 : Colors.black54),
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _isDarkMode ? AppColors.darkSurfaceLight : Colors.grey[100],
      ),
    );
  }

  // ---------- UTILITIES ----------
  Widget _rememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              activeColor: _pink,
              onChanged: (val) => setState(() => rememberMe = val!),
            ),
            Text("Remember me", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text("Forgot password?", style: TextStyle(color: _pink)),
        ),
      ],
    );
  }

  Widget _gradientButton(String text, Color start, Color end,
      {required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [start, end],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _spacer({double height = 16}) => SizedBox(height: height);
}
