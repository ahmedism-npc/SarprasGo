import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_user.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    if (_repository.isConfigured) {
      _subscription = _repository.authChanges.listen((_) => refreshProfile());
      refreshProfile();
    }
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;
  AppUser? user;
  bool isLoading = false;
  String? error;
  bool get isConfigured => _repository.isConfigured;

  Future<void> refreshProfile() async {
    try {
      user = await _repository.currentProfile();
      error = null;
    } catch (exception) {
      user = null;
      error = exception.toString();
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _repository.signIn(email.trim(), password);
    } catch (exception) {
      error = _friendlyError(exception);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void enterDemo(AppRole role) {
    user = AppUser(
      id: 'demo-${role.name}',
      name: switch (role) {
        AppRole.admin => 'Admin Sarpras',
        AppRole.petugasSarpras => 'Petugas Sarpras',
        AppRole.peminjam => 'Nadia Putri',
      },
      email: 'demo@sarprasgo.local',
      role: role,
      userType: switch (role) {
        AppRole.admin => UserType.staf,
        AppRole.petugasSarpras => UserType.staf,
        AppRole.peminjam => UserType.mahasiswa,
      },
    );
    error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    user = null;
    notifyListeners();
  }

  String _friendlyError(Object exception) {
    if (exception is AuthException) return exception.message;
    return 'Tidak dapat masuk. Periksa koneksi dan data akun Anda.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
