import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EnrollmentManager extends ChangeNotifier {
  // In-memory cache
  Map<String, String> _enrollments = {};
  Map<String, DateTime> _enrollmentDates = {};

  // SharedPreferences keys
  static const String _statusKey = 'enrolled_courses_status';
  static const String _datesKey = 'enrolled_courses_dates';

  EnrollmentManager() {
    _loadFromStorage();
  }

  // Load saved data when manager is created
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load enrollment statuses
    final statusJson = prefs.getString(_statusKey);
    if (statusJson != null) {
      try {
        final decoded = jsonDecode(statusJson) as Map<String, dynamic>;
        _enrollments = decoded.map((key, value) => MapEntry(key, value as String));
      } catch (e) {
        debugPrint('Error loading enrollment statuses: $e');
      }
    }

    // Load enrollment dates
    final datesJson = prefs.getString(_datesKey);
    if (datesJson != null) {
      try {
        final decoded = jsonDecode(datesJson) as Map<String, dynamic>;
        _enrollmentDates = decoded.map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        );
      } catch (e) {
        debugPrint('Error loading enrollment dates: $e');
      }
    }

    notifyListeners();
  }

  // Save current data to persistent storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_statusKey, jsonEncode(_enrollments));
    await prefs.setString(
      _datesKey,
      jsonEncode(
        _enrollmentDates.map((key, value) => MapEntry(key, value.toIso8601String())),
      ),
    );
  }

  bool isEnrolled(String courseId) => _enrollments.containsKey(courseId);

  String getStatus(String courseId) => _enrollments[courseId] ?? '';

  DateTime? getEnrollmentDate(String courseId) => _enrollmentDates[courseId];

  Future<void> enroll(String courseId) async {
    if (!_enrollments.containsKey(courseId)) {
      _enrollments[courseId] = 'pending';
      _enrollmentDates[courseId] = DateTime.now();
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> approve(String courseId) async {
    if (_enrollments.containsKey(courseId)) {
      _enrollments[courseId] = 'approved';
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> cleanExpiredPending() async {
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

    if (toRemove.isNotEmpty) {
      await _saveToStorage();
      notifyListeners();
    }
  }

  List<String> getEnrolledCourseIds() => _enrollments.keys.toList();

  // Optional: clear all data (for logout or testing)
  Future<void> clearAll() async {
    _enrollments.clear();
    _enrollmentDates.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusKey);
    await prefs.remove(_datesKey);
    notifyListeners();
  }
}

// Global singleton instance
final enrollmentManager = EnrollmentManager();