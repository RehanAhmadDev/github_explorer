import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/github_provider.dart';
import 'views/home_screen.dart'; // ⬅️ Is line ko uncomment kiya

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GithubProvider()),
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
      title: 'GitHub Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(), // ⬅️ Yahan HomeScreen laga diya
    );
  }
}