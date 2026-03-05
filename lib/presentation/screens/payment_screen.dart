import 'package:gms_mobile/presentation/widgets/pop_up_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gms_mobile/core/providers/payment_provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PaymentScreen({super.key, required this.userData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _paymentIntentId;

  @override
  void initState() {
    super.initState();
    _initializePaymentSheet();
  }

  Future<void> _initializePaymentSheet() async {
    try {
      setState(() => _isLoading = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      // Check if this is a registration payment (applicant) or membership payment (member)
      final isApplicant = widget.userData.containsKey('application_id');
      
      Map<String, dynamic>? paymentData;
      
      if (isApplicant) {
        // Registration payment for new applicants
        paymentData = await paymentProvider.createRegistrationPaymentIntent(
          amount: 1000.0,
          applicationId: widget.userData['application_id'].toString(),
        );
      } else {
        // Class booking payment for existing members
        paymentData = await paymentProvider.createClassBookingPaymentIntent(
          memberId: authProvider.memberId ?? 1,
          classId: 1,
          amount: 1000.0,
        );
      }

      if (paymentData != null) {
        _paymentIntentId = paymentData['paymentIntentId'] ?? paymentData['id'];

        // Initialize Stripe payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentData['clientSecret'],
            merchantDisplayName: 'GMS Fitness',
            style: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          ),
        );
      } else {
        _showError('Failed to initialize payment: ${paymentProvider.error}');
      }
    } catch (e) {
      _showError('Payment initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processPayment() async {
    try {
      setState(() => _isLoading = true);

      // Get providers before async operation to avoid BuildContext issues
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful - record payment on backend
      if (_paymentIntentId != null) {
        // Check if this is a registration payment (applicant) or membership payment (member)
        final isApplicant = widget.userData.containsKey('application_id');
        
        bool success = false;
        if (isApplicant) {
          // Record payment for new applicants
          success = await paymentProvider.recordRegistrationPayment(
            applicationId: widget.userData['application_id'].toString(),
            paymentIntentId: _paymentIntentId!,
            amount: 1000.0,
          );
        } else {
          // Record payment for existing members
          success = await paymentProvider.recordBookingPayment(
            memberId: authProvider.memberId ?? 1,
            classId: 1,
            paymentIntentId: _paymentIntentId!,
            amount: 1000.0,
          );
        }

        if (success) {
          if (mounted) {
            // Show activation message dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Payment Successful!'),
                content: const Text(
                  'Your GMS Account will be activated shortly. '
                  'Please check your email for activation details.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Navigate to login screen
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppConstants.routeLogin,
                        (route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            _showError('Payment recorded but failed to save: ${paymentProvider.error}');
          }
        }
      }
    } catch (e) {
      if (e is StripeException) {
        _showError('Payment failed: ${e.error.localizedMessage}');
      } else {
        _showError('Payment error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _payWithCash() {
    showPopUpDialog(
      context,
      title: 'Pay Later',
      message: 'Please visit the gym reception to complete your payment of Rs 1000.00. Bring your registration confirmation or mention your email address.',
      primaryLabel: 'OK',
      onPrimary: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppConstants.routeLogin,
          (route) => false,
        );
      },
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Complete Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.getIconColor(),
          ),
        ),
        backgroundColor: themeProvider.getBackgroundColor(),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            const SizedBox(height: 40),
            Icon(
              Icons.payment,
              size: 80,
              color: Color(0xFFFF0057),
            ),
            const SizedBox(height: 20),
            Text(
              'Complete Your Registration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.getTextColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome ${widget.userData['name'] ?? 'User'}! To activate your membership, please complete the payment of Rs 1000.00.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.getTextColor(isPrimary: false),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFFF0057),
                  width: 2,
                ),
                color: themeProvider.getCardColor(),
              ),
              child: Column(
                children: [
                  Text(
                    'Membership Fee',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.getTextColor(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs 1000',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF0057),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'One-time registration fee',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((_) => null),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFF0057), Color(0xFF8338EC)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Pay with Card (Rs 1000)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _payWithCash,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFFF0057)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Pay with Cash',
                        style: TextStyle(
                          color: Color(0xFFFF0057),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        ),
      ),
    );
  }
}