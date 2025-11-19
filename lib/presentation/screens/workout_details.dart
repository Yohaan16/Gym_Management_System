import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final String title;
  final String image;

  const WorkoutDetailsPage({
    super.key,
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = [const Color(0xFFFF0057), const Color(0xFF009DFF)];

    // Updated dummy exercises (5 for each workout)
    final Map<String, List<Map<String, dynamic>>> workouts = {
      "Arm Workout": [
        {"name": "Bicep Curls", "sets": 3, "reps": 15},
        {"name": "Tricep Dips", "sets": 3, "reps": 12},
        {"name": "Hammer Curls", "sets": 4, "reps": 10},
        {"name": "Overhead Tricep Extension", "sets": 3, "reps": 12},
        {"name": "Concentration Curls", "sets": 3, "reps": 10},
      ],
      "Legs Workout": [
        {"name": "Squats", "sets": 4, "reps": 12},
        {"name": "Lunges", "sets": 3, "reps": 10},
        {"name": "Leg Press", "sets": 4, "reps": 8},
        {"name": "Calf Raises", "sets": 3, "reps": 20},
        {"name": "Leg Extensions", "sets": 3, "reps": 12},
      ],
      "Chest Workout": [
        {"name": "Bench Press", "sets": 3, "reps": 10},
        {"name": "Incline Press", "sets": 3, "reps": 8},
        {"name": "Push Ups", "sets": 3, "reps": 15},
        {"name": "Chest Fly", "sets": 3, "reps": 12},
        {"name": "Decline Press", "sets": 3, "reps": 10},
      ],
      "Back Workout": [
        {"name": "Pull Ups", "sets": 3, "reps": 10},
        {"name": "Lat Pulldown", "sets": 3, "reps": 12},
        {"name": "Seated Row", "sets": 4, "reps": 10},
        {"name": "Deadlift", "sets": 3, "reps": 8},
        {"name": "Bent Over Rows", "sets": 3, "reps": 10},
      ],
      "Upper Body Workout": [
        {"name": "Shoulder Press", "sets": 3, "reps": 12},
        {"name": "Lateral Raise", "sets": 3, "reps": 15},
        {"name": "Front Raise", "sets": 3, "reps": 12},
        {"name": "Upright Row", "sets": 3, "reps": 10},
        {"name": "Arnold Press", "sets": 3, "reps": 10},
      ],
      "Full Body Workout": [
        {"name": "Burpees", "sets": 3, "reps": 10},
        {"name": "Plank", "sets": 3, "reps": 1},
        {"name": "Jumping Jacks", "sets": 3, "reps": 30},
        {"name": "Mountain Climbers", "sets": 3, "reps": 20},
        {"name": "High Knees", "sets": 3, "reps": 25},
      ],
    };

    final exercises = workouts[title] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              image,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(2), // thinner gradient border
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${exercise['name']} (${exercise['sets']}×${exercise['reps']})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(FontAwesomeIcons.dumbbell,
                            color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
