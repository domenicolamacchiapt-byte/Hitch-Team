import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String? gender;
  final int? heightCm;
  final int? weeklySessions;
  final String? goal;
  final String? pastInjuries;
  final String? anamnesisResults;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender,
    this.heightCm,
    this.weeklySessions,
    this.goal,
    this.pastInjuries,
    this.anamnesisResults,
  });

  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isEmpty ? email : full;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String email) {
    return UserProfile(
      id: map['id'] as String,
      email: email,
      role: map['role'] as String? ?? 'client',
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      birthDate: map['birth_date'] != null ? DateTime.tryParse(map['birth_date']) : null,
      gender: map['gender'] as String?,
      heightCm: map['height_cm'] as int?,
      weeklySessions: map['weekly_sessions'] as int?,
      goal: map['goal'] as String?,
      pastInjuries: map['past_injuries'] as String?,
      anamnesisResults: map['anamnesis_results'] as String?,
    );
  }
}

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  UserProfile? _profile;
  bool _isLoading = false;

  User? get user => _user;
  UserProfile? get profile => _profile;
  String get role => _profile?.role ?? 'client';
  bool get isAdmin => role == 'admin';
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _user = _supabase.auth.currentUser;
    if (_user != null) await _fetchProfile();
    notifyListeners();

    _supabase.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        await _fetchProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      if (data != null) {
        _profile = UserProfile.fromMap(data, _user!.email ?? '');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> refreshProfile() async {
    await _fetchProfile();
    notifyListeners();
  }

  Future<String?> updateProfile(Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', _user!.id);
      await _fetchProfile();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateClientProfile(String clientId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', clientId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, {String firstName = '', String lastName = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final AuthResponse res = await _supabase.auth.signUp(email: email, password: password);
      if (res.user == null) return 'Errore sconosciuto durante la registrazione';
      // Update first and last name immediately after sign-up
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        await _supabase.from('profiles').update({
          'first_name': firstName,
          'last_name': lastName,
        }).eq('id', res.user!.id);
      }
      return null;
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
      return null;
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
