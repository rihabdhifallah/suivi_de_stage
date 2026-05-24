import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/screens/archived_actors_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;

// ─── ADD / EDIT ACADEMIQUE PAGE ───────────────────────────────────────────────

class AddAcademiquePage extends StatefulWidget {
  final Map? editData;
  final List departements;
  final List specialites;
  const AddAcademiquePage({super.key, this.editData, required this.departements, required this.specialites});

  @override
  State<AddAcademiquePage> createState() => _AddAcademiquePageState();
}

class _AddAcademiquePageState extends State<AddAcademiquePage> {
  final _formKey = GlobalKey<FormState>();
  final api = ApiService();
  bool _loading = false;
  bool get _isEdit => widget.editData != null;

  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _cin = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _etablissement = TextEditingController();
  String? _departement, _specialite, _emailError;
  List<String> _filteredSpecs = [];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.editData!;
      _nom.text = d['name'] ?? '';
      _prenom.text = d['prenom'] ?? '';
      _cin.text = d['cin'] ?? '';
      _email.text = d['email'] ?? '';
      _phone.text = d['phone'] ?? '';
      _etablissement.text = d['etablissement'] ?? '';
      _departement = d['departement'];
      _specialite = d['specialite'];
      _updateSpecs(_departement);
    }
  }

  void _updateSpecs(String? dept) {
    if (dept == null) { setState(() { _filteredSpecs = []; }); return; }
    final deptObj = widget.departements.firstWhere((d) => d['nom'] == dept, orElse: () => null);
    if (deptObj == null) { setState(() { _filteredSpecs = []; }); return; }
    final deptId = deptObj['id'];
    setState(() {
      _filteredSpecs = widget.specialites
          .where((s) => s['departementId'] == deptId)
          .map<String>((s) => s['nom'] as String)
          .toList();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _emailError != null) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await api.updateUser(widget.editData!['id'], {
          'name': _nom.text.trim(), 'prenom': _prenom.text.trim(),
          'cin': _cin.text.trim(), 'phone': _phone.text.trim(),
          'etablissement': _etablissement.text.trim(),
          'departement': _departement, 'specialite': _specialite,
        });
        AdminTheme.snack(context, '✅ Encadrant modifié');
      } else {
        await api.createAcademique({
          'nom': _nom.text.trim(), 'prenom': _prenom.text.trim(),
          'cin': _cin.text.trim(), 'email': _email.text.trim(),
          'phone': _phone.text.trim(), 'etablissement': _etablissement.text.trim(),
          'departement': _departement, 'specialite': _specialite,
        });
        AdminTheme.snack(context, '✅ Encadrant créé');
      }
      Navigator.pop(context, true);
    } catch (e) {
      AdminTheme.snack(context, 'Erreur: $e', error: true);
    }
    setState(() => _loading = false);
  }

  Widget _banner(String title) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: AdminTheme.headerGradient, borderRadius: BorderRadius.circular(AdminTheme.radiusLg), boxShadow: AdminTheme.elevatedShadow),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
          child: const Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 28)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Remplissez les informations ci-dessous', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
    ]),
  );

  Widget _row(Widget a, Widget b) => MediaQuery.of(context).size.width > 500
      ? Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)])
      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 12), b]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: _isEdit ? 'Modifier encadrant' : 'Ajouter un encadrant',
        subtitle: _isEdit ? 'Mettre à jour les informations' : 'Créer un nouveau compte encadrant académique',
        showBack: true, context: context,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _banner(_isEdit ? 'Modifier encadrant' : 'Nouvel encadrant académique'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(AdminTheme.radiusLg), boxShadow: AdminTheme.cardShadow, border: Border.all(color: AdminTheme.divider)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AdminTheme.sectionLabel('Identité'),
                const SizedBox(height: 12),
                _row(
                  AdminTheme.formField(_nom, 'Nom *', Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                  AdminTheme.formField(_prenom, 'Prénom *', Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                ),
                const SizedBox(height: 12),
                AdminTheme.formField(_cin, 'CIN *', Icons.badge_outlined, keyboardType: TextInputType.number, maxLength: 8,
                    validator: (v) => v!.trim().length != 8 ? '8 chiffres requis' : null),
                const SizedBox(height: 20),
                AdminTheme.sectionLabel('Contact'),
                const SizedBox(height: 12),
                if (!_isEdit) ...[
                  AdminTheme.formField(_email, 'Email *', Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Requis';
                        if (!v.contains('@')) return 'Email invalide';
                        if (_emailError != null) return _emailError;
                        return null;
                      },
                      onEditingComplete: () async {
                        if (_email.text.contains('@')) {
                          final ok = await api.checkEmailAvailable(_email.text.trim());
                          setState(() => _emailError = ok ? null : 'Email déjà utilisé');
                          _formKey.currentState?.validate();
                        }
                      }),
                  if (_emailError != null) Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(_emailError!, style: const TextStyle(color: AdminTheme.danger, fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                ],
                _row(
                  AdminTheme.formField(_phone, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.number, maxLength: 8),
                  AdminTheme.formField(_etablissement, 'Établissement *', Icons.account_balance_outlined, validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                ),
                const SizedBox(height: 20),
                AdminTheme.sectionLabel('Département & Spécialité'),
                const SizedBox(height: 12),
                AdminTheme.dropdownField<String>(label: 'Département', value: _departement, icon: Icons.apartment_outlined,
                    items: [const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                      ...widget.departements.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d['nom'] as String, child: Text(d['nom'])))],
                    onChanged: (v) { setState(() { _departement = v; _specialite = null; }); _updateSpecs(v); }),
                const SizedBox(height: 12),
                AdminTheme.dropdownField<String>(label: 'Spécialité', value: _specialite, icon: Icons.book_outlined,
                    items: [const DropdownMenuItem(value: null, child: Text('— Aucune —')),
                      ..._filteredSpecs.map((s) => DropdownMenuItem(value: s, child: Text(s)))],
                    onChanged: (v) => setState(() => _specialite = v)),
                const SizedBox(height: 28),
                AdminTheme.primaryButton(
                  label: _isEdit ? 'Enregistrer les modifications' : 'Créer le compte encadrant',
                  icon: _isEdit ? Icons.save_outlined : Icons.person_add_outlined,
                  onPressed: _submit, loading: _loading,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── ACADEMIQUES LIST PAGE ────────────────────────────────────────────────────

class AcademiquesPage extends StatefulWidget {
  const AcademiquesPage({super.key});
  @override
  State<AcademiquesPage> createState() => _AcademiquesPageState();
}

class _AcademiquesPageState extends State<AcademiquesPage> {
  final api = ApiService();
  List academiques = [], departements = [], specialites = [];
  bool loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _loadAll(); }

  Future _loadAll() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        api.getAcademiques(),
        http.get(Uri.parse('${Config.baseUrl}/departements')),
        http.get(Uri.parse('${Config.baseUrl}/specialites')),
      ]);
      setState(() {
        academiques = results[0] as List;
        departements = jsonDecode((results[1] as http.Response).body);
        specialites = jsonDecode((results[2] as http.Response).body);
      });
    } catch (_) {}
    setState(() => loading = false);
  }

  List get _filtered => academiques.where((u) {
    if (u['status'] == 'archived') return false;
    final q = '${u['prenom'] ?? ''} ${u['name'] ?? ''} ${u['email'] ?? ''}'.toLowerCase();
    return q.contains(_search.toLowerCase());
  }).toList();

  void _goAdd() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddAcademiquePage(departements: departements, specialites: specialites),
    ));
    if (result == true) _loadAll();
  }

  void _goEdit(Map u) async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddAcademiquePage(editData: u, departements: departements, specialites: specialites),
    ));
    if (result == true) _loadAll();
  }

  void _toggleArchive(Map u) {
    final isArchived = u['status'] == 'archived';
    AdminTheme.confirmDelete(
      context: context,
      title: isArchived ? 'Désarchiver' : 'Archiver encadrant',
      message: isArchived
          ? 'Restaurer "${u['prenom'] ?? ''} ${u['name'] ?? ''}" ?'
          : 'Archiver "${u['prenom'] ?? ''} ${u['name'] ?? ''}" ?',
      onConfirm: () async {
        final newStatus = await api.archiveUser(u['id']);
        AdminTheme.snack(context, newStatus == 'archived' ? 'Encadrant archivé' : 'Encadrant restauré',
            error: newStatus == 'archived');
        _loadAll();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = academiques.where((u) => u['status'] != 'archived').length;
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Encadrants académiques',
        subtitle: '$activeCount encadrant${activeCount != 1 ? 's' : ''}',
        showBack: true,
        context: context,
        actions: [
          AdminTheme.appBarAction(
            icon: Icons.archive_outlined,
            tooltip: 'Archives',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedActorsPage(initialTab: 1),
                ),
              ).then((_) => _loadAll());
            },
          ),
          const SizedBox(width: 4),
          AdminTheme.appBarAction(icon: Icons.add_rounded, tooltip: 'Ajouter', onPressed: _goAdd),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Rechercher...', hintStyle: const TextStyle(color: AdminTheme.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AdminTheme.textSecondary, size: 20),
              filled: true, fillColor: AdminTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd), borderSide: const BorderSide(color: AdminTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd), borderSide: const BorderSide(color: AdminTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd), borderSide: const BorderSide(color: AdminTheme.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
              : _filtered.isEmpty
                  ? AdminTheme.emptyState(icon: Icons.assignment_ind_outlined, message: 'Aucun encadrant', sub: 'Appuyez sur + pour en ajouter un')
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: AdminTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final u = _filtered[i];
                          final name = '${u['prenom'] ?? ''} ${u['name'] ?? ''}'.trim();
                          final isArchived = u['status'] == 'archived';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isArchived ? AdminTheme.surface : AdminTheme.cardBg,
                              borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                              border: Border.all(color: AdminTheme.divider),
                              boxShadow: isArchived ? [] : AdminTheme.cardShadow,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: isArchived ? AdminTheme.textSecondary.withOpacity(0.1) : AdminTheme.warning.withOpacity(0.1),
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(color: isArchived ? AdminTheme.textSecondary : AdminTheme.warning, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(name.isNotEmpty ? name : 'N/A', style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13,
                                color: isArchived ? AdminTheme.textSecondary : AdminTheme.textPrimary,
                                decoration: isArchived ? TextDecoration.lineThrough : null)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(u['email'] ?? '', style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                                if ((u['etablissement'] ?? '').isNotEmpty || (u['departement'] ?? '').isNotEmpty)
                                  Text('${u['etablissement'] ?? ''}${(u['departement'] ?? '').isNotEmpty ? ' · ${u['departement']}' : ''}',
                                      style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
                              ]),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (isArchived) AdminTheme.statusBadge('Archivé', color: AdminTheme.textSecondary),
                                IconButton(icon: const Icon(Icons.edit_outlined, color: AdminTheme.primary, size: 18), onPressed: () => _goEdit(Map.from(u))),
                                IconButton(
                                  icon: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                      color: isArchived ? AdminTheme.success : AdminTheme.warning, size: 18),
                                  onPressed: () => _toggleArchive(Map.from(u)),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primary, elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Encadrant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _goAdd,
      ),
    );
  }
}
