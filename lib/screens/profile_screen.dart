import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  /// When provided, this is a client being viewed/edited by the Admin.
  /// When null, the logged-in user's own profile is shown (read-only for guests).
  final Map<String, dynamic>? clientData;

  const ProfileScreen({super.key, this.clientData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _injuriesCtrl = TextEditingController();
  final _anamnesisCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _sessionsCtrl = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _targetId;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    if (widget.clientData != null) {
      _targetId = widget.clientData!['id'] as String;
      try {
        final data = await _supabase.from('profiles').select().eq('id', _targetId!).maybeSingle();
        if (data != null) _populateFromMap(data);
      } catch (e) {
        debugPrint('Error loading client profile: $e');
      }
    } else {
      _targetId = auth.user?.id;
      await auth.refreshProfile();
      final p = auth.profile;
      if (p != null) {
        _firstNameCtrl.text = p.firstName;
        _lastNameCtrl.text = p.lastName;
        _goalCtrl.text = p.goal ?? '';
        _injuriesCtrl.text = p.pastInjuries ?? '';
        _anamnesisCtrl.text = p.anamnesisResults ?? '';
        _heightCtrl.text = p.heightCm?.toString() ?? '';
        _sessionsCtrl.text = p.weeklySessions?.toString() ?? '';
        _gender = p.gender;
        _birthDate = p.birthDate;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _populateFromMap(Map<String, dynamic> data) {
    _firstNameCtrl.text = data['first_name'] ?? '';
    _lastNameCtrl.text = data['last_name'] ?? '';
    _goalCtrl.text = data['goal'] ?? '';
    _injuriesCtrl.text = data['past_injuries'] ?? '';
    _anamnesisCtrl.text = data['anamnesis_results'] ?? '';
    _heightCtrl.text = data['height_cm']?.toString() ?? '';
    _sessionsCtrl.text = data['weekly_sessions']?.toString() ?? '';
    _gender = data['gender'] as String?;
    final bd = data['birth_date'];
    _birthDate = bd != null ? DateTime.tryParse(bd) : null;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final data = {
      'first_name': _firstNameCtrl.text.trim().isEmpty ? null : _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim().isEmpty ? null : _lastNameCtrl.text.trim(),
      'goal': _goalCtrl.text.trim().isEmpty ? null : _goalCtrl.text.trim(),
      'past_injuries': _injuriesCtrl.text.trim().isEmpty ? null : _injuriesCtrl.text.trim(),
      'anamnesis_results': _anamnesisCtrl.text.trim().isEmpty ? null : _anamnesisCtrl.text.trim(),
      'height_cm': int.tryParse(_heightCtrl.text.trim()),
      'weekly_sessions': int.tryParse(_sessionsCtrl.text.trim()),
      'gender': _gender,
      'birth_date': _birthDate?.toIso8601String().split('T')[0],
    };

    String? err;
    if (widget.clientData != null) {
      err = await auth.updateClientProfile(_targetId!, data);
    } else {
      err = await auth.updateProfile(data);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.redAccent));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo salvato!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.isAdmin;

    String title = 'Profilo';
    if (widget.clientData != null) {
      final fn = widget.clientData!['first_name'] as String? ?? '';
      final ln = widget.clientData!['last_name'] as String? ?? '';
      final fullName = '$fn $ln'.trim();
      title = fullName.isNotEmpty ? fullName : (widget.clientData!['email'] ?? 'Profilo Cliente');
    }

    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (canEdit)
            _isSaving
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800))))
                : IconButton(icon: const Icon(Icons.save, color: Color(0xFFFF9800)), onPressed: _save, tooltip: 'Salva'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Anagrafica'),
            _buildTextField(_firstNameCtrl, 'Nome', canEdit),
            const SizedBox(height: 16),
            _buildTextField(_lastNameCtrl, 'Cognome', canEdit),
            const SizedBox(height: 24),
            _section('Dati Fisici'),
            _buildDropdown('Sesso', _gender, ['Maschio', 'Femmina', 'Non definito'], canEdit, (v) => setState(() => _gender = v)),
            const SizedBox(height: 16),
            _buildDatePicker(context, canEdit),
            const SizedBox(height: 16),
            _buildNumber(_heightCtrl, 'Altezza (cm)', canEdit),
            const SizedBox(height: 16),
            _buildNumber(_sessionsCtrl, 'Sedute / settimana', canEdit),
            const SizedBox(height: 24),
            _section('Obiettivo e Anamnesi'),
            _buildText(_goalCtrl, 'Obiettivo', canEdit),
            const SizedBox(height: 16),
            _buildText(_injuriesCtrl, 'Infortuni Passati', canEdit),
            const SizedBox(height: 16),
            _buildText(_anamnesisCtrl, 'Risultati Post Anamnesi', canEdit),
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(child: Text('Il profilo è gestito dal Coach', style: TextStyle(color: Colors.white38, fontSize: 13))),
              ),
            // Change password — only for own profile, not client view
            if (widget.clientData == null) ...
            [
              const SizedBox(height: 32),
              _section('Sicurezza Account'),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_outline, color: Color(0xFFFF9800)),
                  label: const Text('Cambia Password', style: TextStyle(color: Color(0xFFFF9800))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF9800)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showChangePasswordDialog(context),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(label, style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
  );

  Widget _buildDropdown(String label, String? value, List<String> items, bool enabled, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _dec(label),
      dropdownColor: const Color(0xFF1E1E1E),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildDatePicker(BuildContext context, bool enabled) {
    return InkWell(
      onTap: !enabled ? null : () async {
        final picked = await showDatePicker(context: context, initialDate: _birthDate ?? DateTime(1990), firstDate: DateTime(1930), lastDate: DateTime.now());
        if (picked != null) setState(() => _birthDate = picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.cake_outlined, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Data di nascita', style: TextStyle(color: _birthDate != null ? Colors.white : Colors.white38))),
          if (enabled) const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ]),
      ),
    );
  }

  Widget _buildNumber(TextEditingController ctrl, String label, bool enabled) => TextField(
    controller: ctrl, enabled: enabled, keyboardType: TextInputType.number,
    decoration: _dec(label),
  );

  void _showChangePasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Cambia Password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nuova Password',
                  filled: true, fillColor: const Color(0xFF161616),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Conferma Password',
                  filled: true, fillColor: const Color(0xFF161616),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ANNULLA', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.black),
              onPressed: isSubmitting ? null : () async {
                if (newPassCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La password deve avere almeno 6 caratteri'), backgroundColor: Colors.redAccent)
                  );
                  return;
                }
                if (newPassCtrl.text != confirmPassCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le password non coincidono'), backgroundColor: Colors.redAccent)
                  );
                  return;
                }
                setDialogState(() => isSubmitting = true);
                final err = await context.read<AuthProvider>().changePassword(newPassCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ?? 'Password aggiornata con successo!'),
                    backgroundColor: err != null ? Colors.redAccent : Colors.green,
                  ));
                }
              },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('SALVA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, bool enabled) => TextField(
    controller: ctrl, enabled: enabled,
    decoration: _dec(label),
  );

  Widget _buildText(TextEditingController ctrl, String label, bool enabled) => TextField(
    controller: ctrl, enabled: enabled, maxLines: 3,
    decoration: _dec(label, hint: true),
  );

  InputDecoration _dec(String label, {bool hint = false}) => InputDecoration(
    labelText: label, alignLabelWithHint: hint, filled: true, fillColor: const Color(0xFF161616),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}
