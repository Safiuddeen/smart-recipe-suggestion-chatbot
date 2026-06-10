import 'package:flutter/material.dart';
import 'package:cook_it_now/route/goroute.dart';
import 'package:cook_it_now/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cook It Now',
      theme: ThemeData(primarySwatch: Colors.pink),
      routerConfig: MyAppRouter().router,
    );
  }
}
