import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/membership_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    _fetchMembershipData();
  }

  Future<void> _fetchMembershipData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    final memberId = authProvider.memberId;

    if (memberId != null) {
      await membershipProvider.getMembership(memberId);
    }
  }

  Future<void> _renewMembership() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final memberId = authProvider.memberId;
    final membershipProvider = context.read<MembershipProvider>();

    if (memberId != null) {
      final membershipType = _isYearly ? "Advanced Yearly" : "Normal Monthly";
      final amount = _isYearly ? 10000.0 : 990.0; // Amount in your currency

      try {
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Step 1: Create payment intent
        final paymentIntentData = await membershipProvider.createMembershipPaymentIntent(
          memberId: memberId,
          membershipType: membershipType,
          amount: amount,
        );

        // Dismiss loading dialog
        if (mounted) Navigator.pop(context);

        if (paymentIntentData == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create payment: ${membershipProvider.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final clientSecret = paymentIntentData['clientSecret'];
        final paymentIntentId = paymentIntentData['paymentIntentId'];

        if (clientSecret == null || paymentIntentId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment setup failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Step 2: Initialize payment sheet with Stripe
        try {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'GMS Fitness',
              style: ThemeMode.dark,
            ),
          );

          // Step 3: Present payment sheet
          await Stripe.instance.presentPaymentSheet();

          // Step 4: Confirm membership renewal after successful payment
          final success = await membershipProvider.confirmMembershipRenewal(
            memberId: memberId,
            membershipType: membershipType,
            paymentIntentId: paymentIntentId,
            amount: amount,
          );

          if (!success && membershipProvider.error != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to renew membership: ${membershipProvider.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            membershipProvider.clearError();
          } else if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Membership renewed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e is StripeException
                      ? e.error.localizedMessage ?? 'Payment failed'
                      : e.toString(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Dismiss loading dialog if still open
        if (mounted) {
          try {
            Navigator.pop(context);
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Plan data
    final String title = _isYearly ? "Advanced Plan" : "Normal Plan";
    final int price = _isYearly ? 10000 : 990;
    final List<String> features = _isYearly
        ? [
            "Everything in normal plan included",
            "Personalized training",
            "Exclusive classes",

          ]
        : [
            "Access to gym",
            "Standard classes",
            "Progress Tracking",
          ];

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        title: Text(
          "Membership",
          style: TextStyle(
              color: themeProvider.getIconColor(), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.getBackgroundColor(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------- STATUS SECTION ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryPink, AppColors.secondaryBlue]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Consumer<MembershipProvider>(
                builder: (context, membershipProvider, child) {
                  final membershipData = membershipProvider.membership ?? {};
                  final membershipType = membershipData['membership_type'] ?? 'No Active Plan';
                  
                  // Use days_remaining from backend, or calculate from end_date
                  int daysRemaining = membershipData['days_remaining'] ?? 0;
                  
                  if (daysRemaining == 0) {
                    final endDate = membershipData['end_date'];
                    if (endDate != null) {
                      try {
                        final expiry = DateTime.parse(endDate.toString());
                        daysRemaining = expiry.difference(DateTime.now()).inDays;
                        if (daysRemaining < 0) daysRemaining = 0;
                      } catch (e) {
                        daysRemaining = 0;
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Current Plan: $membershipType",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Days Remaining: $daysRemaining days",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // ---------- TOGGLE ----------
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.getSurfaceColor(),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton("Monthly", !_isYearly),
                    _buildToggleButton("Yearly", _isYearly),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- DYNAMIC PLAN CONTAINER WITH SLIDE ----------
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                        begin: _isYearly
                            ? const Offset(1.0, 0.0)
                            : const Offset(-1.0, 0.0),
                        end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeInOut));
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _buildPlanCard(
                title,
                price,
                features,
                themeProvider: themeProvider,
                key: ValueKey(_isYearly),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: () => setState(() => _isYearly = text.startsWith("Yearly")),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [AppColors.primaryPink, AppColors.secondaryBlue]) : null,
          color: isSelected ? null : themeProvider.getSurfaceColor(),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : themeProvider.getTextColor(isPrimary: false),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, int price, List<String> features,
      {Key? key, required ThemeProvider themeProvider}) {
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: themeProvider.getCardColor(),
        border: GradientBoxBorder(
          gradient: LinearGradient(colors: [AppColors.primaryPink, AppColors.secondaryBlue]),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: themeProvider.getIconColor().withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.getTextColor(),
              )),
          const SizedBox(height: 8),
          Text("Rs $price",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.getTextColor())),
          const SizedBox(height: 16),
          Column(
            children: features
                .map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("• ",
                              style: TextStyle(
                                fontSize: 14,
                                color: themeProvider.getTextColor(isPrimary: false),
                              )),
                          Flexible(
                            child: Text(f,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.getTextColor(isPrimary: false))),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Consumer<MembershipProvider>(
              builder: (context, membership, child) {
                return GradientButton(
                  label: membership.isLoading ? "Renewing..." : "Renew Now",
                  onPressed: _renewMembership,
                  isLoading: membership.isLoading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
