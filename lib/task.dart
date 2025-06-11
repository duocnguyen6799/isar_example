import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  @Id()
  late String title;
  String? description;
  bool isDone = false;
  Category? category;
  TaskTime? taskTime;
}

@embedded
class Category {
  @Id()
  late String value;
}

@embedded
class TaskTime {
  @Id()
  late int createdAt;

  late int startTime;

  late int endTime;
}
