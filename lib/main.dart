import 'package:flutter/material.dart';
import 'package:v2net/app/app.dart';
import 'package:v2net/app/di/injector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();

  runApp(const MainApp());
}
