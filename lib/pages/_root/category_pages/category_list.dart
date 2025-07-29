import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<dynamic> categories = [];
  List<dynamic> books = [];
  Map<String, List<dynamic>> booksByCategory = {};
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        if (mounted) context.go('/login');
        return;
      }

      final userRes = await http.get(
        Uri.parse('http://localhost:8000/api/v1/auth/info/customer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final userBody = jsonDecode(userRes.body);
      if (userRes.statusCode != 200) throw Exception(userBody['message']);

      // Fetch categories
      final categoryRes = await http.get(
        Uri.parse('http://localhost:8000/api/v1/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final categoryBody = jsonDecode(categoryRes.body);
      if (categoryRes.statusCode != 200)
        throw Exception(categoryBody['message']);

      // Fetch all books
      final booksRes = await http.get(
        Uri.parse('http://localhost:8000/api/v1/books'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final booksBody = jsonDecode(booksRes.body);
      if (booksRes.statusCode != 200) throw Exception(booksBody['message']);

      // Group books by category
      final Map<String, List<dynamic>> groupedBooks = {};
      for (final category in categoryBody['data']) {
        groupedBooks[category['id'].toString()] = [];
      }

      for (final book in booksBody['data']['data']) {
        if (book['category_id'] != null) {
          final categoryId = book['category_id'].toString();
          if (groupedBooks.containsKey(categoryId)) {
            groupedBooks[categoryId]!.add(book);
          }
        }
      }

      setState(() {
        userData = userBody['data'];
        categories = categoryBody['data'];
        books = booksBody['data']['data'];
        booksByCategory = groupedBooks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/category/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _categoryNameController.clear();
        _fetchData();
      } else {
        throw Exception('Failed to add category');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _editCategory(int id, String currentName) async {
    _categoryNameController.text = currentName;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Kategori'),
        content: TextField(
          controller: _categoryNameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _categoryNameController.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/category/edit/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        _fetchData();
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _deleteCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/v1/category/delete/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _fetchData();
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null) {
      await http.post(
        Uri.parse('http://localhost:8000/api/v1/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }

    await prefs.clear();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Kategori Buku',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Tambah Kategori Baru'),
                content: TextField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(labelText: 'Nama Kategori'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addCategory();
                      Navigator.pop(context);
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userData?['name'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData?['email'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => context.go('/'),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('List Buku'),
              onTap: () => context.go('/books-list'),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Kategori'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Keranjang Sampah'),
              onTap: () => context.go('/trash'),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Publishers List'),
              onTap: () => context.go('/publishers_list'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : categories.isEmpty
          ? const Center(child: Text('Tidak ada kategori ditemukan.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryBooks =
                    booksByCategory[category['id'].toString()] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      category['name'] ?? 'Kategori Tanpa Nama',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${categoryBooks.length} buku',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _editCategory(category['id'], category['name']),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteCategory(category['id']),
                        ),
                      ],
                    ),
                    children: categoryBooks.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Tidak ada buku dalam kategori ini.'),
                            ),
                          ]
                        : categoryBooks.map((book) {
                            return ListTile(
                              leading: const Icon(
                                Icons.book,
                                color: Colors.blue,
                              ),
                              title: Text(
                                book['name'] ?? 'Judul tidak diketahui',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Penulis: ${book['publisher_nama'] ?? 'Tidak diketahui'}',
                                  ),
                                  if (book['published_date'] != null)
                                    Text('Tanggal: ${book['published_date']}'),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
