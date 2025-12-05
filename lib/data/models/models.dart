/// Base model for API responses
abstract class BaseModel {
  /// Convert model to JSON
  Map<String, dynamic> toJson();
}

/// User model
class User implements BaseModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String dateOfBirth;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dateOfBirth,
    this.profileImage,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'profileImage': profileImage,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      gender: json['gender'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      profileImage: json['profileImage'] as String?,
    );
  }
}

/// Membership model
class Membership implements BaseModel {
  final String id;
  final String userId;
  final String membershipType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Membership({
    required this.id,
    required this.userId,
    required this.membershipType,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'membershipType': membershipType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as String,
      userId: json['userId'] as String,
      membershipType: json['membershipType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
    );
  }
}

/// Workout model
class Workout implements BaseModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime date;
  final int durationMinutes;
  final int caloriesBurned;

  Workout({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.date,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int,
      caloriesBurned: json['caloriesBurned'] as int,
    );
  }
}

/// Class booking model
class ClassBooking implements BaseModel {
  final String id;
  final String userId;
  final String className;
  final DateTime scheduledTime;
  final String instructor;
  final String level;

  ClassBooking({
    required this.id,
    required this.userId,
    required this.className,
    required this.scheduledTime,
    required this.instructor,
    required this.level,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'className': className,
      'scheduledTime': scheduledTime.toIso8601String(),
      'instructor': instructor,
      'level': level,
    };
  }

  factory ClassBooking.fromJson(Map<String, dynamic> json) {
    return ClassBooking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      className: json['className'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      instructor: json['instructor'] as String,
      level: json['level'] as String,
    );
  }
}
