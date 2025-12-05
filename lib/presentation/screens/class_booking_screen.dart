import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';

class ClassBookingScreen extends StatefulWidget {
  const ClassBookingScreen({super.key});

  @override
  State<ClassBookingScreen> createState() => _ClassBookingScreenState();
}

class _ClassBookingScreenState extends State<ClassBookingScreen> {
final Color _pink = const Color(0xFFFF0057);
final Color _blue = const Color(0xFF009DFF);

int _selectedDateIndex = 0;
int _selectedTimeIndex = -1;
int _currentClassIndex = 0;

late final PageController _pageController;

final List<Map<String, String>> _classes = const [
  {"title": "BODYBUILDING", "image": "assets/images/bodybuilding.jpeg"},
  {"title": "YOGA", "image": "assets/images/yoga.jpeg"},
  {"title": "POWERLIFTING", "image": "assets/images/powerlifting.jpeg"},
];

final List<Map<String, dynamic>> _dates = const [
  {"day": "23", "label": "Wed"},
  {"day": "24", "label": "Thu"},
  {"day": "25", "label": "Fri"},
  {"day": "26", "label": "Sat"},
  {"day": "27", "label": "Sun"},
  {"day": "28", "label": "Mon"},
  {"day": "29", "label": "Tue"},
];

final List<String> _times = const [
  "06:30 - 09:00",
  "09:00 - 09:30",
  "10:30 - 11:00",
  "11:00 - 11:30",
  "13:30 - 14:00",
  "14:00 - 15:30",
  "15:30 - 17:00",
  "16:00 - 17:30",
  "18:00 - 19:30",
];

LinearGradient get _mainGradient => LinearGradient(
  colors: [_pink, _blue],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

@override
void initState() {
  super.initState();
  _pageController = PageController();
}

@override
void dispose() {
  _pageController.dispose();
  super.dispose();
}

Widget _buildDotIndicator(bool isActive) => AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  margin: const EdgeInsets.symmetric(horizontal: 4),
  width: isActive ? 10 : 6,
  height: isActive ? 10 : 6,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: isActive ? _mainGradient : null,
    color: isActive ? null : Colors.white54,
  ),
);

@override
Widget build(BuildContext context) {
  final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
  final theme = Theme.of(context);
  final size = MediaQuery.of(context).size;

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
  body: Column(
    children: [
      // ---------- HEADER WITH PAGEVIEW ----------
      SizedBox(
        height: size.height * 0.32,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _classes.length,
              onPageChanged: (index) =>
                  setState(() => _currentClassIndex = index),
              itemBuilder: (_, index) {
                final item = _classes[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Image.asset(
                        item["image"]!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        item["title"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _classes.length,
                  (i) => _buildDotIndicator(_currentClassIndex == i),
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------- WHITE CONTAINER ----------
      Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // ---------- DATE HEADER ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "December Schedule",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                      },
                      icon: Icon(
                        FontAwesomeIcons.calendarDays,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ---------- DATE SELECTOR ----------
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _dates.length,
                  itemBuilder: (_, index) {
                    final isSelected = index == _selectedDateIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDateIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: isSelected ? _mainGradient : null,
                          color: isSelected ? null : (isDarkMode ? AppColors.darkSurfaceLight : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _pink.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dates[index]['day'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDarkMode ? Colors.white : Colors.black),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              _dates[index]['label'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : (isDarkMode ? Colors.white54 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "Available Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              // ---------- TIME GRID ----------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: _times.length,
                    itemBuilder: (_, index) {
                      final isSelected = index == _selectedTimeIndex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTimeIndex = index),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? _mainGradient : null,
                            color: isSelected ? null : (isDarkMode ? AppColors.darkSurfaceLight : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _pink.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _times[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.white : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ---------- BOOK BUTTON ----------
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {},
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: _mainGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "Book Now",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

}
}
