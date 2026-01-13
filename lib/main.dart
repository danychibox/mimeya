import 'package:flutter/material.dart';
import 'package:mimeya/screens/home_screen.dart';
import 'package:mimeya/providers/classifier_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClassifierProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Disease Detector',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}