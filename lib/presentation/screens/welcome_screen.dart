import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/presentation/screens/notifications_screen.dart';
import 'package:gms_mobile/presentation/widgets/calories_widget.dart';
import 'package:gms_mobile/presentation/widgets/stat_box.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

// ✅ Import your other screens
import 'profile_screen.dart';
import 'class_booking_screen.dart';
import 'progress_tracking_screen.dart';
import 'workout_details.dart';

const Color _blue = Color(0xFF3A86FF);
const Color _purple = Color(0xFF8338EC);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late final PageController _pageController = PageController();

  final List<String> _images = const [
    "assets/images/bodybuilding.jpeg",
    "assets/images/yoga.jpeg",
    "assets/images/powerlifting.jpeg",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSwipe();
  }

  Future<void> _startAutoSwipe() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _images.length;
      });
      _pageController.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final gradientColors = [const Color(0xFFFF0057), const Color(0xFF009DFF)];
    final theme = Theme.of(context);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // ✅ Profile icon -> ProfileScreen
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: isDarkMode ? AppColors.darkSurfaceLight : Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Welcome Yohaan",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                      child: Icon(FontAwesomeIcons.bell, color: iconColor),
                    ),
                  ],
                ),
              ),

              // --- Banner ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: size.height * 0.32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _images.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (context, index) => Image.asset(
                            _images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),

                        // ✅ Make the overlay clickable (Class Booking)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClassBookingScreen(),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.black.withOpacity(0.35),
                            alignment: Alignment.center,
                            child: const Text(
                              "Book Your Classes Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_images.length, (index) {
                              final active = index == _currentImageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: active ? 10 : 6,
                                height: active ? 10 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: active
                                      ? LinearGradient(colors: [_blue, _purple])
                                      : null,
                                  color: active ? null : Colors.white70,
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Progress Tracking Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress Tracking",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    // ✅ Arrow button -> ProgressTrackingScreen
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProgressTrackingScreen(),
                          ),
                        );
                      },
                      child: Icon(FontAwesomeIcons.chevronRight,
                          color: isDarkMode ? Colors.grey : Colors.black54, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Calories widgets
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CaloriesBarChart(gradientColors: gradientColors),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatBox(
                    label: "Steps",
                    value: "6320/10000",
                    icon: FontAwesomeIcons.shoePrints,
                    gradientColors: gradientColors,
                  ),
                  StatBox(
                    label: "Water",
                    value: "2.4/3L",
                    icon: FontAwesomeIcons.tint,
                    gradientColors: gradientColors,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- Workout Plans ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Workout Plans",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 220,
                child: PageView(
                  controller: PageController(viewportFraction: 0.9),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _WorkoutPlanCard(title: "Arm Workout", image: "assets/images/arms.jpeg"),
                    _WorkoutPlanCard(title: "Legs Workout", image: "assets/images/legs.jpeg"),
                    _WorkoutPlanCard(title: "Back Workout", image: "assets/images/back.jpeg"),
                    _WorkoutPlanCard(title: "Chest Workout", image: "assets/images/chest.jpeg"),
                    _WorkoutPlanCard(title: "Upper Body Workout", image: "assets/images/upperbody.jpeg"),
                    _WorkoutPlanCard(title: "Full Body Workout", image: "assets/images/fullbody.jpeg"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Workout Plan Card ---
class _WorkoutPlanCard extends StatelessWidget {
  final String title;
  final String image;

  const _WorkoutPlanCard({required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailsPage(title: title, image: image),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(image, fit: BoxFit.cover),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
