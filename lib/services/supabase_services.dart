import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // Authentication
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Database CRUD
  Future<List<Task>> fetchTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((task) => Task.fromJson(task)).toList();
  }

  Future<void> addTask(String title, String courseCode, String priority) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('tasks').insert({
      'user_id': user.id,
      'title': title,
      'course_code': courseCode,
      'priority': priority,
      'is_completed': false,
    });
  }

  Future<void> toggleTaskStatus(String taskId, bool currentStatus) async {
    await _client
        .from('tasks')
        .update({'is_completed': !currentStatus})
        .eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }
}