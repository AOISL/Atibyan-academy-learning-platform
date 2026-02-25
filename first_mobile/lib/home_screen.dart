import 'package:carousel_slider/carousel_slider.dart';
import 'package:first_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'course_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Fetch all courses
  Future<List<Map<String, dynamic>>> _fetchCourses() async {
    final response = await supabase
        .from('courses')
        .select('*')
        .order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch latest blog posts – now including thumbnail
  Future<List<Map<String, dynamic>>> _fetchLatestBlogs() async {
    final response = await supabase
        .from('blog_posts')
        .select('id, title, link, description, created_at, thumbnail')
        .order('created_at', ascending: false)
        .limit(3);

    return List<Map<String, dynamic>>.from(response);
  }

  bool get isLoggedIn => supabase.auth.currentUser != null;

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  String _formatPrice(String? price) {
    if (price == null || price.trim().isEmpty) return 'TBA';
    final cleaned = price.trim();
    if (cleaned == '0' || cleaned == '0.0') return 'Free';
    return cleaned;
  }

  bool _isFree(String? price) {
    if (price == null || price.trim().isEmpty) return false;
    final cleaned = price.trim();
    return cleaned == '0' || cleaned == '0.0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Atibyan Tech Academy"),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await supabase.auth.signOut();
                setState(() {});
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => setState(() {}));
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────────────────────────────────────────────────
              //  Updated Blog Carousel – Image right, text left
              // ───────────────────────────────────────────────────────
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchLatestBlogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final blogs = snapshot.data ?? [];
                  if (blogs.isEmpty) return const SizedBox.shrink();

                  return CarouselSlider.builder(
                    itemCount: blogs.length,
                    itemBuilder: (context, index, realIndex) {
                      final blog = blogs[index];
                      final desc = blog['description'] as String? ?? '';
                      final snippet = desc.length > 120 ? "${desc.substring(0, 120)}..." : desc;
                      final thumbnail = blog['thumbnail'] as String?;

                      return GestureDetector(
                        onTap: () => _openLink(blog['link'] ?? ''),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[900],
                          ),
                          child: Row(
                            children: [
                              // Left side - Text
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        blog['title'] ?? 'Untitled Post',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        snippet,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Read more →',
                                        style: TextStyle(
                                          color: Colors.blue[300],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Right side - Image (full height)
                              if (thumbnail != null && thumbnail.trim().isNotEmpty)
                                Expanded(
                                  flex: 4,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      thumbnail.trim(),
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: Icon(Icons.broken_image, color: Colors.white54),
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[850],
                                          child: const Center(child: CircularProgressIndicator(color: Colors.white70)),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 260,                // increased height for better layout
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 6),
                      enlargeCenterPage: true,
                      viewportFraction: 0.92,
                      enableInfiniteScroll: true,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Courses title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Available Courses",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              // Courses list (unchanged)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCourses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Error loading courses:\n${snapshot.error}"),
                      ),
                    );
                  }

                  final courses = snapshot.data ?? [];

                  if (courses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          "No courses available yet",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: courses.map((course) {
                        final thumbnail = course['thumbnail'] as String?;
                        final description = course['description'] as String?;
                        final price = course['price']?.toString();

                        // Keep your debug prints if you still want them
                        // print('Course: ${course['title']} | thumbnail: $thumbnail | price: $price');

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: thumbnail != null && thumbnail.trim().isNotEmpty
                                      ? Image.network(
                                          thumbnail.trim(),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, _, _) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                          ),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(child: CircularProgressIndicator()),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course['title']?.toString() ?? 'Untitled Course',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        description?.trim() ?? "No description available",
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _isFree(price) ? Colors.green[100] : Colors.blue[50],
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              _formatPrice(price),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: _isFree(price) ? Colors.green[800] : Colors.blue[900],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}