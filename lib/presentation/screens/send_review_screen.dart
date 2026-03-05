import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/review_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_border.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class SendReviewScreen extends StatefulWidget {
  const SendReviewScreen({super.key});

  @override
  State<SendReviewScreen> createState() => _SendReviewScreenState();
}

class _SendReviewScreenState extends State<SendReviewScreen> {
  final List<String> _topics = [
    "Equipment",
    "Facilities",
    "Trainers",
    "Cleanliness",
    "Pricing",
    "Other"
  ];

  String? _selectedTopic;
  final TextEditingController _reviewController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitReview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final memberId = authProvider.memberId;

    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reviewTitle = _selectedTopic;
    final message = _reviewController.text.trim();

    // Validation
    if (reviewTitle == null || reviewTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a topic'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review must be at least 10 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await reviewProvider.submitReview(
        memberId: memberId,
        reviewTitle: reviewTitle,
        message: message,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _reviewController.clear();
          _selectedTopic = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reviewProvider.error ?? 'Failed to submit review'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Send Review",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.getIconColor(),
          ),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.getBackgroundColor(),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Topic",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: themeProvider.getTextColor(),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GradientBox(
              padding: const EdgeInsets.all(1.5),
              innerPadding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTopic,
                  hint: Text("Choose a topic", style: TextStyle(color: themeProvider.getTextColor(isPrimary: false))),
                  icon: Icon(Icons.arrow_drop_down, color: themeProvider.getTextColor(isPrimary: false)),
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedTopic = value);
                  },
                  items: _topics
                      .map((topic) => DropdownMenuItem(
                            value: topic,
                            child: Text(topic, style: TextStyle(color: themeProvider.getTextColor())),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "Your Review",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: themeProvider.getTextColor(),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GradientBox(
              padding: const EdgeInsets.all(1.5),
              innerPadding: const EdgeInsets.all(14),
              child: TextField(
                controller: _reviewController,
                maxLines: 6,
                style: TextStyle(color: themeProvider.getTextColor()),
                decoration: InputDecoration(
                  hintText: "Write your review here...",
                  hintStyle: TextStyle(color: themeProvider.getTextColor(isPrimary: false)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Spacer(),
            GradientButton(
              label: "Submit Review",
              onPressed: _submitReview,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
