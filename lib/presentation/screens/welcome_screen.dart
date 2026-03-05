import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/presentation/widgets/calories_widget.dart';
import 'package:gms_mobile/presentation/widgets/image_slider_widget.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/presentation/routes/app_routes.dart';
import 'package:gms_mobile/core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<String> _images = const [
    "assets/images/bodybuilding.jpeg",
    "assets/images/yoga.jpeg",
    "assets/images/powerlifting.jpeg",
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeProvider = context.watch<ThemeProvider>();
    final gradientColors = AppColors.gradientBluePink;
    final textColor = themeProvider.getTextColor();
    final iconColor = themeProvider.getIconColor();

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
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
                            AppRoutes.navigateTo(context, AppConstants.routeProfile);
                          },
                          child: CircleAvatar(
                              radius: 22,
                              backgroundColor: themeProvider.isDarkMode 
                                  ? themeProvider.getSurfaceColor() 
                                  : Colors.grey.shade600,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                        ),
                      ],
                    ),
                    GestureDetector(
                          onTap: () {
                            AppRoutes.navigateTo(context, AppConstants.routeNotifications);
                          },
                      child: Icon(FontAwesomeIcons.bell, color: iconColor),
                    ),
                  ],
                ),
              ),

              // --- Banner ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ImageSliderWidget(
                  items: _images.map((image) => {"image": image}).toList(),
                  autoSlide: true,
                  height: size.height * 0.32,
                  borderRadius: BorderRadius.circular(20),
                  activeDotGradient: LinearGradient(colors: AppColors.gradientPurpleBlue),
                  inactiveDotColor: Colors.white70,
                  staticOverlayWidget: GestureDetector(
                    onTap: () {
                      AppRoutes.navigateTo(context, AppConstants.routeClassBooking);
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
                        AppRoutes.navigateTo(context, AppConstants.routeProgressTracking);
                      },
                        child: Icon(FontAwesomeIcons.chevronRight,
                          color: themeProvider.getTextColor(isPrimary: false), size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Calories widgets
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CaloriesWidget(gradientColors: gradientColors),
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
                      color: themeProvider.getTextColor(),
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
        AppRoutes.navigateTo(
          context, 
          AppConstants.routeWorkoutDetails,
          arguments: {'title': title, 'image': image},
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
