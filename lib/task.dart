class Task {
  String id;
  String name;
  bool isCompleted;
  String userId;

  Task({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.userId,
  });

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      name: map['name'],
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'userId': userId,
    };
  }
}