import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Model Todo
class Todo {
  final String id;
  final String title;
  bool isCompleted;

  Todo({required this.id, required this.title, this.isCompleted = false});
}

// Enum untuk filter
enum TodoFilter { all, active, done }

// Provider untuk mengelola state todos
class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  TodoFilter _currentFilter = TodoFilter.all;

  List<Todo> get todos {
    switch (_currentFilter) {
      case TodoFilter.active:
        return _todos.where((todo) => !todo.isCompleted).toList();
      case TodoFilter.done:
        return _todos.where((todo) => todo.isCompleted).toList();
      case TodoFilter.all:
        return _todos;
    }
  }

  TodoFilter get currentFilter => _currentFilter;

  void addTodo(String title) {
    if (title.trim().length >= 3) {
      _todos.add(
        Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.trim(),
        ),
      );
      notifyListeners();
    }
  }

  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  void toggleTodo(String id) {
    final todoIndex = _todos.indexWhere((todo) => todo.id == id);
    if (todoIndex != -1) {
      _todos[todoIndex].isCompleted = !_todos[todoIndex].isCompleted;
      notifyListeners();
    }
  }

  void setFilter(TodoFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F9FF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
        ),
        home: const TodoPage(),
      ),
    );
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Todo List")),
      body: Column(
        children: [
          const _AddTodoSection(),
          // Filter Chips Section - lebih mobile friendly
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  "Filter: ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          text: "All",
                          filter: TodoFilter.all,
                          isSelected:
                              todoProvider.currentFilter == TodoFilter.all,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          text: "Active",
                          filter: TodoFilter.active,
                          isSelected:
                              todoProvider.currentFilter == TodoFilter.active,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          text: "Done",
                          filter: TodoFilter.done,
                          isSelected:
                              todoProvider.currentFilter == TodoFilter.done,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: todoProvider.todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(todoProvider.currentFilter),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: todoProvider.todos.length,
                    itemBuilder: (context, index) {
                      final todo = todoProvider.todos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Checkbox(
                            value: todo.isCompleted,
                            onChanged: (_) => todoProvider.toggleTodo(todo.id),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.isCompleted ? Colors.grey : null,
                              fontSize: 16,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _showDeleteConfirmation(
                              context,
                              todo,
                              todoProvider,
                            ),
                            splashRadius: 24,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.active:
        return "Tidak ada tugas aktif 🎉\nSemua tugas sudah selesai!";
      case TodoFilter.done:
        return "Belum ada tugas yang selesai 📝\nYuk mulai menyelesaikan tugas!";
      case TodoFilter.all:
        return "Belum ada todo 😊\nTambahkan tugas pertama Anda!";
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Todo todo,
    TodoProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Hapus Todo'),
          content: Text('Apakah Anda yakin ingin menghapus "${todo.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.removeTodo(todo.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Todo berhasil dihapus'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

// Widget untuk section menambah todo dengan validasi
class _AddTodoSection extends StatefulWidget {
  const _AddTodoSection();

  @override
  State<_AddTodoSection> createState() => __AddTodoSectionState();
}

class __AddTodoSectionState extends State<_AddTodoSection> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _addTodo() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final title = _controller.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorText = "Todo tidak boleh kosong";
      });
      return;
    }

    if (title.length < 3) {
      setState(() {
        _errorText = "Todo minimal 3 karakter";
      });
      return;
    }

    todoProvider.addTodo(title);
    _controller.clear();
    setState(() {
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Tambah todo baru...",
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              onSubmitted: (_) => _addTodo(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _addTodo,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Tambah"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Widget untuk filter chip yang lebih mobile-friendly
class _FilterChip extends StatelessWidget {
  final String text;
  final TodoFilter filter;
  final bool isSelected;

  const _FilterChip({
    required this.text,
    required this.filter,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (_) => todoProvider.setFilter(filter),
      selectedColor: colorScheme.primary.withOpacity(0.2),
      checkmarkColor: colorScheme.primary,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
    );
  }
}
