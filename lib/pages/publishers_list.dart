import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PublishersListPage extends StatefulWidget {
  const PublishersListPage({super.key});

  @override
  State<PublishersListPage> createState() => _PublishersListPageState();
}

class _PublishersListPageState extends State<PublishersListPage> {
  List<dynamic> books = [];
  List<String> publishers = [];
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

      // Extract unique publisher names
      final publisherNames = booksData
          .map<String>(
            (book) => book['publisher_nama']?.toString() ?? 'Unknown',
          )
          .toSet()
          .toList();

      setState(() {
        userData = user;
        books = booksData;
        publishers = publisherNames;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publishers List',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
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
              onTap: () => context.go('/category-list'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Keranjang Sampah'),
              onTap: () => context.go('/trash'),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Publishers List'),
              onTap: () => Navigator.pop(context),
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
          : publishers.isEmpty
          ? const Center(child: Text('Tidak ada publisher ditemukan'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: publishers.length,
              itemBuilder: (context, index) {
                final publisherName = publishers[index];
                // Get books by this publisher
                final publisherBooks = books
                    .where((book) => book['publisher_nama'] == publisherName)
                    .toList();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      publisherName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: publisherBooks.isEmpty
                        ? [const ListTile(title: Text('Tidak ada buku'))]
                        : publisherBooks.map((book) {
                            return ListTile(
                              leading: const Icon(Icons.book),
                              title: Text(book['name'] ?? 'Tanpa Judul'),
                              subtitle: Text(
                                'ID: ${book['id']} • ${book['published_date'] ?? ''}',
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
