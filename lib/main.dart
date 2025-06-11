import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'task.dart';
import 'dart:async';

Isar? isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  isar = Isar.open(schemas: [TaskSchema], directory: dir.path);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  late Stream<List<Task>> _taskStream;
  List<Task> _pagedTasks = [];
  int _page = 0;
  final int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _initIsar();
  }

  void _initIsar() async {
    _taskStream = isar!.tasks.where().watch().asyncMap((_) async {
      return isar!.tasks.where().findAll();
    });
    _loadPagedTasks();
  }

  Future<void> _loadPagedTasks() async {
    //TODO: check
    // 🔄 Reactive Data: subscribe to paged data (manual for demo)
    final allTasks = isar!.tasks.where().findAll();
    final start = _page * _pageSize;
    final end = (_page + 1) * _pageSize;
    setState(() {
      _pagedTasks =
          allTasks.length > start ? allTasks.sublist(start, end > allTasks.length ? allTasks.length : end) : [];
    });
  }

  Future<void> _addTask() async {
    final task = Task()
      ..category = (Category()..value = 'category-${_titleController.text}')
      ..title = _titleController.text
      ..description = _descController.text;
    await isar!.writeAsync((isar) {
      isar.tasks.put(task);
    });
    _titleController.clear();
    _descController.clear();
    _loadPagedTasks();
  }

  Future<void> _updateTask(Task task) async {
    _updateTaskV2(task);
    // await isar!.writeAsync((isar) {
    //   final t = isar.tasks.get(task.title);
    //   if (t != null) {
    //     t.description = "[Updated] ${t.description ?? ''}";
    //     isar.tasks.put(t);
    //   }
    // });
    // _loadPagedTasks();
  }

  //Using similar to mergeOptions
  Future<void> _updateTaskV2(Task task) async {
    task.description = "[Updated] ${task.description ?? ''}";
    await isar!.writeAsync((isar) {
      // isar.tasks.update.call(title: task.title, description: task.description);
      // isar.tasks.update.call(title: task.title, category: (Category()..value = 'category-${DateTime.now().millisecondsSinceEpoch}'));
      // isar.tasks.where().titleEqualTo(task.title).updateAll(description: task.description);
    });
  }

  Future<void> _batchAddTasks() async {
    final tasks = List.generate(
        3,
        (i) => Task()
          ..title = 'Batch Task ${DateTime.now().millisecondsSinceEpoch}-$i'
          ..description = 'Batch created');
    await isar!.writeAsync((isar) {
      isar.tasks.putAll(tasks);
    });
    _loadPagedTasks();
  }

  Future<void> _transactionDemo() async {
    await isar!.writeAsync((isar) {
      final t1 = Task()
        ..title = 'Txn Task 1'
        ..description = 'In transaction';
      final t2 = Task()
        ..title = 'Txn Task 2'
        ..description = 'In transaction';
      isar.tasks.putAll([t1, t2]);
    });
    _loadPagedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(width: 8),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: _batchAddTasks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Batch Add'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _transactionDemo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Transaction Demo'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _page = (_page - 1).clamp(0, 1000);
                        });
                        _loadPagedTasks();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Prev Page'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _page = _page + 1;
                        });
                        _loadPagedTasks();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Next Page'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('All Tasks (Reactive):'),
            Expanded(
              child: StreamBuilder<List<Task>>(
                stream: _taskStream,
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  return ListView.builder(
                    // shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text('${task.description ?? ''} - category: ${task.category?.value}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateTask(task),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            const Text('Paged Tasks:'),
            SizedBox(
              height: 120,
              child: ListView.builder(
                // shrinkWrap: true,
                // physics: const NeverScrollableScrollPhysics(),
                itemCount: _pagedTasks.length,
                itemBuilder: (context, index) {
                  final task = _pagedTasks[index];
                  return ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.description ?? ''),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
