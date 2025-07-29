import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ManagingBooks extends StatefulWidget {
  final Map<String, dynamic> book;

  const ManagingBooks({super.key, required this.book});

  @override
  State<ManagingBooks> createState() => _ManagingBooksState();
}

class _ManagingBooksState extends State<ManagingBooks> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _publisherController;
  late TextEditingController _dateController;
  late int _selectedCategoryId;
  String? _categoryName;
  List<dynamic> categories = [];
  bool _isLoading = false;
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.book['name'] ?? '');
    _descriptionController = TextEditingController(
      text: widget.book['description'] ?? '',
    );
    _publisherController = TextEditingController(
      text: widget.book['publisher_nama'] ?? '',
    );
    _dateController = TextEditingController(
      text: widget.book['published_date'] ?? '',
    );
    _selectedCategoryId = widget.book['category_id'];
    _fetchCategories();
    _fetchCategoryName(_selectedCategoryId);
  }

  Future<void> _fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          categories = data['data'];
          _categoriesLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading categories: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchCategoryName(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/show/category/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categoryName = data['data']['name'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading category: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBook() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse(
        'http://localhost:8000/api/v1/publisher/book/edit/${widget.book['id']}',
      );

      final body = jsonEncode({
        'name': _nameController.text,
        'publisher_nama': _publisherController.text,
        'description': _descriptionController.text,
        'published_date': _dateController.text,
        'category_id': _selectedCategoryId,
      });

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buku berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/books-list');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Gagal memperbarui buku');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: const Text('Apakah Anda yakin ingin menghapus buku ini?'),
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

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception('Not authenticated');

      // Updated endpoint for soft delete
      final response = await http.delete(
        Uri.parse(
          'http://localhost:8000/api/v1/publisher/book/delete/${widget.book['id']}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buku berhasil dipindahkan ke keranjang sampah'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) context.go('/books-list');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Gagal menghapus buku');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Buku', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books-list'),
        ),
      ),
      body: _categoriesLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Buku',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _publisherController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Publisher',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Publikasi (YYYY-MM-DD)',
                        hintText: 'Contoh: 2023-01-15',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      items: categories.map<DropdownMenuItem<int>>((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'],
                          child: Text(category['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value!;
                          _categoryName = categories.firstWhere(
                            (cat) => cat['id'] == value,
                          )['name'];
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_categoryName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Kategori saat ini: $_categoryName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _deleteBook,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Hapus Buku', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _updateBook,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _publisherController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
