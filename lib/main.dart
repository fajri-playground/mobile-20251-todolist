import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Model Todo
class Todo {
  final String id;
  final String title;
  final DateTime createdAt;
  bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
  });
}

// Enum untuk filter
enum TodoFilter { all, active, done }

// Provider untuk mengelola state todos
class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  TodoFilter _currentFilter = TodoFilter.all;

  List<Todo> get todos {
    List<Todo> filteredTodos;

    switch (_currentFilter) {
      case TodoFilter.active:
        filteredTodos = _todos.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.done:
        filteredTodos = _todos.where((todo) => todo.isCompleted).toList();
        break;
      case TodoFilter.all:
        filteredTodos = _todos;
        break;
    }

    // Sorting logic: Active todos first (newest first), then completed todos (newest first)
    if (_currentFilter == TodoFilter.all) {
      filteredTodos.sort((a, b) {
        // First sort by completion status (active first)
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        // Then sort by creation time (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      // For active or done filter, just sort by newest first
      filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filteredTodos;
  }

  TodoFilter get currentFilter => _currentFilter;

  int get activeTodosCount => _todos.where((todo) => !todo.isCompleted).length;

  int get completedTodosCount =>
      _todos.where((todo) => todo.isCompleted).length;

  int get totalTodosCount => _todos.length;

  void addTodo(String title) {
    if (title.trim().length >= 3) {
      final now = DateTime.now();
      _todos.add(
        Todo(
          id: now.millisecondsSinceEpoch.toString(),
          title: title.trim(),
          createdAt: now,
        ),
      );
      notifyListeners();
    }
  }

  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  void restoreTodo(Todo todo) {
    _todos.add(todo);
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
          // Counter Section - menampilkan jumlah tugas aktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _TaskCounter(
                    label: "Aktif",
                    count: todoProvider.activeTodosCount,
                    color: Colors.orange,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TaskCounter(
                    label: "Selesai",
                    count: todoProvider.completedTodosCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TaskCounter(
                    label: "Total",
                    count: todoProvider.totalTodosCount,
                    color: Colors.blue,
                    icon: Icons.list_alt,
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
                      return Dismissible(
                        key: Key(todo.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _showSwipeDeleteConfirmation(
                            context,
                            todo,
                          );
                        },
                        onDismissed: (direction) {
                          todoProvider.removeTodo(todo.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Todo "${todo.title}" berhasil dihapus',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  // Re-add the todo using the provider method
                                  todoProvider.restoreTodo(todo);
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
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
                              onChanged: (_) =>
                                  todoProvider.toggleTodo(todo.id),
                              shape: const CircleBorder(),
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
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
                            trailing: Text(
                              _formatTime(todo.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Baru saja";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}j";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}h";
    } else {
      return "${dateTime.day}/${dateTime.month}";
    }
  }

  Future<bool?> _showSwipeDeleteConfirmation(
    BuildContext context,
    Todo todo,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Hapus Todo'),
          content: Text('Yakin ingin menghapus "${todo.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
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

// Widget untuk menampilkan counter tugas
class _TaskCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _TaskCounter({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
