import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // ✅ untuk kReleaseMode
import 'services/supabase_service.dart';
import 'screens/login_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hanya load dotenv saat debug/development
  if (!kReleaseMode) {
    await dotenv.load(fileName: "env.txt");
  }

  // Lock orientasi ke portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Inisialisasi Supabase
  await initSupabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voting OSIS SMPN 7',
      home: const LoginSelectorScreen(),
    );
  }
}
