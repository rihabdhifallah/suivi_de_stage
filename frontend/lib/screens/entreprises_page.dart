import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/screens/archived_actors_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;

// ─── ADD / EDIT ENTREPRISE PAGE ───────────────────────────────────────────────

class AddEntreprisePage extends StatefulWidget {
  final Map? editData;
  const AddEntreprisePage({super.key, this.editData});

  @override
  State<AddEntreprisePage> createState() => _AddEntreprisePageState();
}

class _AddEntreprisePageState extends State<AddEntreprisePage> {
  final _formKey = GlobalKey<FormState>();
  final api = ApiService();
  bool _loading = false;
  bool get _isEdit => widget.editData != null;

  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _adresse = TextEditingController();
  final _secteur = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.editData!;
      _nom.text = d['nom'] ?? '';
      _email.text = d['email'] ?? '';
      _phone.text = d['telephone'] ?? '';
      _adresse.text = d['adresse'] ?? '';
      _secteur.text = d['secteurActivite'] ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await api.updateCompany(widget.editData!['id'], {
          'nom': _nom.text.trim(), 'telephone': _phone.text.trim(),
          'adresse': _adresse.text.trim(), 'secteurActivite': _secteur.text.trim(),
        });
        AdminTheme.snack(context, '✅ Entreprise modifiée');
      } else {
        final res = await http.post(
          Uri.parse('${Config.baseUrl}/companies'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nom': _nom.text.trim(), 'email': _email.text.trim(),
            'telephone': _phone.text.trim(), 'adresse': _adresse.text.trim(),
            'secteurActivite': _secteur.text.trim(), 'role': 'company',
          }),
        );
        if (res.statusCode != 200 && res.statusCode != 201) {
          final msg = jsonDecode(res.body)['message'] ?? 'Erreur serveur';
          throw Exception(msg);
        }
        AdminTheme.snack(context, '✅ Entreprise créée');
      }
      Navigator.pop(context, true);
    } catch (e) {
      AdminTheme.snack(context, 'Erreur: $e', error: true);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: _isEdit ? 'Modifier entreprise' : 'Ajouter une entreprise',
        subtitle: _isEdit ? 'Mettre à jour les informations' : 'Créer un nouveau compte entreprise',
        showBack: true, context: context,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Banner
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AdminTheme.headerGradient, borderRadius: BorderRadius.circular(AdminTheme.radiusLg), boxShadow: AdminTheme.elevatedShadow),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                    child: const Icon(Icons.business_outlined, color: Colors.white, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_isEdit ? 'Modifier entreprise' : 'Nouvelle entreprise', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Remplissez les informations ci-dessous', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            // Form card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AdminTheme.cardBg, borderRadius: BorderRadius.circular(AdminTheme.radiusLg), boxShadow: AdminTheme.cardShadow, border: Border.all(color: AdminTheme.divider)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AdminTheme.sectionLabel('Informations générales'),
                const SizedBox(height: 12),
                AdminTheme.formField(_nom, 'Nom de l\'entreprise *', Icons.business_outlined, validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                AdminTheme.formField(_secteur, 'Secteur d\'activité *', Icons.category_outlined, validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                const SizedBox(height: 20),
                AdminTheme.sectionLabel('Contact'),
                const SizedBox(height: 12),
                if (!_isEdit) ...[
                  AdminTheme.formField(_email, 'Email *', Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      }),
                  const SizedBox(height: 12),
                ],
                AdminTheme.formField(_phone, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                AdminTheme.formField(_adresse, 'Adresse', Icons.location_on_outlined),
                const SizedBox(height: 28),
                AdminTheme.primaryButton(
                  label: _isEdit ? 'Enregistrer les modifications' : 'Créer le compte entreprise',
                  icon: _isEdit ? Icons.save_outlined : Icons.add_business_outlined,
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

// ─── ENTREPRISES LIST PAGE ────────────────────────────────────────────────────

class EntreprisesPage extends StatefulWidget {
  const EntreprisesPage({super.key});
  @override
  State<EntreprisesPage> createState() => _EntreprisesPageState();
}

class _EntreprisesPageState extends State<EntreprisesPage> {
  final api = ApiService();
  List entreprises = [];
  bool loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _loadAll(); }

  Future _loadAll() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/companies'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => entreprises = data is List ? data : []);
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  List get _filtered => entreprises.where((e) {
    if (e['status'] == 'archived') return false;
    final q = '${e['nom'] ?? ''} ${e['email'] ?? ''} ${e['secteurActivite'] ?? ''}'.toLowerCase();
    return q.contains(_search.toLowerCase());
  }).toList();

  void _goAdd() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEntreprisePage()));
    if (result == true) _loadAll();
  }

  void _goEdit(Map e) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntreprisePage(editData: e)));
    if (result == true) _loadAll();
  }

  void _toggleArchive(Map e) {
    final isArchived = e['status'] == 'archived';
    AdminTheme.confirmDelete(
      context: context,
      title: isArchived ? 'Désarchiver' : 'Archiver entreprise',
      message: isArchived
          ? 'Restaurer "${e['nom']}" ?'
          : 'Archiver "${e['nom']}" ? Elle ne pourra plus se connecter.',
      onConfirm: () async {
        await api.archiveCompany(e['id']);
        AdminTheme.snack(context, isArchived ? 'Entreprise restaurée' : 'Entreprise archivée',
            error: !isArchived);
        _loadAll();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = entreprises.where((e) => e['status'] != 'archived').length;
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Entreprises',
        subtitle: '$activeCount entreprise${activeCount != 1 ? 's' : ''}',
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
                  builder: (_) => const ArchivedActorsPage(initialTab: 2),
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
                  ? AdminTheme.emptyState(icon: Icons.business_outlined, message: 'Aucune entreprise', sub: 'Appuyez sur + pour en ajouter une')
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: AdminTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final e = _filtered[i];
                          final isArchived = e['status'] == 'archived';
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
                                backgroundColor: isArchived ? AdminTheme.textSecondary.withOpacity(0.1) : AdminTheme.teal.withOpacity(0.1),
                                child: Text((e['nom'] ?? '?')[0].toUpperCase(),
                                    style: TextStyle(color: isArchived ? AdminTheme.textSecondary : AdminTheme.teal, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(e['nom'] ?? 'N/A', style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13,
                                color: isArchived ? AdminTheme.textSecondary : AdminTheme.textPrimary,
                                decoration: isArchived ? TextDecoration.lineThrough : null)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e['email'] ?? '', style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                                if ((e['secteurActivite'] ?? '').isNotEmpty)
                                  Text(e['secteurActivite'], style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary)),
                              ]),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (isArchived) AdminTheme.statusBadge('Archivé', color: AdminTheme.textSecondary),
                                IconButton(icon: const Icon(Icons.edit_outlined, color: AdminTheme.primary, size: 18), onPressed: () => _goEdit(Map.from(e))),
                                IconButton(
                                  icon: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                      color: isArchived ? AdminTheme.success : AdminTheme.warning, size: 18),
                                  onPressed: () => _toggleArchive(Map.from(e)),
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
        label: const Text('Entreprise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _goAdd,
      ),
    );
  }
}
