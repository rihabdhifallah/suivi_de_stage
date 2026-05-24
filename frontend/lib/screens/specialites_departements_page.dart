import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;

// ─── ADD/EDIT SPECIALITE PAGE ─────────────────────────────────────────────────

class AddSpecialitePage extends StatefulWidget {
  final List departements;
  final Map? editData; // null = add mode
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
              // Header banner
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    ),
                    child: const Icon(Icons.book_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEdit ? 'Modifier spécialité' : 'Nouvelle spécialité',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Remplissez les informations ci-dessous',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 24),
              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.cardBg,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  boxShadow: AdminTheme.cardShadow,
                  border: Border.all(color: AdminTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminTheme.sectionLabel('Informations'),
                    const SizedBox(height: 12),
                    AdminTheme.formField(_nomCtrl, 'Nom de la spécialité *', Icons.book_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
                    const SizedBox(height: 14),
                    // Département dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedDeptId,
                      decoration: InputDecoration(
                        labelText: 'Département',
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
                      hint: const Text('Choisir un département (optionnel)', style: TextStyle(fontSize: 13)),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ADD/EDIT DEPARTEMENT PAGE ────────────────────────────────────────────────

class AddDepartementPage extends StatefulWidget {
  final Map? editData; // null = add mode
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
              // Header banner
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    ),
                    child: const Icon(Icons.apartment_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEdit ? 'Modifier département' : 'Nouveau département',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Remplissez les informations ci-dessous',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 24),
              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.cardBg,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  boxShadow: AdminTheme.cardShadow,
                  border: Border.all(color: AdminTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MAIN LIST PAGE ───────────────────────────────────────────────────────────

class SpecialitesDepartementsPage extends StatefulWidget {
  final int initialTab;
  const SpecialitesDepartementsPage({super.key, this.initialTab = 0});

  @override
  State<SpecialitesDepartementsPage> createState() => _SpecialitesDepartementsPageState();
}

class _SpecialitesDepartementsPageState extends State<SpecialitesDepartementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List specialites = [];
  List departements = [];
  bool loadingSpec = true;
  bool loadingDept = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future _loadAll() async {
    await Future.wait([_loadSpecialites(), _loadDepartements()]);
  }

  Future _loadSpecialites() async {
    setState(() => loadingSpec = true);
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/specialites'));
      setState(() => specialites = jsonDecode(res.body));
    } catch (_) {}
    setState(() => loadingSpec = false);
  }

  Future _loadDepartements() async {
    setState(() => loadingDept = true);
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/departements'));
      setState(() => departements = jsonDecode(res.body));
    } catch (_) {}
    setState(() => loadingDept = false);
  }

  Future _deleteSpecialite(int id) async {
    await http.delete(Uri.parse('${Config.baseUrl}/specialites/$id'));
    await _loadSpecialites();
  }

  Future _deleteDepartement(int id) async {
    await http.delete(Uri.parse('${Config.baseUrl}/departements/$id'));
    await _loadDepartements();
  }

  String? _getDeptName(int? deptId) {
    if (deptId == null) return null;
    try {
      return departements.firstWhere((d) => d['id'] == deptId)['nom'] as String;
    } catch (_) {
      return null;
    }
  }

  void _goAddSpecialite() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddSpecialitePage(departements: departements),
    ));
    if (result == true) _loadSpecialites();
  }

  void _goEditSpecialite(Map s) async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddSpecialitePage(departements: departements, editData: s),
    ));
    if (result == true) _loadSpecialites();
  }

  void _goAddDepartement() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const AddDepartementPage(),
    ));
    if (result == true) _loadAll();
  }

  void _goEditDepartement(Map d) async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddDepartementPage(editData: d),
    ));
    if (result == true) _loadAll();
  }

  void _confirmDelete({required String type, required String nom, required Future Function() onConfirm}) {
    AdminTheme.confirmDelete(
      context: context,
      title: 'Supprimer $type',
      message: 'Supprimer "$nom" ? Cette action est irréversible.',
      onConfirm: () async {
        await onConfirm();
        AdminTheme.snack(context, '$type supprimé(e)', error: true);
      },
    );
  }

  Widget _specCard(dynamic s) {
    final deptName = _getDeptName(s['departementId']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            tooltip: 'Modifier',
            onPressed: () => _goEditSpecialite(Map.from(s)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AdminTheme.danger, size: 20),
            tooltip: 'Supprimer',
            onPressed: () => _confirmDelete(type: 'Spécialité', nom: s['nom'], onConfirm: () => _deleteSpecialite(s['id'])),
          ),
        ]),
      ),
    );
  }

  Widget _deptCard(dynamic d) {
    final count = specialites.where((s) => s['departementId'] == d['id']).length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        boxShadow: AdminTheme.cardShadow,
        border: Border.all(color: AdminTheme.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: AdminTheme.iconContainer(Icons.apartment_outlined, color: const Color(0xFF0D9488)),
        title: Text(d['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AdminTheme.textPrimary)),
        subtitle: Text('$count spécialité${count != 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0D9488), size: 20),
            tooltip: 'Modifier',
            onPressed: () => _goEditDepartement(Map.from(d)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AdminTheme.danger, size: 20),
            tooltip: 'Supprimer',
            onPressed: () => _confirmDelete(type: 'Département', nom: d['nom'], onConfirm: () => _deleteDepartement(d['id'])),
          ),
        ]),
      ),
    );
  }

  Widget _specialitesTab() {
    if (loadingSpec) return const Center(child: CircularProgressIndicator(color: AdminTheme.primary));
    if (specialites.isEmpty) return AdminTheme.emptyState(icon: Icons.book_outlined, message: 'Aucune spécialité', sub: 'Appuyez sur + pour en ajouter une');
    return RefreshIndicator(
      onRefresh: _loadSpecialites,
      color: AdminTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 90),
        itemCount: specialites.length,
        itemBuilder: (_, i) => _specCard(specialites[i]),
      ),
    );
  }

  Widget _departementsTab() {
    if (loadingDept) return const Center(child: CircularProgressIndicator(color: AdminTheme.primary));
    if (departements.isEmpty) return AdminTheme.emptyState(icon: Icons.apartment_outlined, message: 'Aucun département', sub: 'Appuyez sur + pour en ajouter un');
    return RefreshIndicator(
      onRefresh: _loadDepartements,
      color: AdminTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 90),
        itemCount: departements.length,
        itemBuilder: (_, i) => _deptCard(departements[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSpec = _tabController.index == 0;
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: AdminTheme.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestion académique', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('Spécialités & Départements', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.book_outlined, size: 18), text: 'Spécialités'),
              Tab(icon: Icon(Icons.apartment_outlined, size: 18), text: 'Départements'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_specialitesTab(), _departementsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primary,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isSpec ? 'Spécialité' : 'Département',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: isSpec ? _goAddSpecialite : _goAddDepartement,
      ),
    );
  }
}
