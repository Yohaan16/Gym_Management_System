// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/notices_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<bool> _isExpanded = [];

  @override
  void initState() {
    super.initState();
    // Fetch notices when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoticesProvider>().getAllNotices();
    });
  }

  String _formatPostedDate(String postedDate) {
    try {
      final date = DateTime.parse(postedDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return postedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final noticesProvider = context.watch<NoticesProvider>();
    final gradientColors = AppColors.gradientPurpleBlue;

    // Initialize expanded state based on notices length
    if (_isExpanded.length != noticesProvider.notices.length) {
      _isExpanded = List<bool>.filled(noticesProvider.notices.length, false);
    }

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.getIconColor(),
          ),
        ),
        backgroundColor: themeProvider.getBackgroundColor(),
        elevation: 0,
        centerTitle: true,
      ),
      body: noticesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : noticesProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading notices',
                        style: TextStyle(
                          color: themeProvider.getTextColor(),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        noticesProvider.error!,
                        style: TextStyle(
                          color: themeProvider.getTextColor(isPrimary: false),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          noticesProvider.clearError();
                          noticesProvider.getAllNotices();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : noticesProvider.notices.isEmpty
                  ? Center(
                      child: Text(
                        'No notices available',
                        style: TextStyle(
                          color: themeProvider.getTextColor(isPrimary: false),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: noticesProvider.notices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notice = noticesProvider.notices[index];
                        final expanded = _isExpanded[index];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded[index] = !_isExpanded[index];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: themeProvider.getCardColor(),
                              borderRadius: BorderRadius.circular(16),
                              border: GradientBoxBorder(
                                gradient: LinearGradient(colors: gradientColors),
                                width: 1.6,
                                radius: 16,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.getIconColor().withOpacity(themeProvider.isDarkMode ? 0.3 : 0.06),
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
                                        color: themeProvider.getTextColor(isPrimary: false),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        notice['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: themeProvider.getTextColor(),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatPostedDate(notice['posted_date'] ?? ''),
                                      style: TextStyle(
                                        color: themeProvider.getTextColor(isPrimary: false),
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notice['message'] ?? 'No Message',
                                          style: TextStyle(
                                            color: themeProvider.getTextColor(isPrimary: false),
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Posted by: ${notice['staff_name'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: themeProvider.getTextColor(isPrimary: false).withOpacity(0.7),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
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
