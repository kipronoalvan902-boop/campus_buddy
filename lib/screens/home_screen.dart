import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/supabase_services.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _supabaseService.fetchTasks();
    });
  }

  void _showAddTaskModal(BuildContext context) {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    String selectedPriority = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        key: const Key('addTaskBottomSheet'),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Assignment / Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course Code (e.g. CCS311)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High']
                    .map((priority) => DropdownMenuItem(
                  value: priority,
                  child: Text(priority),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedPriority = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  await _supabaseService.addTask(
                    titleController.text.trim(),
                    courseController.text.trim(),
                    selectedPriority,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshTasks();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Task', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusBuddy Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading tasks: ${snapshot.error}'),
            );
          }

          final tasks = snapshot.data ?? [];
          final completedCount = tasks.where((t) => t.isCompleted).length;
          final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

          return Column(
            children: [
              // Progress Card Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress, minHeight: 8),
                    const SizedBox(height: 12),
                    Text(
                      '$completedCount of ${tasks.length} tasks completed',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              // Task List
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                  child: Text('No tasks yet. Tap + to add one!'),
                )
                    : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (bool? value) async {
                            await _supabaseService.toggleTaskStatus(
                                task.id, task.isCompleted);
                            _refreshTasks();
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${task.courseCode} • Priority: ${task.priority}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            await _supabaseService.deleteTask(task.id);
                            _refreshTasks();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}