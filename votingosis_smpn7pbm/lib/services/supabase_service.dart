import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // ⬅️ Untuk cek mode build

bool _isSupabaseInitialized = false;

/// Inisialisasi Supabase
Future<void> initSupabase() async {
  if (_isSupabaseInitialized) return;

  final String url;
  final String key;

  if (kReleaseMode) {
    // 📦 APK Release — pakai hardcoded untuk hindari error env
    url = 'https://snbsdfbjopizfydeadok.supabase.co';
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuYnNkZmJqb3BpemZ5ZGVhZG9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwNTUxMTUsImV4cCI6MjA2ODYzMTExNX0.MSDzdxvpvIQcS2FXsOcbhx-GbHFZMDQtZsoboScF1d0';
  } else {
    // 🧪 Debug mode — ambil dari env
    url = dotenv.env['SUPABASE_URL'] ?? '';
    key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || key.isEmpty) {
      throw Exception('❌ SUPABASE_URL atau SUPABASE_ANON_KEY kosong di env.txt');
    }
  }

  await Supabase.initialize(
    url: url,
    anonKey: key,
  );

  _isSupabaseInitialized = true;
}

/// Getter Supabase Client
SupabaseClient get supabase {
  if (!_isSupabaseInitialized) {
    throw Exception('❌ Supabase belum diinisialisasi. Panggil initSupabase() dulu.');
  }
  return Supabase.instance.client;
}
