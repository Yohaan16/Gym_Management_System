import 'package:flutter/material.dart';

class SendReviewScreen extends StatefulWidget {
  const SendReviewScreen({super.key});

  @override
  State<SendReviewScreen> createState() => _SendReviewScreenState();
}

class _SendReviewScreenState extends State<SendReviewScreen> {
  final Color _pink = const Color(0xFFFF0057);
  final Color _blue = const Color(0xFF009DFF);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Send Review",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Topic",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_pink, _blue]),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(1.5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTopic,
                    hint: const Text("Choose a topic"),
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() => _selectedTopic = value);
                    },
                    items: _topics
                        .map((topic) => DropdownMenuItem(
                              value: topic,
                              child: Text(topic),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Your Review",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_pink, _blue]),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(1.5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _reviewController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "Write your review here...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Handle send review logic
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_pink, _blue]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      "Submit Review",
                      style: TextStyle(
                        color: Colors.white,
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
    );
  }
}
