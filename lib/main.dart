import 'package:flutter/material.dart';
import 'package:v2net/app/app.dart';
import 'package:v2net/app/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  runApp(const MainApp());
}
