import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;

// ─── ADD / EDIT SPECIALITE PAGE ───────────────────────────────────────────────

class AddSpecialitePage extends StatefulWidget {
  final List departements;
  final Map? editData;
  const AddSpecialitePage({super.key, required this.departements, this.editData});

  @override
  State<AddSpecialitePage> createState() => _AddSpecialitePageState();
}

class _AddSpecialitePageState extends State<AddSpecialitePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  int? _selectedDeptId;
  bool _loading = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nomCtrl.text = widget.editData!['nom'] ?? '';
      _selectedDeptId = widget.editData!['departementId'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await http.patch(
          Uri.parse('${Config.baseUrl}/specialites/${widget.editData!['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nom': _nomCtrl.text.trim(), 'departementId': _selectedDeptId}),
        );
      } else {
        await http.post(
          Uri.parse('${Config.baseUrl}/specialites'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nom': _nomCtrl.text.trim(),
            if (_selectedDeptId != null) 'departementId': _selectedDeptId,
          }),
        );
      }
      setState(() => _loading = false);
      AdminTheme.snack(context, _isEdit ? '✅ Spécialité modifiée' : '✅ Spécialité ajoutée');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      AdminTheme.snack(context, 'Erreur: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: _isEdit ? 'Modifier la spécialité' : 'Ajouter une spécialité',
        subtitle: _isEdit ? 'Mettre à jour les informations' : 'Créer une nouvelle spécialité',
        showBack: true,
        context: context,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AdminTheme.headerGradient,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  boxShadow: AdminTheme.elevatedShadow,
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                    child: const Icon(Icons.book_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_isEdit ? 'Modifier spécialité' : 'Nouvelle spécialité',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Remplissez les informations ci-dessous', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.cardBg,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  boxShadow: AdminTheme.cardShadow,
                  border: Border.all(color: AdminTheme.divider),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AdminTheme.sectionLabel('Informations'),
                  const SizedBox(height: 12),
                  AdminTheme.formField(_nomCtrl, 'Nom de la spécialité *', Icons.book_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: _selectedDeptId,
                    decoration: InputDecoration(
                      labelText: 'Département (optionnel)',
                      labelStyle: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
                      prefixIcon: const Icon(Icons.apartment_outlined, size: 18, color: AdminTheme.primary),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd), borderSide: const BorderSide(color: AdminTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd), borderSide: const BorderSide(color: AdminTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd), borderSide: const BorderSide(color: AdminTheme.primary, width: 1.5)),
                    ),
                    hint: const Text('— Aucun —', style: TextStyle(fontSize: 13)),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('— Aucun —', style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary))),
                      ...widget.departements.map<DropdownMenuItem<int>>((d) => DropdownMenuItem<int>(
                        value: d['id'] as int,
                        child: Text(d['nom'] as String, style: const TextStyle(fontSize: 13)),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedDeptId = v),
                  ),
                  const SizedBox(height: 28),
                  AdminTheme.primaryButton(
                    label: _isEdit ? 'Enregistrer les modifications' : 'Ajouter la spécialité',
                    icon: _isEdit ? Icons.save_outlined : Icons.add_rounded,
                    onPressed: _submit,
                    loading: _loading,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SPECIALITES LIST PAGE ────────────────────────────────────────────────────

class SpecialitesPage extends StatefulWidget {
  const SpecialitesPage({super.key});

  @override
  State<SpecialitesPage> createState() => _SpecialitesPageState();
}

class _SpecialitesPageState extends State<SpecialitesPage> {
  List specialites = [];
  List departements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future _loadAll() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${Config.baseUrl}/specialites')),
        http.get(Uri.parse('${Config.baseUrl}/departements')),
      ]);
      setState(() {
        specialites = jsonDecode(results[0].body);
        departements = jsonDecode(results[1].body);
      });
    } catch (_) {}
    setState(() => loading = false);
  }

  Future _delete(int id) async {
    await http.delete(Uri.parse('${Config.baseUrl}/specialites/$id'));
    await _loadAll();
  }

  String? _getDeptName(int? deptId) {
    if (deptId == null) return null;
    try {
      return departements.firstWhere((d) => d['id'] == deptId)['nom'] as String;
    } catch (_) {
      return null;
    }
  }

  void _goAdd() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddSpecialitePage(departements: departements),
    ));
    if (result == true) _loadAll();
  }

  void _goEdit(Map s) async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddSpecialitePage(departements: departements, editData: s),
    ));
    if (result == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Spécialités',
        subtitle: 'Gestion des spécialités académiques',
        showBack: true,
        context: context,
        actions: [
          AdminTheme.appBarAction(icon: Icons.add_rounded, tooltip: 'Ajouter', onPressed: _goAdd),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
          : specialites.isEmpty
              ? AdminTheme.emptyState(icon: Icons.book_outlined, message: 'Aucune spécialité', sub: 'Appuyez sur + pour en ajouter une')
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: AdminTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                    itemCount: specialites.length,
                    itemBuilder: (_, i) {
                      final s = specialites[i];
                      final deptName = _getDeptName(s['departementId']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AdminTheme.cardBg,
                          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                          boxShadow: AdminTheme.cardShadow,
                          border: Border.all(color: AdminTheme.divider),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: AdminTheme.iconContainer(Icons.book_outlined),
                          title: Text(s['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AdminTheme.textPrimary)),
                          subtitle: deptName != null
                              ? Row(children: [
                                  const Icon(Icons.apartment_outlined, size: 12, color: Color(0xFF0D9488)),
                                  const SizedBox(width: 4),
                                  Text(deptName, style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488))),
                                ])
                              : Text('Aucun département', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary.withOpacity(0.6))),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AdminTheme.primary, size: 20),
                              onPressed: () => _goEdit(Map.from(s)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AdminTheme.danger, size: 20),
                              onPressed: () => AdminTheme.confirmDelete(
                                context: context,
                                title: 'Supprimer spécialité',
                                message: 'Supprimer "${s['nom']}" ? Cette action est irréversible.',
                                onConfirm: () async {
                                  await _delete(s['id']);
                                  AdminTheme.snack(context, 'Spécialité supprimée', error: true);
                                },
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Spécialité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _goAdd,
      ),
    );
  }
}
