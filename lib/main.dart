import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.loadToken();
  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  final ApiClient api;
  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ManoVecina',
      theme: ThemeData(useMaterial3: true),
      home: api.hasToken ? HomePage(api: api) : LoginPage(api: api),
    );
  }
}
