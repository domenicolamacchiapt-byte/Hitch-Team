import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  String _role = 'client';
  bool _isLoading = false;

  User? get user => _user;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      await _fetchRole();
    }
    notifyListeners();

    _supabase.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        await _fetchRole();
      } else {
        _role = 'client';
      }
      notifyListeners();
    });
  }

  Future<void> _fetchRole() async {
    try {
      final data = await _supabase.from('profiles').select('role').eq('id', _user!.id).maybeSingle();
      if (data != null) {
        _role = data['role'] as String;
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
  }

  Future<String?> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final AuthResponse res = await _supabase.auth.signUp(email: email, password: password);
      if (res.user == null) return 'Errore sconosciuto durante la registrazione';
      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
