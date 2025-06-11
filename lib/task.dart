import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  @Id()
  late String title;
  String? description;
  bool isDone = false;
}
