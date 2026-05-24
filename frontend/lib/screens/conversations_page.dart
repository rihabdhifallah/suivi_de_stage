import 'package:flutter/material.dart';
import 'package:frontend/screens/chat_page.dart';
import 'package:frontend/services/api_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _kDark  = Color(0xFF0D1B4B);
const Color _kBlue  = Color(0xFF1A3C8F);
const Color _kLight = Color(0xFF4A72D4);
const Color _kBg    = Color(0xFFF0F4FF);
const Color _kCard  = Color(0xFFFFFFFF);
const Color _kBorder= Color(0xFFE4EAF8);
const Color _kSec   = Color(0xFF6B7A99);
const Color _kGreen = Color(0xFF059669);

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});
  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage>
    with SingleTickerProviderStateMixin {
  final api = ApiService();
  late TabController _tabCtrl;

  // Encadrant professionnel
  List<Map<String, String>> _encPro  = [];
  bool _loadingPro = true;

  // Encadrant académique
  List<Map<String, String>> _encAcad = [];
  bool _loadingAcad = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadPro();
    _loadAcad();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  /// Encadrants professionnels via candidatures acceptées
  Future<void> _loadPro() async {
    try {
      final List apps = await api.getMyApplications();
      final Set<String> seen = {};
      final List<Map<String, String>> loaded = [];

      for (var app in apps) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        if (!['accepted','signed_by_company','fully_signed'].contains(status)) continue;

        final offre = app['offre'] ?? app['stage'] ?? {};
        final invitations = offre['invitations'];
        if (invitations is List) {
          for (var inv in invitations) {
            final enc = inv['encadrant'];
            if (enc == null) continue;
            final email = (enc['email'] ?? '').toString().trim().toLowerCase();
            final name  = (enc['nomComplet'] ?? enc['name'] ?? '').toString().trim();
            final photo = (enc['photo'] ?? '').toString();
            if (email.isNotEmpty && !seen.contains(email)) {
              seen.add(email);
              loaded.add({
                'name':  name.isNotEmpty ? name : email,
                'email': email,
                'photo': photo,
                'offre': (offre['titre'] ?? '').toString(),
              });
            }
          }
        }
      }
      if (mounted) setState(() { _encPro = loaded; _loadingPro = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingPro = false);
    }
  }

  /// Encadrants académiques via encadrements
  Future<void> _loadAcad() async {
    try {
      final List data = await api.getMyEncadrements();
      final Set<String> seen = {};
      final List<Map<String, String>> loaded = [];

      for (var enc in data) {
        final encadrant = enc['encadrant'];
        if (encadrant == null) continue;
        final email = (encadrant['email'] ?? '').toString().trim().toLowerCase();
        final name  = (encadrant['name']  ?? encadrant['nom'] ?? '').toString().trim();
        final photo = (encadrant['photo'] ?? '').toString();
        if (email.isNotEmpty && !seen.contains(email)) {
          seen.add(email);
          loaded.add({
            'name':  name.isNotEmpty ? name : email,
            'email': email,
            'photo': photo,
            'specialite': (enc['specialite'] ?? '').toString(),
          });
        }
      }
      if (mounted) setState(() { _encAcad = loaded; _loadingAcad = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingAcad = false);
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
              colors: [_kDark, _kBlue, _kLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Conversations",
          style: TextStyle(color: Colors.white, fontSize: 17,
            fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.work_outline_rounded, size: 18),
              text: "Enc. Professionnel"),
            Tab(icon: Icon(Icons.school_outlined, size: 18),
              text: "Enc. Académique"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(_encPro,  _loadingPro,  isPro: true),
          _buildList(_encAcad, _loadingAcad, isPro: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, String>> list, bool loading,
      {required bool isPro}) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(
              isPro ? Icons.work_outline_rounded : Icons.school_outlined,
              size: 48, color: _kBlue)),
          const SizedBox(height: 16),
          Text(
            isPro
                ? "Aucun encadrant professionnel"
                : "Aucun encadrant académique",
            style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.bold, color: _kDark)),
          const SizedBox(height: 8),
          Text(
            isPro
                ? "Vous devez avoir une candidature acceptée."
                : "Vous devez être assigné à un encadrement.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _kSec, height: 1.5)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (_, i) => _contactCard(list[i], isPro: isPro),
    );
  }

  Widget _contactCard(Map<String, String> enc, {required bool isPro}) {
    final name  = enc['name']  ?? '';
    final email = enc['email'] ?? '';
    final photo = enc['photo'] ?? '';
    final sub   = isPro
        ? (enc['offre']?.isNotEmpty == true ? enc['offre']! : email)
        : (enc['specialite']?.isNotEmpty == true ? enc['specialite']! : email);
    final color = isPro ? _kBlue : _kGreen;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatPage(
          otherEmail: email,
          otherName:  name,
          otherPhoto: photo,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isPro
                    ? [_kDark, _kBlue]
                    : [const Color(0xFF065F46), _kGreen],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              backgroundImage: photo.isNotEmpty
                  ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                  : null,
              child: photo.isEmpty
                  ? Text(_initials(name),
                      style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kDark)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(
                  isPro ? Icons.work_outline_rounded : Icons.school_outlined,
                  size: 12, color: _kSec),
                const SizedBox(width: 4),
                Expanded(child: Text(sub,
                  style: const TextStyle(fontSize: 12, color: _kSec),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ],
          )),

          // Bouton chat
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
            child: Icon(Icons.chat_bubble_outline_rounded,
              color: color, size: 18),
          ),
        ]),
      ),
    );
  }
}
