import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static String get url {
    const definedUrl = String.fromEnvironment('SUPABASE_URL');
    if (definedUrl.isNotEmpty) return definedUrl;
    return dotenv.maybeGet('SUPABASE_URL') ?? '';
  }

  static String get anonKey {
    const definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (definedAnonKey.isNotEmpty) return definedAnonKey;
    return dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
  }

  static bool _initialized = false;

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) {
      return;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (e, stackTrace) {
      _initialized = false;
      if (kDebugMode) {
        print('SupabaseConfig: initialization failed (app runs offline): $e');
        print(stackTrace);
      }
    }
  }
}
