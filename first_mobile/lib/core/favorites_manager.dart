import 'package:flutter/foundation.dart';
import 'package:first_mobile/model/course.dart';

class FavoritesManager {
  FavoritesManager._();

  static final ValueNotifier<List<Course>> favoritesNotifier =
      ValueNotifier<List<Course>>([]);

  static bool isFavorite(Course course) {
    return favoritesNotifier.value.any((c) => c.id == course.id);
  }

  static void toggleFavorite(Course course) {
    final list = List<Course>.from(favoritesNotifier.value);
    final index = list.indexWhere((c) => c.id == course.id);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.add(course);
    }
    favoritesNotifier.value = list;
  }
}
