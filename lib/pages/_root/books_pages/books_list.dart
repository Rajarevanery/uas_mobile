import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BooksListPage extends StatefulWidget {
  const BooksListPage({super.key});

  @override
  State<BooksListPage> createState() => _BooksListPageState();
}

class _BooksListPageState extends State<BooksListPage> {
  List<dynamic> books = [];
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

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

      if (userRes.statusCode != 200) {
        throw Exception(jsonDecode(userRes.body)['message']);
      }

      final user = jsonDecode(userRes.body)['data'];

      final booksRes = await http.get(
        Uri.parse('http://localhost:8000/api/v1/books'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (booksRes.statusCode != 200) {
        throw Exception(jsonDecode(booksRes.body)['message']);
      }

      final booksData = jsonDecode(booksRes.body)['data']['data'];

      setState(() {
        userData = user;
        books = booksData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
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

  Widget _buildDrawer() {
    return Drawer(
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
          _drawerItem(Icons.dashboard, 'Dashboard', () => context.go('/')),
          _drawerItem(Icons.book, 'List Buku', () => Navigator.pop(context)),
          _drawerItem(
            Icons.category,
            'Kategori',
            () => context.go('/category-list'),
          ),
          _drawerItem(
            Icons.delete,
            'Keranjang Sampah',
            () => context.go('/trash'),
          ),
          _drawerItem(
            Icons.library_books,
            'Publishers List',
            () => context.go('/publishers_list'),
          ),
          const Divider(),
          _drawerItem(Icons.logout, 'Logout', _logout),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }

  Widget _buildBookList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) return Center(child: Text(errorMessage!));
    if (books.isEmpty) {
      return const Center(child: Text('Tidak ada buku tersedia.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.book, color: Colors.blue),
              title: Text(book['name'] ?? 'Tanpa Judul'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publisher: ${book['publisher_nama'] ?? 'Tidak Diketahui'}',
                  ),
                  if (book['description'] != null &&
                      book['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        book['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _navigateToEditBook(book),
              ),
              onTap: () => _navigateToEditBook(book),
            ),
          );
        },
      ),
    );
  }

  void _navigateToEditBook(Map<String, dynamic> book) {
    context.go(
      '/manage-books',
      extra: {
        'id': book['id'],
        'name': book['name'],
        'publisher_nama': book['publisher_nama'],
        'description': book['description'],
        'published_date': book['published_date'],
        'category_id': book['category_id'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'List Buku',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBookList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add_book_screen'),
        tooltip: 'Tambah Buku Baru',
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
