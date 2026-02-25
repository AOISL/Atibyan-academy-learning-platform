import 'package:flutter/material.dart';

class EnrollmentManager extends ChangeNotifier {
  // courseId → status ('pending' or 'approved')
  final Map<String, String> _enrollments = {};

  // courseId → enrollment date
  final Map<String, DateTime> _enrollmentDates = {};

  bool isEnrolled(String courseId) => _enrollments.containsKey(courseId);

  String getStatus(String courseId) => _enrollments[courseId] ?? '';

  DateTime? getEnrollmentDate(String courseId) => _enrollmentDates[courseId];

  void enroll(String courseId) {
    if (!_enrollments.containsKey(courseId)) {
      _enrollments[courseId] = 'pending';
      _enrollmentDates[courseId] = DateTime.now();
      notifyListeners();
    }
  }

  void approve(String courseId) {
    if (_enrollments.containsKey(courseId)) {
      _enrollments[courseId] = 'approved';
      notifyListeners();
    }
  }

  void cleanExpiredPending() {
    final now = DateTime.now();
    final toRemove = <String>[];

    _enrollmentDates.forEach((courseId, date) {
      if (_enrollments[courseId] == 'pending' && now.difference(date).inDays > 3) {
        toRemove.add(courseId);
      }
    });

    for (var id in toRemove) {
      _enrollments.remove(id);
      _enrollmentDates.remove(id);
    }

    if (toRemove.isNotEmpty) notifyListeners();
  }

  List<String> getEnrolledCourseIds() => _enrollments.keys.toList();
}

// Global instance
final enrollmentManager = EnrollmentManager();