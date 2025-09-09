import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tasksKey = 'tasks';

  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final taskStrings = tasks.map((task) => _serializeTask(task)).toList();
    await prefs.setStringList(_tasksKey, taskStrings);
  }

  Future<List<Map<String, dynamic>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskStrings = prefs.getStringList(_tasksKey) ?? [];
    return taskStrings.map((str) => _deserializeTask(str)).toList();
  }

  String _serializeTask(Map<String, dynamic> task) {
    return '${task['title']}|${task['category']}|${task['deadline']?.millisecondsSinceEpoch ?? ''}|${task['isCompleted']}';
  }

  Map<String, dynamic> _deserializeTask(String str) {
    final parts = str.split('|');
    return {
      'title': parts[0],
      'category': parts[1],
      'deadline': parts[2].isEmpty ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
      'isCompleted': parts[3] == 'true',
    };
  }
}