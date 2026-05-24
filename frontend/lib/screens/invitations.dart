import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _kRoyalDark  = Color(0xFF0D1B4B);
const Color _kRoyal      = Color(0xFF1A3C8F);
const Color _kRoyalMid   = Color(0xFF2952B3);
const Color _kBg         = Color(0xFFF0F4FF);
const Color _kCard       = Color(0xFFFFFFFF);
const Color _kDivider    = Color(0xFFE4EAF8);
const Color _kTextSec    = Color(0xFF6B7A99);
const Color _kGreen      = Color(0xFF059669);

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});
  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final api = ApiService();

  // Invitations (offres)
  List _invitations = [];
  // Stagiaires acceptés
  List _stagiaires  = [];

  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final invData  = await api.getEncadrantInvitations();
      final stagData = await api.getStagiairesForEncadrantPro();
      setState(() {
        _invitations = invData;
        _stagiaires  = stagData;
      });
    } catch (e) {
      debugPrint("Error loading: $e");
    }
    setState(() => _loading = false);
  }

  List get _filteredInv {
    if (_search.isEmpty) return _invitations;
    final q = _search.toLowerCase();
    return _invitations.where((inv) {
      final offre = inv['offre'] ?? {};
      final titre   = (offre['titre'] ?? '').toString().toLowerCase();
      final domaine = (offre['domaine'] ?? '').toString().toLowerCase();
      final company = (offre['companyName'] ?? offre['companyEmail'] ?? '').toString().toLowerCase();
      return titre.contains(q) || domaine.contains(q) || company.contains(q);
    }).toList();
  }

  List get _filteredStag {
    if (_search.isEmpty) return _stagiaires;
    final q = _search.toLowerCase();
    return _stagiaires.where((s) {
      final name  = (s['studentName'] ?? '').toString().toLowerCase();
      final email = (s['studentEmail'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':          return _kGreen;
      case 'signed_by_company': return _kRoyal;
      case 'fully_signed':      return const Color(0xFF0891B2);
      case 'rejected':
      case 'refused':           return const Color(0xFFDC2626);
      default:                  return _kRoyalMid;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':          return 'Accepté';
      case 'signed_by_company': return 'Signé Ent.';
      case 'fully_signed':      return 'Validé & Signé';
      case 'rejected':
      case 'refused':           return 'Refusé';
      default:                  return 'En attente';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kRoyalDark, _kRoyal, _kRoyalMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Invitations & Stagiaires",
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: _kRoyalDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.6), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kRoyal))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kRoyal,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                children: [

                  // ── SECTION 1 : INVITATIONS (OFFRES) ─────────────────────
                  _sectionHeader(
                    icon: Icons.mark_email_read_rounded,
                    title: "Invitations aux offres",
                    count: _filteredInv.length,
                    color: _kRoyal,
                  ),
                  const SizedBox(height: 12),

                  if (_filteredInv.isEmpty)
                    _emptyBox("Aucune invitation pour le moment",
                      Icons.work_outline_rounded)
                  else
                    ...(_filteredInv.map((inv) => _invitationCard(inv))),

                  const SizedBox(height: 28),

                  // ── SÉPARATEUR ────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: Container(height: 1, color: _kDivider)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kRoyal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kRoyal.withValues(alpha: 0.2)),
                      ),
                      child: const Text("Mes Stagiaires",
                        style: TextStyle(fontSize: 11, color: _kRoyal,
                          fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Container(height: 1, color: _kDivider)),
                  ]),

                  const SizedBox(height: 20),

                  // ── SECTION 2 : MES STAGIAIRES ────────────────────────────
                  _sectionHeader(
                    icon: Icons.groups_rounded,
                    title: "Mes Stagiaires",
                    count: _filteredStag.length,
                    color: _kGreen,
                  ),
                  const SizedBox(height: 12),

                  if (_filteredStag.isEmpty)
                    _emptyBox("Aucun stagiaire pour le moment",
                      Icons.groups_outlined)
                  else
                    ...(_filteredStag.map((s) => _stagiairCard(s))),
                ],
              ),
            ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ),
    ]);
  }

  // ── EMPTY BOX ─────────────────────────────────────────────────────────────
  Widget _emptyBox(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
      ),
      child: Column(children: [
        Icon(icon, size: 36, color: _kDivider),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(fontSize: 13, color: _kTextSec)),
      ]),
    );
  }

  // ── CARTE INVITATION (offre + étudiant si accepté) ────────────────────────
  Widget _invitationCard(dynamic inv) {
    final offre   = inv['offre'] ?? {};
    final titre   = (offre['titre'] ?? 'Offre sans titre').toString();
    final duree   = (offre['duree'] ?? '').toString();
    final niveau  = (offre['niveau'] ?? '').toString();
    final domaine = (offre['domaine'] ?? '').toString();
    final company = (offre['companyName'] ?? offre['companyEmail'] ?? '').toString();
    final status  = (inv['status'] ?? 'pending').toString();

    final stagiaire  = inv['application'];
    final hasStudent = stagiaire != null;
    final stagName   = hasStudent ? (stagiaire['studentName'] ?? '').toString() : '';
    final stagEmail  = hasStudent ? (stagiaire['studentEmail'] ?? '').toString() : '';
    final stagPhoto  = hasStudent ? (stagiaire['studentPhoto'] ?? stagiaire['photo'] ?? '').toString() : '';
    final stagPhone  = hasStudent ? (stagiaire['phone'] ?? stagiaire['telephone'] ?? '').toString() : '';
    final stagEtab   = hasStudent ? (stagiaire['etablissement'] ?? stagiaire['university'] ?? '').toString() : '';

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: _kRoyal.withValues(alpha: 0.06),
          blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Badge titre offre ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kRoyal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kRoyal.withValues(alpha: 0.15)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.work_outline_rounded, size: 13, color: _kRoyal),
              const SizedBox(width: 6),
              Flexible(child: Text(titre,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kRoyal),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),

          const SizedBox(height: 10),

          // ── Chips durée / niveau / domaine ──
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (duree.isNotEmpty)   _chip(Icons.timer_outlined, duree, _kRoyalMid),
            if (niveau.isNotEmpty)  _chip(Icons.school_outlined, niveau, const Color(0xFF7C3AED)),
            if (domaine.isNotEmpty) _chip(Icons.category_outlined, domaine, const Color(0xFF059669)),
          ]),

          // ── Étudiant accepté (si disponible) ──
          if (hasStudent) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: _kDivider),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kRoyalDark, _kRoyal],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: _kRoyal.withValues(alpha: 0.2),
                    blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  backgroundImage: stagPhoto.isNotEmpty
                      ? NetworkImage("${ApiService.baseUrl}/uploads/$stagPhoto")
                      : null,
                  child: stagPhoto.isEmpty
                      ? Text(_initials(stagName.isNotEmpty ? stagName : '?'),
                          style: const TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stagName.isNotEmpty ? stagName : 'Étudiant',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: _kRoyalDark),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (stagEmail.isNotEmpty)
                  Text(stagEmail,
                    style: const TextStyle(fontSize: 11, color: _kTextSec),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                    color: statusColor)),
              ),
            ]),
            if (stagEtab.isNotEmpty || stagPhone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                if (stagEtab.isNotEmpty)
                  Expanded(child: Row(children: [
                    const Icon(Icons.account_balance_outlined, size: 12, color: _kTextSec),
                    const SizedBox(width: 4),
                    Expanded(child: Text(stagEtab,
                      style: const TextStyle(fontSize: 11, color: _kTextSec),
                      overflow: TextOverflow.ellipsis)),
                  ])),
                if (stagPhone.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.phone_outlined, size: 12, color: _kTextSec),
                    const SizedBox(width: 4),
                    Text(stagPhone, style: const TextStyle(fontSize: 11, color: _kTextSec)),
                  ]),
              ]),
            ],
          ] else ...[
            // Pas encore d'étudiant — afficher l'entreprise
            const SizedBox(height: 10),
            const Divider(height: 1, color: _kDivider),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.business_outlined, size: 13, color: _kTextSec),
              const SizedBox(width: 5),
              Expanded(child: Text(company,
                style: const TextStyle(fontSize: 11, color: _kTextSec),
                overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ]),
      ),
    );
  }

  // ── CARTE STAGIAIRE (nom + email + statut + détails offre) ──────────────
  Widget _stagiairCard(dynamic s) {
    final name   = (s['studentName'] ?? 'Étudiant').toString();
    final email  = (s['studentEmail'] ?? '').toString();
    final photo  = (s['studentPhoto'] ?? '').toString();
    final status = (s['status'] ?? 'accepted').toString();
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    // Détails de l'offre acceptée
    final offre      = s['offre'] ?? {};
    final offreTitre = (offre['titre'] ?? '').toString();
    final offreDuree = (offre['duree'] ?? '').toString();
    final offreDebut = (offre['dateDebut'] ?? '').toString();
    final offreFin   = (offre['dateFin'] ?? '').toString();
    final skillsRaw  = offre['skills'];
    List<String> skills = [];
    if (skillsRaw is List) {
      skills = skillsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (skillsRaw is String && skillsRaw.isNotEmpty) {
      skills = skillsRaw
          .replaceAll('{', '').replaceAll('}', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Ligne 1 : Avatar + nom + email + statut ──
          Row(children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kGreen.withValues(alpha: 0.8), _kGreen],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: 0.2),
                  blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                backgroundImage: photo.isNotEmpty
                    ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                    : null,
                child: photo.isEmpty
                    ? Text(_initials(name),
                        style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kRoyalDark)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.email_outlined, size: 12, color: _kTextSec),
                const SizedBox(width: 4),
                Expanded(child: Text(email,
                  style: const TextStyle(fontSize: 12, color: _kTextSec),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: statusColor)),
            ),
          ]),

          // ── Détails de l'offre (si disponible) ──
          if (offreTitre.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: _kDivider),
            const SizedBox(height: 10),

            // Titre de l'offre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kRoyal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRoyal.withValues(alpha: 0.15)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.work_outline_rounded, size: 13, color: _kRoyal),
                const SizedBox(width: 6),
                Flexible(child: Text(offreTitre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: _kRoyal),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),

            const SizedBox(height: 8),

            // Durée + dates
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (offreDuree.isNotEmpty)
                _chip(Icons.timer_outlined, offreDuree, _kRoyalMid),
              if (offreDebut.isNotEmpty && offreFin.isNotEmpty)
                _chip(Icons.date_range_outlined,
                  "${offreDebut.length >= 10 ? offreDebut.substring(0, 10) : offreDebut}"
                  " → "
                  "${offreFin.length >= 10 ? offreFin.substring(0, 10) : offreFin}",
                  const Color(0xFFF59E0B)),
            ]),

            // Compétences
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6,
                children: skills.take(4).map((sk) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0891B2).withValues(alpha: 0.2)),
                  ),
                  child: Text(sk, style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: Color(0xFF0891B2))),
                )).toList()),
            ],
          ],
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
