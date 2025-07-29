import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrashListPage extends StatefulWidget {
  const TrashListPage({super.key});

  @override
  State<TrashListPage> createState() => _TrashListPageState();
}

class _TrashListPageState extends State<TrashListPage> {
  List<dynamic> deletedBooks = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserAndBooks();
  }

  Future<void> _loadUserAndBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final userRes = await http.get(
        Uri.parse('http://localhost:8000/api/v1/auth/info/customer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final booksRes = await http.get(
        Uri.parse('http://localhost:8000/api/v1/publisher/book/trash'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final userBody = jsonDecode(userRes.body);
      final booksBody = jsonDecode(booksRes.body);

      if (userRes.statusCode != 200 || booksRes.statusCode != 200) {
        throw Exception('Gagal ambil data.');
      }

      setState(() {
        userData = userBody['data'];
        deletedBooks = booksBody['data']?['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _restoreBook(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) return;

    final res = await http.get(
      Uri.parse('http://localhost:8000/api/v1/publisher/book/restore/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil dipulihkan'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUserAndBooks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memulihkan buku'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _permanentlyDeleteBook(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) return;

    final res = await http.delete(
      Uri.parse('http://localhost:8000/api/v1/publisher/book/destroy/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku dihapus permanen'),
          backgroundColor: Colors.red,
        ),
      );
      _loadUserAndBooks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus buku secara permanen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keranjang Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserAndBooks,
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
              leading: const Icon(Icons.home),
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
              onTap: () => context.go('/category-list'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Keranjang Sampah'),
              onTap: () => Navigator.pop(context),
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
              onTap: () async {
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
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : deletedBooks.isEmpty
          ? const Center(child: Text('Tidak ada buku di keranjang sampah'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deletedBooks.length,
              itemBuilder: (context, index) {
                final book = deletedBooks[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.grey),
                    title: Text(book['name'] ?? 'Tanpa Judul'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${book['id']}'),
                        if (book['deleted_at'] != null)
                          Text(
                            'Dihapus pada: ${book['deleted_at']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () => _restoreBook(book['id']),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () => _permanentlyDeleteBook(book['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
