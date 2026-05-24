import 'package:flutter/material.dart';
import 'package:frontend/screens/chat_page.dart';
import 'package:frontend/services/api_service.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _kRoyalDark  = Color(0xFF0D1B4B);
const Color _kRoyal      = Color(0xFF1A3C8F);
const Color _kRoyalMid   = Color(0xFF2952B3);
const Color _kBg         = Color(0xFFF0F4FF);
const Color _kCard       = Color(0xFFFFFFFF);
const Color _kDivider    = Color(0xFFE4EAF8);
const Color _kTextSec    = Color(0xFF6B7A99);

class StagiairesPage extends StatefulWidget {
  const StagiairesPage({super.key});

  @override
  State<StagiairesPage> createState() => _StagiairesPageState();
}

class _StagiairesPageState extends State<StagiairesPage> {
  final _api = ApiService();
  List _stagiaires = [];
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
      final data = await _api.getStagiairesForEncadrantPro();
      setState(() => _stagiaires = data);
    } catch (e) {
      debugPrint("Error loading stagiaires: $e");
    }
    setState(() => _loading = false);
  }

  List get _filtered {
    if (_search.isEmpty) return _stagiaires;
    final q = _search.toLowerCase();
    return _stagiaires.where((s) {
      final name  = (s['studentName'] ?? '').toString().toLowerCase();
      final email = (s['studentEmail'] ?? '').toString().toLowerCase();
      final offre = (s['offre']?['titre'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || offre.contains(q);
    }).toList();
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':       return 'Accepté';
      case 'signed_by_company': return 'Signé Ent.';
      case 'fully_signed':   return 'Validé & Signé';
      default:               return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':       return const Color(0xFF059669);
      case 'signed_by_company': return _kRoyal;
      case 'fully_signed':   return const Color(0xFF0891B2);
      default:               return _kTextSec;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mes Stagiaires",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            Text("${_filtered.length} stagiaire${_filtered.length != 1 ? 's' : ''}",
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _load,
            tooltip: "Actualiser",
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        // Search bar
        Container(
          color: _kRoyalDark,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Rechercher par nom, email, offre...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kRoyal))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kRoyal,
                  child: _filtered.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _stagiairCard(_filtered[i]),
                        ),
                ),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kRoyal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined, size: 56, color: _kRoyal),
          ),
          const SizedBox(height: 16),
          const Text("Aucun stagiaire",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kRoyalDark)),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty
                ? "Aucun résultat pour \"$_search\""
                : "Vos stagiaires apparaîtront ici\nlorsque leurs candidatures seront acceptées.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _kTextSec, height: 1.5)),
        ],
      ),
    );
  }

  Widget _stagiairCard(dynamic s) {
    final name    = (s['studentName'] ?? 'Étudiant').toString();
    final email   = (s['studentEmail'] ?? '').toString();
    final photo   = (s['studentPhoto'] ?? '').toString();
    final status  = (s['status'] ?? 'accepted').toString();
    final phone   = (s['studentPhone'] ?? s['phone'] ?? '').toString();
    final adresse = (s['studentAdresse'] ?? s['city'] ?? '').toString();
    final ville   = (s['studentVille'] ?? s['city'] ?? '').toString();
    final univ    = (s['studentUniversite'] ?? s['etablissement'] ?? '').toString();

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    // Séparer prénom/nom si possible
    final nameParts = name.trim().split(' ');
    final prenom = nameParts.isNotEmpty ? nameParts[0] : name;
    final nom    = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(color: _kRoyal.withValues(alpha: 0.07),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header : Avatar + nom + statut ──────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: _kRoyal.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(bottom: BorderSide(color: _kDivider)),
          ),
          child: Row(children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kRoyalDark, _kRoyal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(
                  color: _kRoyal.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.transparent,
                backgroundImage: photo.isNotEmpty
                    ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                    : null,
                child: photo.isEmpty
                    ? Text(_initials(name),
                        style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Nom + prénom
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nom.isNotEmpty) ...[
                  Text(nom.toUpperCase(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: _kRoyalDark, letterSpacing: 0.5)),
                  Text(prenom,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: _kRoyalDark)),
                ] else
                  Text(name, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold, color: _kRoyalDark)),
              ],
            )),
            // Badge statut
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
        ),

        // ── Coordonnées ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(children: [
            _coordRow(Icons.email_outlined,    "Email",     email,   const Color(0xFF3B82F6)),
            if (phone.isNotEmpty)
              _coordRow(Icons.phone_outlined,  "Téléphone", phone,   const Color(0xFF10B981)),
            if (adresse.isNotEmpty)
              _coordRow(Icons.home_outlined,   "Adresse",   adresse, const Color(0xFFF59E0B)),
            if (ville.isNotEmpty && ville != adresse)
              _coordRow(Icons.location_on_outlined, "Ville", ville,  const Color(0xFF8B5CF6)),
            if (univ.isNotEmpty)
              _coordRow(Icons.account_balance_outlined, "Université", univ, const Color(0xFF0891B2)),

            // ── Bouton Contacter ──────────────────────────────────────
            if (email.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatPage(
                        otherEmail: email,
                        otherName:  name,
                        otherPhoto: photo,
                      ),
                    ));
                  },
                  icon: const SizedBox.shrink(),
                  label: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D1B4B), Color(0xFF1A3C8F)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text("Contacter par message",
                            style: TextStyle(
                              color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _coordRow(IconData icon, String label, String value, Color color) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              fontSize: 10, color: _kTextSec, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(
              fontSize: 13, color: _kRoyalDark, fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
    );
  }
}
