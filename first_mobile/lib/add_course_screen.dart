import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'package:first_mobile/main.dart' show supabase;

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Course fields
  String _courseTitle = '';
  String _courseSlug = '';

  // List to hold dynamic topics (you can add/remove in UI)
  final List<Map<String, dynamic>> _topics = [
    {
      'title': '',
      'youtube_url': '',
      'is_intro': true, // First one is intro by default
      'order': 1,
    },
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_topics.any((t) => t['title'].isEmpty || t['youtube_url'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All topics need title and YouTube URL')),
      );
      return;
    }

    try {
      // 1. Insert the course
      final courseResponse = await supabase
          .from('courses')
          .insert({'title': _courseTitle, 'slug': _courseSlug})
          .select('id')
          .single(); // Get the new course back

      final String courseId = courseResponse['id'] as String;

      // 2. Prepare topics with course_id
      final List<Map<String, dynamic>> topicsToInsert = _topics.map((t) {
        return {
          'course_id': courseId,
          'title': t['title'],
          'youtube_url': t['youtube_url'],
          'is_intro': t['is_intro'],
          'order': t['order'],
        };
      }).toList();

      // 3. Insert all topics at once
      await supabase.from('topics').insert(topicsToInsert);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Course "$_courseTitle" added with ${_topics.length} topics!',
          ),
        ),
      );

      Navigator.pop(context); // Back to home
    } catch (e) {
      String errorMsg = 'Error adding course: $e';
      if (e.toString().contains('duplicate key')) {
        errorMsg = 'Slug already exists! Choose a unique one.';
      } else if (e.toString().contains('new row violates row-level security')) {
        errorMsg =
            'Permission denied. Are you logged in? (RLS may block inserts)';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  void _addTopicField() {
    setState(() {
      _topics.add({
        'title': '',
        'youtube_url': '',
        'is_intro': false,
        'order': _topics.length + 1,
      });
    });
  }

  void _removeTopic(int index) {
    if (_topics.length > 1) {
      setState(() => _topics.removeAt(index));
      // Re-order remaining
      for (int i = 0; i < _topics.length; i++) {
        _topics[i]['order'] = i + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Course & Topics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course section
              Text(
                'Course Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course Title *'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                onSaved: (v) => _courseTitle = v!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Slug (unique, lowercase-no-spaces) *',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                onSaved: (v) =>
                    _courseSlug = v!.trim().toLowerCase().replaceAll(' ', '_'),
              ),
              const SizedBox(height: 24),

              // Topics section
              Text(
                'Topics (at least intro required)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ..._topics.asMap().entries.map((entry) {
                final index = entry.key;
                final topic = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: topic['title'],
                          decoration: InputDecoration(
                            labelText: 'Topic Title *',
                          ),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Required' : null,
                          onSaved: (v) => topic['title'] = v!.trim(),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: topic['youtube_url'],
                          decoration: InputDecoration(
                            labelText: 'YouTube URL * (full link)',
                          ),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Required';
                            if (!v.contains('youtube.com') &&
                                !v.contains('youtu.be')) {
                              return 'Invalid YouTube link';
                            }
                            return null;
                          },
                          onSaved: (v) => topic['youtube_url'] = v!.trim(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: topic['is_intro'],
                              onChanged: (bool? val) {
                                setState(
                                  () => topic['is_intro'] = val ?? false,
                                );
                              },
                            ),
                            const Text('This is the free Introduction'),
                          ],
                        ),
                        if (_topics.length > 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Remove',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () => _removeTopic(index),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Another Topic'),
                onPressed: _addTopicField,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text(
                    'Publish Course',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
