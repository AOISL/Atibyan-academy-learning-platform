import 'package:first_mobile/main.dart';
import 'package:flutter/material.dart';

import 'course_detail_screen.dart';
import 'enrollment_manager.dart'; // ← new import
import 'login_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for enrollment changes
    enrollmentManager.addListener(_onEnrollmentChanged);
  }

  @override
  void dispose() {
    enrollmentManager.removeListener(_onEnrollmentChanged);
    super.dispose();
  }

  void _onEnrollmentChanged() {
    if (mounted) setState(() {});
  }

  Future<List<Map<String, dynamic>>> _fetchEnrolledCourses() async {
    enrollmentManager.cleanExpiredPending();

    final enrolledIds = enrollmentManager.getEnrolledCourseIds();
    if (enrolledIds.isEmpty) return [];

    try {
      final courses = await supabase
          .from('courses')
          .select('id, title, thumbnail, description, price')
          .inFilter('id', enrolledIds);

      final result = <Map<String, dynamic>>[];

      for (var course in courses) {
        final courseId = course['id'] as String;
        final status = enrollmentManager.getStatus(courseId) ?? 'pending';
        final createdAt = enrollmentManager.getEnrollmentDate(courseId) ?? DateTime.now();

        course['status'] = status;
        course['enrollment_created_at'] = createdAt;
        result.add(course);
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching course details: $e');
      return [];
    }
  }

  bool get isLoggedIn => supabase.auth.currentUser != null;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Login to view your courses', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => setState(() {}));
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Courses'), centerTitle: true),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchEnrolledCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No enrolled courses yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enroll in a course from the home page'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final status = course['status'] as String;
                final createdAt = course['enrollment_created_at'] as DateTime;
                final daysPassed = DateTime.now().difference(createdAt).inDays;
                final isPending = status == 'pending';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: course['thumbnail'] != null && course['thumbnail'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              course['thumbnail'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, size: 60),
                            ),
                          )
                        : const Icon(Icons.school, size: 60, color: Colors.blueGrey),
                    title: Text(
                      course['title'] ?? 'Untitled Course',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPending ? 'Pending Approval' : 'Approved',
                            style: TextStyle(color: isPending ? Colors.orange[900] : Colors.green[900], fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isPending)
                          Text(
                            'Waiting for approval (${3 - daysPassed} days left)',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                      ],
                    ),
                    trailing: isPending
                        ? const Icon(Icons.hourglass_empty, color: Colors.orange)
                        : const Icon(Icons.check_circle, color: Colors.green),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            courseId: course['id'],
                            courseTitle: course['title'] ?? 'Course',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}