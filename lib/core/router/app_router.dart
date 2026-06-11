import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:v2net/ui/home_page/home_page.dart';

final GoRouter app_router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomePage();
      },
    ),
  ],
);
