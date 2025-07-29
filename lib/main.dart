import 'package:bookmanagement/pages/_auth/login.dart';
import 'package:bookmanagement/pages/_auth/register.dart';
import 'package:bookmanagement/pages/_root/books_pages/add_book_screen.dart';
import 'package:bookmanagement/pages/_root/books_pages/books_list.dart';
import 'package:bookmanagement/pages/_root/category_pages/category_list.dart';
import 'package:bookmanagement/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/trash_list.dart';
import 'pages/_root/books_pages/managing_books.dart';
import 'pages/publishers_list.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return Dashboard();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return Login();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) {
        return Register();
      },
    ),
    GoRoute(
      path: '/books-list',
      builder: (BuildContext context, GoRouterState state) {
        return BooksListPage();
      },
    ),
    GoRoute(
      path: '/category-list',
      builder: (BuildContext context, GoRouterState state) {
        return CategoryListPage();
      },
    ),
    GoRoute(
      path: '/trash',
      builder: (BuildContext context, GoRouterState state) {
        return TrashListPage();
      },
    ),
    GoRoute(
      path: '/manage-books',
      pageBuilder: (context, state) {
        final book = state.extra as Map<String, dynamic>;
        return MaterialPage(child: ManagingBooks(book: book));
      },
    ),
    GoRoute(
      path: '/publishers_list',
      builder: (BuildContext context, GoRouterState state) {
        return PublishersListPage();
      },
    ),
    GoRoute(
      path: '/add_book_screen',
      builder: (BuildContext context, GoRouterState state) {
        return AddBookScreen();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
