// ignore_for_file: depend_on_referenced_packages

import 'package:first_mobile/main.dart';
import 'package:first_mobile/model/course.dart';
import 'package:first_mobile/data_provider/course_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'enrollment_manager.dart'; // ← Make sure this file exists
import 'video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  void _checkEnrollment() {
    setState(() {
      _isEnrolled = enrollmentManager.isEnrolled(widget.courseId);
    });
  }

  Future<void> _enroll() async {
    enrollmentManager.enroll(widget.courseId);
    setState(() => _isEnrolled = true);

    final url = 'https://wa.me/message/AMMVXT6NNVLSH1?text=I%20want%20to%20unlock%20course:%20${widget.courseTitle}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment request sent! (Pending approval)')),
      );
    }
  }

  Future<bool> _promptPassword(BuildContext context, String correctPassword) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Password to Unlock'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Password provided by director'),
            obscureText: true,
            validator: (value) => value?.isEmpty ?? true ? 'Password required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text == correctPassword);
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _openWhatsApp(BuildContext context, String courseTitle) async {
    final url = 'https://wa.me/message/AMMVXT6NNVLSH1?text=I%20want%20to%20unlock%20course:%20$courseTitle';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Course? get _localCourse {
    try {
      return CourseDataProvider.courseList.firstWhere((c) => c.id == widget.courseId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle), centerTitle: true),
      body: Column(
        children: [
          // Course description section
          FutureBuilder<Map<String, dynamic>>(
            future: supabase
                .from('courses')
                .select('description')
                .eq('id', widget.courseId)
                .single()
                .catchError((_) {
                  final course = _localCourse;
                  return {'description': course?.description ?? ''};
                }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final description = snapshot.data?['description'] as String? ?? '';
              if (description.trim().isEmpty) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                color: const Color.fromARGB(255, 18, 202, 73).withAlpha(13),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About this Course',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 14, 173, 41),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    if (_localCourse != null &&
                        _localCourse!.youtubeUrl != null &&
                        _localCourse!.youtubeUrl!.isNotEmpty)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Watch Intro Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                url: _localCourse!.youtubeUrl!,
                                title: 'Course Introduction',
                                topicId: 'intro_${widget.courseId}',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),

          // Topics list
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('topics')
                  .select('id, title, youtube_url, is_intro, order, description, password')
                  .eq('course_id', widget.courseId)
                  .order('order')
                  .catchError((_) => []),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final topics = snapshot.data ?? [];
                if (topics.isEmpty) {
                  final localCourse = _localCourse;
                  if (localCourse == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Course not found', style: TextStyle(color: Colors.red)),
                      ),
                    );
                  }
                  return _buildLocalSectionsList(context, localCourse);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final isIntro = topic['is_intro'] as bool? ?? false;
                    final password = topic['password'] as String? ?? '';
                    final isLocked = !isIntro && password.isNotEmpty;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: isLocked
                            ? const Icon(Icons.lock, color: Colors.red, size: 32)
                            : const Icon(Icons.play_circle_fill, color: Colors.green, size: 32),
                        title: Text(
                          topic['title'] ?? 'Untitled Topic',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isLocked ? Colors.grey[700] : Colors.black87,
                          ),
                        ),
                        subtitle: topic['description'] != null && topic['description'].toString().trim().isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  topic['description'].toString().length > 60
                                      ? '${topic['description'].toString().substring(0, 57)}...'
                                      : topic['description'].toString(),
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : null,
                        trailing: isLocked ? const Text('Locked', style: TextStyle(color: Colors.red)) : null,
                        onTap: () async {
                          if (!isLocked) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(
                                  url: topic['youtube_url'] ?? '',
                                  title: topic['title'] ?? 'Video',
                                  topicId: topic['id'] as String,
                                ),
                              ),
                            );
                            return;
                          }

                          final unlocked = await _promptPassword(context, password);
                          if (unlocked) {
                            enrollmentManager.approve(widget.courseId);
                            _checkEnrollment();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(
                                  url: topic['youtube_url'] ?? '',
                                  title: topic['title'] ?? 'Video',
                                  topicId: topic['id'] as String,
                                ),
                              ),
                            );
                          } else {
                            _openWhatsApp(context, widget.courseTitle);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Enroll button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isEnrolled
                ? const Text(
                    'You are already enrolled in this course',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.school),
                    label: const Text('Enroll in Course'),
                    onPressed: _enroll,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 18, 165, 25),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalSectionsList(BuildContext context, Course course) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: course.sections.length,
      itemBuilder: (context, index) {
        final section = course.sections[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.play_circle_fill, color: Colors.green, size: 32),
            title: Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                section.content.length > 60 ? '${section.content.substring(0, 57)}...' : section.content,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}