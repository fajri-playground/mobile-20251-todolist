import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Model data untuk Todo item
/// Ini adalah struktur data yang menyimpan informasi setiap todo
class Todo {
  final String id; // ID unik untuk setiap todo
  final String title; // Judul/isi todo
  final DateTime createdAt; // Kapan todo dibuat
  bool isCompleted; // Status apakah sudah selesai atau belum

  Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false, // Default: belum selesai
  });
}

/// Enum untuk filter status todos
/// Ini menentukan jenis filter yang bisa dipilih user
enum TodoFilter {
  all, // Tampilkan semua todo
  active, // Hanya todo yang belum selesai
  done, // Hanya todo yang sudah selesai
}

/// Provider untuk state management todos menggunakan ChangeNotifier
/// Ini adalah "otak" aplikasi yang mengatur semua data dan logika
class TodoProvider extends ChangeNotifier {
  final List<Todo> _todos = []; // List private untuk menyimpan semua todo
  TodoFilter _currentFilter = TodoFilter.all; // Filter yang sedang aktif

  /// Getter todos yang sudah difilter dan diurutkan
  /// Mengembalikan list todo sesuai filter yang dipilih
  List<Todo> get todos {
    List<Todo> filteredTodos;

    // Filter berdasarkan status yang dipilih user
    switch (_currentFilter) {
      case TodoFilter.active:
        // Hanya ambil todo yang belum selesai
        filteredTodos = _todos.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.done:
        // Hanya ambil todo yang sudah selesai
        filteredTodos = _todos.where((todo) => todo.isCompleted).toList();
        break;
      case TodoFilter.all:
        // Ambil semua todo
        filteredTodos = _todos;
        break;
    }

    // Sorting: Urutkan todo agar yang aktif muncul di atas
    if (_currentFilter == TodoFilter.all) {
      filteredTodos.sort((a, b) {
        // Urutkan berdasarkan status completion (aktif dulu)
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted
              ? 1
              : -1; // Aktif (false) di atas, selesai (true) di bawah
        }
        // Lalu urutkan berdasarkan waktu buat (terbaru dulu)
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      // Untuk filter specific, urutkan berdasarkan terbaru saja
      filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filteredTodos;
  }

  // Getter untuk mengetahui filter apa yang sedang aktif
  TodoFilter get currentFilter => _currentFilter;

  // Counter untuk berbagai status todos (untuk ditampilkan di UI)
  int get activeTodosCount =>
      _todos.where((todo) => !todo.isCompleted).length; // Jumlah todo aktif
  int get completedTodosCount =>
      _todos.where((todo) => todo.isCompleted).length; // Jumlah todo selesai
  int get totalTodosCount => _todos.length; // Total semua todo

  /// Menambah todo baru dengan validasi minimal 3 karakter
  /// Parameter: title = judul todo yang mau ditambah
  void addTodo(String title) {
    if (title.trim().length >= 3) {
      // Validasi: minimal 3 karakter
      final now = DateTime.now();
      _todos.add(
        Todo(
          id: now.millisecondsSinceEpoch.toString(), // ID unik dari timestamp
          title: title.trim(), // Hapus spasi di awal/akhir
          createdAt: now,
        ),
      );
      notifyListeners(); // Beritahu semua widget yang listening untuk update UI
    }
  }

  /// Menghapus todo berdasarkan ID
  /// Parameter: id = ID todo yang mau dihapus
  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners(); // Update UI
  }

  /// Mengembalikan todo yang telah dihapus (untuk fitur undo)
  /// Parameter: todo = object Todo yang mau dikembalikan
  void restoreTodo(Todo todo) {
    _todos.add(todo);
    notifyListeners(); // Update UI
  }

  /// Toggle status completed todo (centang/uncentang)
  /// Parameter: id = ID todo yang statusnya mau diubah
  void toggleTodo(String id) {
    final todoIndex = _todos.indexWhere((todo) => todo.id == id);
    if (todoIndex != -1) {
      _todos[todoIndex].isCompleted =
          !_todos[todoIndex].isCompleted; // Balik status
      notifyListeners(); // Update UI
    }
  }

  /// Mengubah filter saat ini
  /// Parameter: filter = jenis filter baru yang dipilih
  void setFilter(TodoFilter filter) {
    _currentFilter = filter;
    notifyListeners(); // Update UI
  }
}

// Fungsi utama - entry point aplikasi
void main() {
  runApp(const MyApp()); // Jalankan aplikasi Flutter
}

/// Root app dengan Material Design 3 dan Provider setup
/// Ini adalah widget utama yang membungkus seluruh aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Setup Provider di level tertinggi agar bisa diakses semua widget
      create: (context) => TodoProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Hilangkan banner debug
        theme: ThemeData(
          // Setup tema dengan warna biru sebagai primary color
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(
            0xFFF5F9FF,
          ), // Background biru muda
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2), // AppBar biru tua
            foregroundColor: Colors.white, // Text putih di AppBar
          ),
        ),
        home: const TodoPage(), // Halaman utama aplikasi
      ),
    );
  }
}

/// Halaman utama Todo List
/// StatelessWidget karena state dikelola oleh Provider
class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari TodoProvider untuk mendengarkan perubahan
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      // AppBar dengan judul aplikasi
      appBar: AppBar(title: const Text("Todo List")),

      // Tombol floating untuk tambah todo (posisi bawah tengah)
      floatingActionButton: Container(
        width: double.infinity, // Lebar penuh
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTodoBottomSheet(context), // Buka form tambah
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Tambah Tugas"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Body utama dengan layout Column
      body: Column(
        children: [
          // === SECTION 1: FILTER CHIPS ===
          // Container untuk filter chips (All, Active, Done)
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
                // Buat scrollable horizontal jika filter banyak
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Filter chip untuk "All"
                        _FilterChip(
                          text: "All",
                          filter: TodoFilter.all,
                          isSelected:
                              todoProvider.currentFilter == TodoFilter.all,
                        ),
                        const SizedBox(width: 8),
                        // Filter chip untuk "Active"
                        _FilterChip(
                          text: "Active",
                          filter: TodoFilter.active,
                          isSelected:
                              todoProvider.currentFilter == TodoFilter.active,
                        ),
                        const SizedBox(width: 8),
                        // Filter chip untuk "Done"
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

          // === SECTION 2: COUNTER CARDS ===
          // Container untuk menampilkan statistik todo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Counter untuk todo aktif
                Expanded(
                  child: _TaskCounter(
                    label: "Aktif",
                    count: todoProvider.activeTodosCount,
                    color: Colors.orange,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                // Counter untuk todo selesai
                Expanded(
                  child: _TaskCounter(
                    label: "Selesai",
                    count: todoProvider.completedTodosCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Counter untuk total todo
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
          // === SECTION 3: LIST AREA ===
          // Area utama untuk menampilkan daftar todo atau empty state
          Expanded(
            child: todoProvider.todos.isEmpty
                ? // EMPTY STATE: Tampilan ketika belum ada todo
                  Transform.translate(
                    offset: const Offset(
                      0,
                      -50,
                    ), // Geser ke atas 50px agar lebih centered
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon ilustrasi untuk empty state
                            Icon(
                              Icons.task_alt,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 24),
                            // Pesan empty state yang berbeda untuk setiap filter
                            Text(
                              _getEmptyMessage(todoProvider.currentFilter),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Hint tombol FAB - hanya tampil jika tidak ada data sama sekali
                            if (todoProvider.totalTodosCount == 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Tap tombol 'Tambah Tugas' di bawah",
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                : // TODO LIST: Tampilan daftar todo dengan ListView
                  ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ), // Space untuk FAB
                    itemCount: todoProvider.todos.length,
                    itemBuilder: (context, index) {
                      final todo = todoProvider.todos[index];

                      // Dismissible: Widget untuk swipe-to-delete
                      return Dismissible(
                        key: Key(todo.id), // Key unik untuk setiap item
                        direction: DismissDirection
                            .endToStart, // Swipe dari kanan ke kiri
                        // Background merah yang muncul saat di-swipe
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

                        // Konfirmasi sebelum hapus
                        confirmDismiss: (direction) async {
                          return await _showSwipeDeleteConfirmation(
                            context,
                            todo,
                          );
                        },

                        // Aksi ketika item dihapus
                        onDismissed: (direction) {
                          todoProvider.removeTodo(todo.id);
                          // Tampilkan snackbar dengan opsi undo
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
                                  todoProvider.restoreTodo(
                                    todo,
                                  ); // Kembalikan todo
                                },
                              ),
                            ),
                          );
                        },

                        // Card untuk membungkus setiap todo item
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          elevation: 2, // Bayangan card
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),

                            // CHECKBOX: Lingkaran untuk centang/uncentang
                            leading: Transform.scale(
                              scale: 1.3, // Perbesar 30% agar mudah disentuh
                              child: Theme(
                                // Custom theme untuk checkbox agar berbentuk lingkaran
                                data: Theme.of(context).copyWith(
                                  checkboxTheme: CheckboxThemeData(
                                    shape:
                                        const CircleBorder(), // Bentuk lingkaran
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                      width: 2,
                                    ),
                                    checkColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ), // Warna centang putih
                                    fillColor: WidgetStateProperty.resolveWith((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        // Jika dicentang, warna primary
                                        return Theme.of(
                                          context,
                                        ).colorScheme.primary;
                                      }
                                      return Colors
                                          .transparent; // Jika belum dicentang, transparan
                                    }),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: todo.isCompleted,
                                    onChanged: (_) =>
                                        todoProvider.toggleTodo(todo.id),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                    visualDensity: VisualDensity.comfortable,
                                  ),
                                ),
                              ),
                            ),

                            // TITLE: Judul todo dengan styling conditional
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                // Coret jika sudah selesai
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                // Abu-abu jika sudah selesai
                                color: todo.isCompleted ? Colors.grey : null,
                                fontSize: 16,
                              ),
                            ),

                            // TRAILING: Waktu dibuat (sebelah kanan)
                            trailing: Text(
                              _formatTime(
                                todo.createdAt,
                              ), // Format waktu yang mudah dibaca
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

  // === HELPER METHODS ===

  /// Menentukan pesan yang ditampilkan saat tidak ada todo
  /// Setiap filter memiliki pesan yang berbeda
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

  /// Format waktu menjadi string yang mudah dibaca (contoh: "5m", "2j", "3h")
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Baru saja"; // Kurang dari 1 menit
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m"; // Dalam hitungan menit
    } else if (difference.inDays < 1) {
      return "${difference.inHours}j"; // Dalam hitungan jam
    } else if (difference.inDays < 7) {
      return "${difference.inDays}h"; // Dalam hitungan hari
    } else {
      return "${dateTime.day}/${dateTime.month}"; // Tanggal lengkap
    }
  }

  /// Tampilkan dialog konfirmasi sebelum menghapus todo
  /// Return true jika user yakin hapus, false jika batal
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
            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            // Tombol Hapus
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

  /// Tampilkan bottom sheet untuk menambah todo baru
  void _showAddTodoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Bisa scroll jika keyboard muncul
      backgroundColor: Colors.transparent,
      enableDrag: true, // Bisa ditutup dengan drag ke bawah
      isDismissible: true, // Bisa ditutup dengan tap di luar
      builder: (context) => const _AddTodoBottomSheet(),
    ).then((_) {
      // Pastikan keyboard hilang saat bottom sheet ditutup
      if (context.mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }
}

// === WIDGET BOTTOM SHEET UNTUK TAMBAH TODO ===

/// Widget untuk bottom sheet form tambah todo
/// StatefulWidget karena ada TextEditingController dan state error
class _AddTodoBottomSheet extends StatefulWidget {
  const _AddTodoBottomSheet();

  @override
  State<_AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<_AddTodoBottomSheet> {
  final TextEditingController _controller =
      TextEditingController(); // Controller untuk input text
  final FocusNode _focusNode = FocusNode(); // Node untuk mengatur focus
  String? _errorText; // Text error jika validasi gagal

  @override
  void initState() {
    super.initState();
    // Auto-focus ke input field setelah bottom sheet muncul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  /// Method untuk menambah todo baru dengan validasi
  void _addTodo() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final title = _controller.text.trim(); // Hapus spasi di awal/akhir

    // Validasi: tidak boleh kosong
    if (title.isEmpty) {
      setState(() {
        _errorText = "Todo tidak boleh kosong";
      });
      return;
    }

    // Validasi: minimal 3 karakter
    if (title.length < 3) {
      setState(() {
        _errorText = "Todo minimal 3 karakter";
      });
      return;
    }

    // Tambah todo ke provider
    todoProvider.addTodo(title);

    // Cek apakah widget masih mounted sebelum menggunakan context
    if (!mounted) return;

    Navigator.of(context).pop(); // Tutup bottom sheet

    // Tampilkan feedback success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Todo "$title" berhasil ditambahkan'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardHeight = MediaQuery.of(
      context,
    ).viewInsets.bottom; // Tinggi keyboard

    return Container(
      // Padding yang menyesuaikan keyboard agar tidak tertutup
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: keyboardHeight + 16, // Extra space untuk keyboard
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ), // Rounded top corners
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ukuran minimal sesuai konten
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar untuk indikasi bisa di-drag
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title dengan icon
          Row(
            children: [
              Icon(Icons.add_task, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Tambah Tugas Baru",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input field untuk todo
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true, // Auto focus
            textCapitalization:
                TextCapitalization.sentences, // Kapital huruf pertama kalimat
            textInputAction: TextInputAction.done, // Tombol "Done" di keyboard
            decoration: InputDecoration(
              hintText: "Apa yang ingin kamu kerjakan?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.edit_outlined),
              errorText: _errorText, // Tampilkan error jika ada
              filled: true,
              fillColor: Colors.grey[50], // Background abu-abu muda
            ),
            maxLines: 3, // Maksimal 3 baris
            minLines: 1, // Minimal 1 baris
            onChanged: (_) {
              // Hapus error saat user mulai mengetik
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            onSubmitted: (_) => _addTodo(), // Tambah todo saat tekan "Done"
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan resource saat widget dihancurkan
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// === WIDGET HELPER COMPONENTS ===

/// Widget untuk filter chip yang mobile-friendly
/// Chip yang bisa diklik untuk mengubah filter
class _FilterChip extends StatelessWidget {
  final String text; // Text yang ditampilkan
  final TodoFilter filter; // Jenis filter
  final bool isSelected; // Apakah sedang dipilih

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
      onSelected: (_) =>
          todoProvider.setFilter(filter), // Ubah filter saat diklik
      selectedColor: colorScheme.primary.withValues(
        alpha: 0.2,
      ), // Background saat dipilih
      checkmarkColor: colorScheme.primary, // Warna centang
      backgroundColor: Colors.grey[100], // Background default
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.grey[300]!, // Border
          width: isSelected ? 2 : 1,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.primary
            : Colors.grey[600], // Warna text
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
    );
  }
}

/// Widget untuk menampilkan counter tugas dalam bentuk card
/// Digunakan untuk menampilkan statistik (Aktif, Selesai, Total)
class _TaskCounter extends StatelessWidget {
  final String label; // Label (contoh: "Aktif", "Selesai")
  final int count; // Angka yang ditampilkan
  final Color color; // Warna tema untuk card ini
  final IconData icon; // Icon yang ditampilkan

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
        color: color.withValues(
          alpha: 0.1,
        ), // Background transparan sesuai warna
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ), // Border dengan warna yang sama
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24), // Icon dengan warna tema
          const SizedBox(height: 4),
          Text(
            count.toString(), // Angka counter
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color, // Warna angka sesuai tema
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label, // Label di bawah angka
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(
                alpha: 0.8,
              ), // Warna label agak transparan
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/*
=== PENJELASAN STRUKTUR APLIKASI ===

1. MAIN FUNCTION & APP SETUP:
   - main() → MyApp() → TodoPage()
   - Provider setup di level MyApp untuk state management
   - Tema Material Design 3 dengan warna biru

2. STATE MANAGEMENT (TodoProvider):
   - Menyimpan list todo dalam _todos
   - Mengatur filter saat ini (_currentFilter)
   - Method untuk CRUD operations (Create, Read, Update, Delete)
   - notifyListeners() untuk update UI

3. UI STRUCTURE (TodoPage):
   - AppBar: Judul aplikasi
   - Filter Chips: All, Active, Done
   - Counter Cards: Statistik todo
   - List Area: Daftar todo atau empty state
   - FAB: Tombol tambah todo

4. FEATURES:
   - Add Todo: Bottom sheet dengan validasi
   - Toggle Todo: Tap checkbox untuk centang/uncentang
   - Delete Todo: Swipe dari kanan ke kiri + konfirmasi
   - Filter: Tampilkan todo berdasarkan status
   - Undo: Kembalikan todo yang sudah dihapus
   - Empty State: Pesan berbeda untuk setiap filter

5. WIDGETS CUSTOM:
   - _AddTodoBottomSheet: Form tambah todo
   - _FilterChip: Chip untuk filter
   - _TaskCounter: Card statistik

Semua komentar dibuat untuk memudahkan pembelajaran Flutter!
*/
