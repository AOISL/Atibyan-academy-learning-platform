enum CourseCategory {
  all,
  programming,
  development,
  design,
  business,
  marketing,
  finance,
  other,
}

extension CourseCategoryX on CourseCategory {
  String get title {
    switch (this) {
      case CourseCategory.all:
        return 'All';
      case CourseCategory.programming:
        return 'Programming';
      case CourseCategory.development:
        return 'Development';
      case CourseCategory.design:
        return 'Design';
      case CourseCategory.business:
        return 'Business';
      case CourseCategory.marketing:
        return 'Marketing';
      case CourseCategory.finance:
        return 'Finance';
      case CourseCategory.other:
        return 'Other';
    }
  }
}
