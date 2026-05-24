import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;

// ─── ADD / EDIT DEPARTEMENT PAGE ──────────────────────────────────────────────

class AddDepartementPage extends StatefulWidget {
  final Map? editData;
  const AddDepartementPage({super.key, this.editData});

  @override
  State<AddDepartementPage> createState() => _AddDepartementPageState();
}

class _AddDepartementPageState extends State<AddDepartementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  bool _loading = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _nomCtrl.text = widget.editData!['nom'] ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await http.patch(
          Uri.parse('${Config.baseUrl}/departements/${widget.editData!['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nom': _nomCtrl.text.trim()}),
        );
      } else {
        await http.post(
          Uri.parse('${Config.baseUrl}/departements'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nom': _nomCtrl.text.trim()}),
        );
      }
      setState(() => _loading = false);
      AdminTheme.snack(context, _isEdit ? '✅ Département modifié' : '✅ Département ajouté');
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
        title: _isEdit ? 'Modifier le département' : 'Ajouter un département',
        subtitle: _isEdit ? 'Mettre à jour les informations' : 'Créer un nouveau département',
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
                    child: const Icon(Icons.apartment_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_isEdit ? 'Modifier département' : 'Nouveau département',
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
                  AdminTheme.formField(_nomCtrl, 'Nom du département *', Icons.apartment_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
                  const SizedBox(height: 28),
                  AdminTheme.primaryButton(
                    label: _isEdit ? 'Enregistrer les modifications' : 'Ajouter le département',
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

// ─── DEPARTEMENTS LIST PAGE ───────────────────────────────────────────────────

class DepartementsPage extends StatefulWidget {
  const DepartementsPage({super.key});

  @override
  State<DepartementsPage> createState() => _DepartementsPageState();
}

class _DepartementsPageState extends State<DepartementsPage> {
  List departements = [];
  List specialites = [];
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
        http.get(Uri.parse('${Config.baseUrl}/departements')),
        http.get(Uri.parse('${Config.baseUrl}/specialites')),
      ]);
      setState(() {
        departements = jsonDecode(results[0].body);
        specialites = jsonDecode(results[1].body);
      });
    } catch (_) {}
    setState(() => loading = false);
  }

  Future _delete(int id) async {
    await http.delete(Uri.parse('${Config.baseUrl}/departements/$id'));
    await _loadAll();
  }

  void _goAdd() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const AddDepartementPage(),
    ));
    if (result == true) _loadAll();
  }

  void _goEdit(Map d) async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddDepartementPage(editData: d),
    ));
    if (result == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Départements',
        subtitle: 'Gestion des départements académiques',
        showBack: true,
        context: context,
        actions: [
          AdminTheme.appBarAction(icon: Icons.add_rounded, tooltip: 'Ajouter', onPressed: _goAdd),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
          : departements.isEmpty
              ? AdminTheme.emptyState(icon: Icons.apartment_outlined, message: 'Aucun département', sub: 'Appuyez sur + pour en ajouter un')
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: AdminTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                    itemCount: departements.length,
                    itemBuilder: (_, i) {
                      final d = departements[i];
                      final count = specialites.where((s) => s['departementId'] == d['id']).length;
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
                          leading: AdminTheme.iconContainer(Icons.apartment_outlined, color: AdminTheme.teal),
                          title: Text(d['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AdminTheme.textPrimary)),
                          subtitle: Text(
                            '$count spécialité${count != 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF0D9488), size: 20),
                              onPressed: () => _goEdit(Map.from(d)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AdminTheme.danger, size: 20),
                              onPressed: () => AdminTheme.confirmDelete(
                                context: context,
                                title: 'Supprimer département',
                                message: 'Supprimer "${d['nom']}" ? Cette action est irréversible.',
                                onConfirm: () async {
                                  await _delete(d['id']);
                                  AdminTheme.snack(context, 'Département supprimé', error: true);
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
        label: const Text('Département', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _goAdd,
      ),
    );
  }
}
