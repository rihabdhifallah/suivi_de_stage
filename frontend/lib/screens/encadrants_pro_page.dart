import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/admin_theme.dart';

// ─── ADD / EDIT ENCADRANT PRO PAGE ───────────────────────────────────────────

class AddEncadrantProPage extends StatefulWidget {
  final Map? editData;
  const AddEncadrantProPage({super.key, this.editData});

  @override
  State<AddEncadrantProPage> createState() => _AddEncadrantProPageState();
}

class _AddEncadrantProPageState extends State<AddEncadrantProPage> {
  final _formKey = GlobalKey<FormState>();
  final api = ApiService();
  bool _loading = false;
  bool get _isEdit => widget.editData != null;

  final _nom    = TextEditingController();
  final _email  = TextEditingController();
  final _phone  = TextEditingController();
  final _poste  = TextEditingController();
  final _adresse = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.editData!;
      _nom.text    = d['name'] ?? d['nomComplet'] ?? '';
      _email.text  = d['email'] ?? '';
      _phone.text  = d['phone'] ?? d['telephone'] ?? '';
      _poste.text  = d['poste'] ?? '';
      _adresse.text = d['adresse'] ?? '';
    }
  }

  @override
  void dispose() {
    _nom.dispose(); _email.dispose();
    _phone.dispose(); _poste.dispose(); _adresse.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await api.updateEncadrantPro(widget.editData!['id'], {
          'nomComplet': _nom.text.trim(),
          'telephone': _phone.text.trim(),
          'poste': _poste.text.trim(),
          'adresse': _adresse.text.trim(),
        });
        AdminTheme.snack(context, '✅ Encadrant professionnel modifié');
      } else {
        final result = await api.createEncadrant({
          'nomComplet': _nom.text.trim(),
          'email': _email.text.trim(),
          'telephone': _phone.text.trim(),
          'poste': _poste.text.trim(),
          'adresse': _adresse.text.trim(),
        });
        // Show credentials dialog
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text('Compte créé', style: TextStyle(fontSize: 15)),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Les accès ont été envoyés par email. Copiez-les ci-dessous :"),
                const SizedBox(height: 14),
                SelectableText("Email : ${result['email'] ?? _email.text.trim()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                SelectableText("Mot de passe : ${result['password'] ?? '—'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
            ),
          );
        }
        AdminTheme.snack(context, '✅ Encadrant professionnel créé');
      }
      if (mounted) Navigator.pop(context, true);
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
        title: _isEdit ? 'Modifier encadrant pro' : 'Ajouter encadrant pro',
        subtitle: _isEdit ? 'Mettre à jour les informations' : 'Créer un compte encadrant professionnel',
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
              decoration: BoxDecoration(
                gradient: AdminTheme.headerGradient,
                borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                boxShadow: AdminTheme.elevatedShadow,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                  child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_isEdit ? 'Modifier encadrant professionnel' : 'Nouvel encadrant professionnel',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Remplissez les informations ci-dessous',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            // Form card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminTheme.cardBg,
                borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                boxShadow: AdminTheme.cardShadow,
                border: Border.all(color: AdminTheme.divider),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AdminTheme.sectionLabel('Identité'),
                const SizedBox(height: 12),
                AdminTheme.formField(_nom, 'Nom complet *', Icons.person_outline_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                AdminTheme.formField(_poste, 'Poste / Fonction', Icons.badge_outlined),
                const SizedBox(height: 20),
                AdminTheme.sectionLabel('Contact'),
                const SizedBox(height: 12),
                if (!_isEdit) ...[
                  AdminTheme.formField(_email, 'Email Gmail *', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Requis';
                      if (!v.contains('@')) return 'Email invalide';
                      if (!v.toLowerCase().endsWith('@gmail.com')) return 'Doit être une adresse Gmail';
                      return null;
                    }),
                  const SizedBox(height: 12),
                ],
                AdminTheme.formField(_phone, 'Téléphone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                AdminTheme.formField(_adresse, 'Adresse', Icons.location_on_outlined),
                const SizedBox(height: 28),
                AdminTheme.primaryButton(
                  label: _isEdit ? 'Enregistrer les modifications' : 'Créer le compte',
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

// ─── ENCADRANTS PRO LIST PAGE ─────────────────────────────────────────────────

class EncadrantsProPage extends StatefulWidget {
  const EncadrantsProPage({super.key});
  @override
  State<EncadrantsProPage> createState() => _EncadrantsProPageState();
}

class _EncadrantsProPageState extends State<EncadrantsProPage> {
  final api = ApiService();
  List _encadrants = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final data = await api.getEncadrantsPro();
      setState(() => _encadrants = data);
    } catch (e) {
      AdminTheme.snack(context, 'Erreur chargement: $e', error: true);
    }
    setState(() => _loading = false);
  }

  List get _filtered {
    final q = _search.toLowerCase();
    return _encadrants.where((e) {
      if (e['status'] == 'archived') return false;
      final name = '${e['name'] ?? ''} ${e['nomComplet'] ?? ''}'.toLowerCase();
      final email = (e['email'] ?? '').toLowerCase();
      final poste = (e['poste'] ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || poste.contains(q);
    }).toList();
  }

  List get _archived => _encadrants.where((e) => e['status'] == 'archived').toList();

  void _goAdd() async {
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AddEncadrantProPage()));
    if (result == true) _loadAll();
  }

  void _goEdit(Map e) async {
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => AddEncadrantProPage(editData: e)));
    if (result == true) _loadAll();
  }

  void _toggleArchive(Map e) {
    final isArchived = e['status'] == 'archived';
    final name = e['name'] ?? e['nomComplet'] ?? 'cet encadrant';
    AdminTheme.confirmDelete(
      context: context,
      title: isArchived ? 'Désarchiver' : 'Archiver encadrant',
      message: isArchived
          ? 'Restaurer "$name" ? Il pourra à nouveau se connecter.'
          : 'Archiver "$name" ? Il ne pourra plus se connecter.',
      onConfirm: () async {
        try {
          final newStatus = await api.archiveEncadrantPro(e['id']);
          AdminTheme.snack(context,
            newStatus == 'archived' ? 'Encadrant archivé' : 'Encadrant restauré',
            error: newStatus == 'archived');
          _loadAll();
        } catch (err) {
          AdminTheme.snack(context, 'Erreur: $err', error: true);
        }
      },
    );
  }

  void _showArchivedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(
            color: AdminTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AdminTheme.divider, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Icon(Icons.archive_outlined, color: AdminTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text('Archivés (${_archived.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
              ]),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: _archived.isEmpty
                  ? AdminTheme.emptyState(
                      icon: Icons.archive_outlined,
                      message: 'Aucun encadrant archivé',
                      sub: 'Tous les encadrants sont actifs')
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: _archived.length,
                      itemBuilder: (_, i) {
                        final e = _archived[i];
                        final name = e['name'] ?? e['nomComplet'] ?? 'N/A';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                            border: Border.all(color: AdminTheme.divider),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AdminTheme.textSecondary.withOpacity(0.1),
                              child: Text(name[0].toUpperCase(),
                                style: const TextStyle(color: AdminTheme.textSecondary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                                color: AdminTheme.textSecondary, decoration: TextDecoration.lineThrough)),
                            subtitle: Text(e['email'] ?? '',
                              style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.success.withOpacity(0.1),
                                foregroundColor: AdminTheme.success,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                                  side: BorderSide(color: AdminTheme.success.withOpacity(0.3)),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _toggleArchive(Map.from(e));
                              },
                              icon: const Icon(Icons.unarchive_outlined, size: 14),
                              label: const Text('Restaurer',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _encadrants.where((e) => e['status'] != 'archived').length;

    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Encadrants professionnels',
        subtitle: '$activeCount encadrant${activeCount != 1 ? 's' : ''} actif${activeCount != 1 ? 's' : ''}',
        showBack: true,
        context: context,
        actions: [
          AdminTheme.appBarAction(
            icon: Icons.archive_outlined,
            tooltip: 'Archivés (${_archived.length})',
            onPressed: _showArchivedSheet,
          ),
          const SizedBox(width: 4),
          AdminTheme.appBarAction(
            icon: Icons.add_rounded,
            tooltip: 'Ajouter',
            onPressed: _goAdd,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Encadrant pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _goAdd,
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email, poste...',
              hintStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AdminTheme.textSecondary, size: 20),
              filled: true, fillColor: AdminTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                borderSide: const BorderSide(color: AdminTheme.border)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                borderSide: const BorderSide(color: AdminTheme.border)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                borderSide: const BorderSide(color: AdminTheme.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
              : _filtered.isEmpty
                  ? AdminTheme.emptyState(
                      icon: Icons.work_outline_rounded,
                      message: 'Aucun encadrant professionnel',
                      sub: 'Appuyez sur + pour en ajouter un')
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: AdminTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final e = _filtered[i];
                          final name = e['name'] ?? e['nomComplet'] ?? 'N/A';
                          final email = e['email'] ?? '';
                          final poste = e['poste'] ?? '';
                          final phone = e['phone'] ?? e['telephone'] ?? '';
                          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AdminTheme.cardBg,
                              borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                              border: Border.all(color: AdminTheme.divider),
                              boxShadow: AdminTheme.cardShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AdminTheme.teal.withOpacity(0.12),
                                  child: Text(initials,
                                    style: const TextStyle(
                                      color: AdminTheme.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14,
                                      color: AdminTheme.textPrimary)),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      const Icon(Icons.email_outlined, size: 12, color: AdminTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(email,
                                        style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                                        overflow: TextOverflow.ellipsis)),
                                    ]),
                                    if (poste.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        const Icon(Icons.badge_outlined, size: 12, color: AdminTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(poste, style: const TextStyle(
                                          fontSize: 11, color: AdminTheme.textSecondary,
                                          fontWeight: FontWeight.w500)),
                                      ]),
                                    ],
                                    if (phone.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        const Icon(Icons.phone_outlined, size: 12, color: AdminTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(phone, style: const TextStyle(
                                          fontSize: 11, color: AdminTheme.textSecondary)),
                                      ]),
                                    ],
                                  ],
                                )),
                                // Actions
                                Column(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AdminTheme.primary, size: 18),
                                    tooltip: 'Modifier',
                                    onPressed: () => _goEdit(Map.from(e)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.archive_outlined, color: AdminTheme.warning, size: 18),
                                    tooltip: 'Archiver',
                                    onPressed: () => _toggleArchive(Map.from(e)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
