import 'package:flutter/material.dart';
import 'package:first_mobile/model/course.dart';

// Placeholder course card widget — paste your UI here.
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset(
          course.thumbnailUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
        title: Text(course.title),
        subtitle: Text('₦${course.price.toStringAsFixed(0)}'),
        onTap: onTap,
      ),
    );
  }
}
