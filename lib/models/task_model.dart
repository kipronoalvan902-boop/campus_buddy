class Task {
  final String id;
  final String userId;
  final String title;
  final String courseCode;
  final DateTime? dueDate;
  final String priority;
  final bool isCompleted;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.courseCode,
    this.dueDate,
    required this.priority,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      courseCode: json['course_code'] ?? '',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] ?? 'Medium',
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'course_code': courseCode,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'is_completed': isCompleted,
    };
  }
}