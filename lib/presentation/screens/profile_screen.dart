import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/profile_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/qr_dialog.dart';
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
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemberDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final memberId = authProvider.memberId;

    if (memberId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Member ID not found';
        });
      }
      return;
    }

    final success = await profileProvider.getMemberProfile(memberId);

    if (!mounted) return;

    if (success) {
      final data = profileProvider.memberProfile ?? {};
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _genderController.text = data['gender'] ?? '';
        if (data['dateOfBirth'] != null) {
          try {
            final date = DateTime.parse(data['dateOfBirth']);
            _dobController.text =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (e) {
            _dobController.text = data['dateOfBirth'];
          }
        } else {
          _dobController.text = '';
        }
        _addressController.text = data['address'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = profileProvider.error;
      });
    }
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Phone validation helper (digits only)
  bool _isValidPhone(String phone) {
    return RegExp(r'^\d+$').hasMatch(phone);
  }

  Future<void> _saveMemberDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final memberId = authProvider.memberId;

    if (memberId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member ID not found')),
        );
      }
      return;
    }

    // Validation checks
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full Name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_genderController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date of Birth is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone Number is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidPhone(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone Number must contain only digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isEditing = false);

    String dateOfBirth = _dobController.text;
    if (dateOfBirth.isNotEmpty) {
      try {
        final parts = dateOfBirth.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          dateOfBirth = date.toIso8601String();
        }
      } catch (e) {
        // If parsing fails, use the original value
      }
    }

    final success = await profileProvider.updateMemberProfile(
      memberId: memberId,
      firstName: _nameController.text.split(' ').first,
      lastName: _nameController.text.split(' ').skip(1).join(' '),
      email: _emailController.text,
      phone: _phoneController.text,
      gender: _genderController.text,
      dateOfBirth: dateOfBirth,
      address: _addressController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${profileProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: themeProvider.getIconColor(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.getTextColor(),
          ),
        ),
        backgroundColor: themeProvider.getBackgroundColor(),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchMemberDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: themeProvider.isDarkMode 
                                  ? themeProvider.getSurfaceColor() 
                                  : Colors.grey.shade600,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(height: 8),

                      // QR button under profile picture
                      Builder(
                        builder: (context) {
                          return ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('Show QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            onPressed: () async {
                              final auth = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final profile = Provider.of<ProfileProvider>(
                                context,
                                listen: false,
                              );
                              final memberId = auth.memberId;
                              if (memberId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Member not available'),
                                  ),
                                );
                                return;
                              }

                              final success = await profile.getQrToken(memberId);
                              if (!success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        profile.error ?? 'Failed to get QR',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              final token = profile.qrToken;
                              if (token == null || token.isEmpty) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid QR token'),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Show dialog with QR and countdown
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => QrDialog(
                                    token: token,
                                    expiresAt: null,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 10),
                      Text(
                        _nameController.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text,
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                  // ---------- INFO CONTAINER ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: GradientBoxBorder(
                        gradient: LinearGradient(
                          colors: AppColors.gradientPinkPurple,
                        ),
                        width: 2,
                      ),
                      color: themeProvider.isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.bgWhite,
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
                        _buildInfoField(
                          "Full Name",
                          _nameController,
                          themeProvider,
                        ),
                        _buildGenderDropdown(
                          themeProvider,
                        ),
                        _buildInfoField(
                          "Date of Birth",
                          _dobController,
                          themeProvider,
                        ),
                        _buildInfoField(
                          "Phone Number",
                          _phoneController,
                          themeProvider,
                        ),
                        _buildInfoField(
                          "Email",
                          _emailController,
                          themeProvider,
                        ),
                        _buildInfoField(
                          "Address",
                          _addressController,
                          themeProvider,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 45,
                          width: double.infinity,
                          child: ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ).copyWith(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith(
                                        (_) => null,
                                      ),
                                  foregroundColor: WidgetStateProperty.all(
                                    Colors.white,
                                  ),
                                ),
                            onPressed: () {
                              if (_isEditing) {
                                _saveMemberDetails();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.gradientPinkPurple,
                                ),
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
                  _buildOptionItem(
                    context,
                    "Membership",
                    Icons.card_membership,
                    const MembershipScreen(),
                    themeProvider,
                  ),
                  _buildOptionItem(
                    context,
                    "Settings",
                    Icons.settings,
                    const SettingsScreen(),
                    themeProvider,
                  ),
                  _buildOptionItem(
                    context,
                    "Change Password",
                    Icons.password,
                    const ChangePasswordScreen(),
                    themeProvider,
                  ),
                  _buildOptionItem(
                    context,
                    "Send Review",
                    Icons.reviews_outlined,
                    const SendReviewScreen(),
                    themeProvider,
                  ),
                  _buildLogoutOption(context, themeProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: themeProvider.getTextColor(),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: _isEditing,
            decoration: InputDecoration(
              filled: true,
              fillColor: themeProvider.getSurfaceColor(),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
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

  Widget _buildGenderDropdown(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gender",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: themeProvider.getTextColor(),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: themeProvider.getSurfaceColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _genderController.text.isEmpty ? null : _genderController.text,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ]
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            e.value ?? '',
                            style: TextStyle(color: themeProvider.getTextColor()),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (_isEditing)
                    ? (value) {
                        setState(() {
                          _genderController.text = value ?? '';
                        });
                      }
                    : null,
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
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
    ThemeProvider themeProvider,
  ) {
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
          color: themeProvider.isDarkMode
              ? AppColors.darkSurface
              : AppColors.bgWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: themeProvider.getIconColor()),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.getTextColor(),
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: themeProvider.getIconColor()),
          ],
        ),
      ),
    );
  }
}

// ---------- LOGOUT OPTION ----------
Widget _buildLogoutOption(BuildContext context, ThemeProvider themeProvider) {
  return GestureDetector(
    onTap: () async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // Navigate to login screen and remove all previous routes from stack
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Remove all routes from stack
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: GradientBoxBorder(
          gradient: LinearGradient(colors: AppColors.gradientPinkPurple),
          width: 2,
        ),
        color: themeProvider.isDarkMode
            ? AppColors.darkSurface
            : AppColors.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.logout, color: themeProvider.getIconColor()),
              const SizedBox(width: 10),
              Text(
                "Log Out",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.getTextColor(),
                ),
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: themeProvider.getIconColor()),
        ],
      ),
    ),
  );
}
