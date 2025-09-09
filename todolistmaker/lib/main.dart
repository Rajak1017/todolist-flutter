import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ToDoListmaker/storage/storage_service.dart';

void main() {
  runApp(ToDoApp());
}

class ToDoApp extends StatefulWidget {
  const ToDoApp({super.key});

  @override
  _ToDoAppState createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ToDoListPage(
        toggleTheme: () => setState(() => isDarkMode = !isDarkMode),
      ),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ToDoListPage({super.key, required this.toggleTheme});

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final List<Map<String, dynamic>> _tasks = [];
  final List<String> categories = ["Work", "Personal", "Other"];
  final StorageService _storageService = StorageService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final loadedTasks = await _storageService.loadTasks();
    setState(() {
      _tasks.addAll(loadedTasks);
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    await _storageService.saveTasks(_tasks);
  }

  Future<void> _addTask(String title, String category, DateTime? deadline) async {
    setState(() {
      _tasks.add({
        'title': title,
        'category': category,
        'deadline': deadline,
        'isCompleted': false,
      });
    });
    await _saveTasks();
  }

  Future<void> _toggleTaskCompletion(int index) async {
    setState(() {
      _tasks[index]['isCompleted'] = !_tasks[index]['isCompleted'];
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _tasks.removeAt(index);
                });
                await _saveTasks();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
                );
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        categories: categories,
        onAddTask: _addTask,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "To-Do List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 2, 150, 46),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(
                  child: Text(
                    "No tasks yet! Add some!",
                    style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Color.fromARGB(255, 0, 2, 6)),
                  ),
                )
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.task,
                            color: task['isCompleted']
                                ? Colors.green
                                : Colors.red),
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            decoration: task['isCompleted']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          "Category: ${task['category']}\nDeadline: ${task['deadline'] != null ? DateFormat.yMMMd().format(task['deadline']) : 'None'}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: task['isCompleted'],
                              onChanged: (_) => _toggleTaskCompletion(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTask(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      backgroundColor: Colors.grey[200],
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskDialog,
        backgroundColor: const Color.fromARGB(255, 2, 150, 46),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final List<String> categories;
  final Function(String, String, DateTime?) onAddTask;

  const AddTaskDialog(
      {super.key, required this.categories, required this.onAddTask});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _taskController = TextEditingController();
  String? selectedCategory;
  DateTime? selectedDeadline;

  void _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    setState(() {
      selectedDeadline = pickedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _taskController,
            decoration: const InputDecoration(labelText: "Task Title"),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            items: widget.categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) => setState(() => selectedCategory = value),
            decoration: const InputDecoration(labelText: "Category"),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedDeadline == null
                  ? "No deadline"
                  : "Deadline: ${DateFormat.yMMMd().format(selectedDeadline!)}"),
              TextButton(
                onPressed: _pickDeadline,
                child: const Text("Pick Date"),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_taskController.text.isNotEmpty && selectedCategory != null) {
              widget.onAddTask(
                _taskController.text,
                selectedCategory!,
                selectedDeadline,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task added')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
            }
          },
          child: const Text("Add Task"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}