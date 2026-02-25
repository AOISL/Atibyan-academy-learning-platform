import 'package:first_mobile/model/course_category.dart';
import 'package:first_mobile/model/section.dart';

class Course {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String description;
  final String createdBy;
  final String createdDate;
  final double rate;
  bool isFavorite;
  final double price;
  final CourseCategory courseCategory;
  final String duration;
  final int lessonNo;
  final List<Section> sections;

  // Optional fields
  final String? youtubeUrl;
  final String? subject;
  final List<String>? topics;

  Course({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.description,
    required this.createdBy,
    required this.createdDate,
    required this.rate,
    this.isFavorite = false,
    required this.price,
    required this.courseCategory,
    required this.duration,
    required this.lessonNo,
    required this.sections,
    this.youtubeUrl,
    this.subject,
    this.topics,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? 'Unknown',
      createdDate: json['created_date'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      courseCategory: CourseCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => CourseCategory.other,
      ),
      duration: json['duration'] as String? ?? 'Unknown',
      lessonNo: json['lesson_no'] as int? ?? 0,
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((s) => Section.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      youtubeUrl: json['youtube_url'] as String?,
      subject: json['subject'] as String?,
      topics: (json['topics'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'description': description,
      'created_by': createdBy,
      'created_date': createdDate,
      'rate': rate,
      'is_favorite': isFavorite,
      'price': price,
      'category': courseCategory.name,
      'duration': duration,
      'lesson_no': lessonNo,
      'sections': sections.map((s) => s.toJson()).toList(),
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (subject != null) 'subject': subject,
      if (topics != null) 'topics': topics,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? thumbnailUrl,
    String? description,
    String? createdBy,
    String? createdDate,
    double? rate,
    bool? isFavorite,
    double? price,
    CourseCategory? courseCategory,
    String? duration,
    int? lessonNo,
    List<Section>? sections,
    String? youtubeUrl,
    String? subject,
    List<String>? topics,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      rate: rate ?? this.rate,
      isFavorite: isFavorite ?? this.isFavorite,
      price: price ?? this.price,
      courseCategory: courseCategory ?? this.courseCategory,
      duration: duration ?? this.duration,
      lessonNo: lessonNo ?? this.lessonNo,
      sections: sections ?? this.sections,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      subject: subject ?? this.subject,
      topics: topics ?? this.topics,
    );
  }

  @override
  String toString() {
    return 'Course(id: $id, title: $title, rate: $rate, price: $price, category: ${courseCategory.name})';
  }
}
