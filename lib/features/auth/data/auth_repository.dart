import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/app_user.dart';

class AuthRepository {
  bool get isConfigured => AppConfig.hasSupabaseConfig;
  SupabaseClient? get _client => isConfigured ? Supabase.instance.client : null;

  Stream<AuthState> get authChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<AppUser?> currentProfile() async {
    final client = _client;
    final authUser = client?.auth.currentUser;
    if (client == null || authUser == null) return null;
    final row = await client
        .from('users')
        .select('id,name,email,role,user_type,is_active')
        .eq('id', authUser.id)
        .maybeSingle();
    if (row == null || row['is_active'] != true) {
      await client.auth.signOut();
      throw const AuthException('Akun belum diaktifkan Admin.');
    }
    return AppUser.fromRow(row);
  }

  Future<AppUser> signIn(String email, String password) async {
    final client = _client;
    if (client == null) throw StateError('Supabase belum dikonfigurasi.');
    await client.auth.signInWithPassword(email: email, password: password);
    final profile = await currentProfile();
    if (profile == null) throw const AuthException('Profil pengguna tidak ditemukan.');
    return profile;
  }

  Future<void> signOut() async => _client?.auth.signOut();
}
