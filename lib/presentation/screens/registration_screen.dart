import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/payment_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';
import 'package:gms_mobile/presentation/widgets/pop_up_dialog.dart';

// Exported form widget for use in LoginScreen's PageView
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();

  bool obscurePassword = true;
  String? _selectedGender;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    _dob.dispose();
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  // ===================== REGISTRATION =====================
  Future<void> _register() async {
    if ([_name, _email, _phone, _password, _confirm, _dob, _address]
            .any((c) => c.text.isEmpty) ||
        _selectedGender == null) {
      _showError('Please fill in all fields');
      return;
    }

    if (_password.text != _confirm.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_password.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    final auth = context.read<AuthProvider>();
    final data = await auth.apiRegister(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      gender: _selectedGender!,
      dateOfBirth: _dob.text.trim(),
      address: _address.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    data != null
        ? _registrationSuccess(data)
        : _showError(auth.error ?? 'Registration failed');
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        _field(_name, 'Full Name', Icons.person, themeProvider),
        _field(_email, 'Email', Icons.email, themeProvider),
        _field(_phone, 'Phone Number', Icons.phone, themeProvider),
        _genderDropdown(themeProvider),
        _dobField(themeProvider),
        _field(_address, 'Address', Icons.home, themeProvider),
        _passwordField(_password, 'Password', themeProvider),
        _passwordField(_confirm, 'Confirm Password', themeProvider),
        _space(20),
        GradientButton(
          label: 'Sign Up',
          onPressed: _register,
        ),
      ],
    );
  }

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

  Widget _dobField(ThemeProvider themeProvider) => GestureDetector(
        onTap: _selectDate,
        child: AbsorbPointer(
          child: _field(_dob, 'Date of Birth', Icons.calendar_today, themeProvider),
        ),
      );

  Widget _genderDropdown(ThemeProvider themeProvider) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
          ],
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
          decoration: _decoration('Gender', Icons.person_outline, themeProvider),
          style: TextStyle(color: themeProvider.getTextColor()),
        ),
      );

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon,
          ThemeProvider themeProvider) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: themeProvider.getSurfaceColor(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  // ===================== PAYMENT FLOW =====================
  void _registrationSuccess(Map<String, dynamic> data) {
    showPopUpDialog(
      context,
      title: 'Registration Successful',
      message: 'Welcome ${data['name']}',
      primaryLabel: 'Pay Now',
      onPrimary: () async {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _processRegistrationPayment(data);
        }
      },
      secondaryLabel: 'Pay Later',
      onSecondary: () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _processRegistrationPayment(
      Map<String, dynamic> registrationData) async {
    try {
      final paymentProvider = context.read<PaymentProvider>();
      final themeProvider = context.read<ThemeProvider>();
      final applicationId = registrationData['application_id']?.toString() ?? '';

      if (applicationId.isEmpty || applicationId == 'null') {
        _showError('Invalid registration data. Please try signing up again.');
        return;
      }

      // Create payment intent
      final paymentData = await paymentProvider.createRegistrationPaymentIntent(
        amount: 1000.0,
        applicationId: applicationId,
      );

      if (!mounted) return;

      if (paymentData == null) {
        _showError('Failed to initialize payment: ${paymentProvider.error}');
        return;
      }

      final clientSecret = paymentData['clientSecret'];

      if (clientSecret == null || clientSecret.isEmpty) {
        _showError('Invalid payment intent. Please try again.');
        return;
      }

      // Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'GMS Fitness',
          style: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        ),
      );

      if (!mounted) return;

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful - record it
      final paymentIntentId =
          paymentData['paymentIntentId'] ?? paymentData['id'];
      final success = await paymentProvider.recordRegistrationPayment(
        applicationId: applicationId,
        paymentIntentId: paymentIntentId,
        amount: 1000.0,
      );

      if (!mounted) return;

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Payment successful! Your GMS Account will be activated shortly.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          _clearForm();
        }
      } else {
        _showError('Payment recording failed: ${paymentProvider.error}');
      }
    } on StripeException catch (e) {
      if (e.error.message?.contains('cancelled') ?? false) {
        return;
      }
      if (mounted) {
        _showError('Payment failed: ${e.error.message}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Payment error: $e');
      }
    }
  }

  // ===================== HELPERS =====================
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _clearForm() {
    _email.clear();
    _password.clear();
    _confirm.clear();
    _phone.clear();
    _dob.clear();
    _name.clear();
    _address.clear();
    _selectedGender = null;
  }

  Widget _space([double h = 16]) => SizedBox(height: h);
}

// ===================== FULL SCREEN VERSION =====================
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign Up',
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
        padding: const EdgeInsets.all(24),
        child: const RegistrationForm(),
      ),
    );
  }
}
