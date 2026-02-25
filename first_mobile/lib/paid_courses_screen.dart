// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';

// Add these imports — adjust paths if your folder structure is different
import 'package:first_mobile/model/course.dart';
import 'package:first_mobile/model/course_category.dart';
import 'package:first_mobile/data_provider/course_data_provider.dart';
import 'package:first_mobile/core/favorites_manager.dart';

import 'course_detail_screen.dart';
// import 'courses_screen.dart';  // ← commented out because it doesn't exist yet

// Green palette
const Color kPaidGreen = Color(0xFF2E7D32); // main green
const Color kPaidGreenLight = Color(0xFF4CAF50);
const Color kPaidGreenAccent = Color(0xFF66BB6A);
const Color kPaidGreenVeryLight = Color(0xFF81C784);

class PaidCoursesScreen extends StatelessWidget {
  const PaidCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter only paid courses
    final paidCourses = CourseDataProvider.courseList
        .where((course) => course.price > 0)
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/aoi_logo.png',
          height: 44,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kPaidGreen,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: kPaidGreenVeryLight.withAlpha(64), // 0.25 * 255 ≈ 64
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPaidGreen.withAlpha(64), // 0.25
                    kPaidGreenVeryLight.withAlpha(31), // ≈ 0.12
                  ],
                ),
              ),
              child: Column(
                children: [
                  Image.asset('assets/imag es/aoi_logo.png', height: 120),
                  const SizedBox(height: 16),
                  Text(
                    'Premium & Paid Courses',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: kPaidGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock professional training with certificates, mentorship & lifetime access.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open, size: 20),
                    label: const Text('Browse All Paid Courses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPaidGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text('All Paid Courses'),
                            ),
                            body: const Center(
                              child: Text(
                                'Full paid courses list coming soon...\nCreate courses_screen.dart to continue',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
              child: Text(
                'Popular Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: kPaidGreen),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: CourseCategory.values
                    .where((cat) => cat != CourseCategory.all)
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: FilterChip(
                          label: Text(cat.title),
                          selected: false,
                          onSelected: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Showing premium ${cat.title} courses',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          selectedColor: kPaidGreen,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: const TextStyle(color: Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Featured section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Premium Courses',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: kPaidGreen),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text('All Paid Courses'),
                            ),
                            body: const Center(
                              child: Text(
                                'Full list coming soon...\nCreate courses_screen.dart',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: kPaidGreen),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                itemCount: paidCourses.length,
                itemBuilder: (context, index) {
                  final course = paidCourses[index];

                  return ValueListenableBuilder<List<Course>>(
                    valueListenable: FavoritesManager.favoritesNotifier,
                    builder: (context, favorites, _) {
                      final isFavorite = FavoritesManager.isFavorite(course);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                courseId: course.id, // ← fixed
                                courseTitle: course.title, // ← fixed
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.asset(
                                      'assets/images/aoi10.png',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: const Color.fromARGB(255, 67, 151, 72)
                                                  .withAlpha(64),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.school,
                                                  size: 48,
                                                  color: kPaidGreen,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '₦${course.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: kPaidGreen,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${course.lessonNo} lessons • ${course.duration}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      FavoritesManager.toggleFavorite(course),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
