import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/chat_page.dart';
import 'package:frontend/screens/invitations.dart';
import 'package:frontend/screens/reunions.dart';
import '../services/api_service.dart';

// ── Palette bleu roi ──────────────────────────────────────────────────────────
const Color _kRoyalDark   = Color(0xFF0D1B4B);
const Color _kRoyal       = Color(0xFF1A3C8F);
const Color _kRoyalMid    = Color(0xFF2952B3);
const Color _kRoyalLight  = Color(0xFF4A72D4);
const Color _kBg          = Color(0xFFF0F4FF);
const Color _kCard        = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF0D1B4B);
const Color _kTextSec     = Color(0xFF6B7A99);
const Color _kDivider     = Color(0xFFE4EAF8);

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard>
    with SingleTickerProviderStateMixin {
  final api = ApiService();

  String name    = "";
  String company = "";
  String poste   = "";
  String email   = "";
  bool   _loaded = false;
  int    _unreadNotifs = 0;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadUser();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final n = await api.storage.read(key: "name")    ?? "";
    final c = await api.storage.read(key: "company") ?? "";
    final p = await api.storage.read(key: "role")    ?? "";
    final e = await api.storage.read(key: "email")   ?? "";
    setState(() { name = n; company = c; poste = p; email = e; _loaded = true; });
    _animCtrl.forward();
    _loadNotifCount();
  }

  Future<void> _loadNotifCount() async {
    try {
      final notifs = await api.getMyNotifications();
      final unread = notifs.where((n) => n['read'] == false).length;
      if (mounted) setState(() => _unreadNotifs = unread);
    } catch (_) {}
  }

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'EP';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  void _logout() async {
    await api.storage.deleteAll();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _kBg,
      body: _loaded
          ? FadeTransition(opacity: _fadeAnim, child: _buildBody())
          : const Center(child: CircularProgressIndicator(color: _kRoyal)),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 28),
                _buildSectionTitle('Navigation rapide'),
                const SizedBox(height: 14),
                _buildMenuGrid(),
                const SizedBox(height: 28),
                _buildSectionTitle('Informations'),
                const SizedBox(height: 14),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── SliverAppBar ─────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: _kRoyalDark,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
      leading: const SizedBox.shrink(),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
          tooltip: 'Mon profil',
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
          ),
          onPressed: _logout,
          tooltip: 'Déconnexion',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kRoyalDark, _kRoyal, _kRoyalMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(top: -30, right: -30,
                child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
              Positioned(bottom: -20, left: -20,
                child: Container(width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
              Positioned(top: 40, left: 100,
                child: Container(width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03)))),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 80, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Badge rôle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7DD3FC), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text("Encadrant Professionnel",
                            style: TextStyle(color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      // Greeting
                      Text("$_greeting,",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14, fontWeight: FontWeight.w400)),
                      const SizedBox(height: 2),
                      Text(name.isNotEmpty ? name : "Encadrant",
                        style: const TextStyle(color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        maxLines: 1, overflow: TextOverflow.ellipsis),                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.business_rounded, size: 13,
                            color: Color(0xFF93C5FD)),
                          const SizedBox(width: 5),
                          Text(company,
                            style: const TextStyle(color: Color(0xFF93C5FD),
                              fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(color: _kRoyal.withValues(alpha: 0.08),
            blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(children: [
        // Avatar with gradient ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_kRoyal, _kRoyalLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF0D1B4B),
            child: Text(
              _initials,
              style: const TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.isNotEmpty ? name : "Encadrant",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                color: _kTextPrimary)),
            const SizedBox(height: 4),
            if (email.isNotEmpty)
              Row(children: [
                const Icon(Icons.email_outlined, size: 13, color: _kTextSec),
                const SizedBox(width: 5),
                Expanded(child: Text(email,
                  style: const TextStyle(fontSize: 12, color: _kTextSec),
                  overflow: TextOverflow.ellipsis)),
              ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kRoyal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kRoyal.withValues(alpha: 0.2)),
              ),
              child: Text("Encadrant Professionnel",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: _kRoyal)),
            ),
          ],
        )),
        // Edit profile button
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
            ),
            child: const Icon(Icons.edit_outlined, color: _kRoyal, size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(width: 4, height: 18,
        decoration: BoxDecoration(
          color: _kRoyal,
          borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.bold,
        color: _kTextPrimary, letterSpacing: 0.2)),
    ]);
  }

  // ── Menu grid ─────────────────────────────────────────────────────────────────
  List<_MenuItem> get _menuItems => [
    const _MenuItem(Icons.groups_rounded,         "Stagiaires",     Color(0xFF0D1B4B), Color(0xFFE8EEFF), '/stagiaires',  null),
    const _MenuItem(Icons.task_alt_rounded,       "Tâches",         Color(0xFF1A3C8F), Color(0xFFEEF2FF), '/taches',      null),
    const _MenuItem(Icons.calendar_month_rounded, "Réunions",       Color(0xFF2952B3), Color(0xFFF0F4FF), null,           'reunions'),
    const _MenuItem(Icons.mark_email_read_rounded,"Invitations",    Color(0xFF4A72D4), Color(0xFFF4F7FF), null,           'invitations'),
    const _MenuItem(Icons.chat_bubble_outline_rounded, "Conversations", Color(0xFF059669), Color(0xFFECFDF5), null,       'conversations'),
  ];

  Widget _buildMenuGrid() {
    final items = _menuItems;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: items.map((item) => _buildMenuCard(item)).toList(),
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    final isInvitations = item.special == 'invitations';
    return GestureDetector(
      onTap: () {
        if (item.route != null) {
          Navigator.pushNamed(context, item.route!);
        } else if (item.special == 'reunions') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReunionsPage()));
        } else if (item.special == 'invitations') {
          setState(() => _unreadNotifs = 0);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsPage()))
              .then((_) => _loadNotifCount());
        } else if (item.special == 'conversations') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const ProConversationsPage()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(color: item.color.withValues(alpha: 0.1),
              blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(children: [
          // Background decoration
          Positioned(right: -10, bottom: -10,
            child: Container(width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha: 0.06)))),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: item.color.withValues(alpha: 0.15)),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    // Badge rouge si invitations non lues
                    if (isInvitations && _unreadNotifs > 0)
                      Positioned(
                        top: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            _unreadNotifs > 9 ? '9+' : '$_unreadNotifs',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: item.color)),
                    Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: item.color.withValues(alpha: 0.5)),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRoyalDark, _kRoyal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kRoyalDark.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            const Text("Votre espace",
              style: TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _infoRow(Icons.groups_rounded, "Gérez vos stagiaires et suivez leur progression"),
          const SizedBox(height: 10),
          _infoRow(Icons.task_alt_rounded, "Évaluez les tâches soumises via le tableau Kanban"),
          const SizedBox(height: 10),
          _infoRow(Icons.calendar_month_rounded, "Planifiez des réunions avec vos stagiaires"),
          const SizedBox(height: 10),
          _infoRow(Icons.mark_email_read_rounded, "Consultez vos invitations aux offres de stage"),
          const SizedBox(height: 10),
          _infoRow(Icons.chat_bubble_outline_rounded, "Échangez directement avec vos stagiaires"),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFF93C5FD), size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12, height: 1.4))),
    ]);
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String   title;
  final Color    color;
  final Color    bg;
  final String?  route;
  final String?  special;
  const _MenuItem(this.icon, this.title, this.color, this.bg, this.route, this.special);
}

// ── Page Conversations (stagiaires) ──────────────────────────────────────────
class ProConversationsPage extends StatefulWidget {
  const ProConversationsPage({super.key});
  @override
  State<ProConversationsPage> createState() => _ProConversationsPageState();
}

class _ProConversationsPageState extends State<ProConversationsPage> {
  final api = ApiService();
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
      final data = await api.getStagiairesForEncadrantPro();
      // Dédupliquer par email
      final seen = <String>{};
      final unique = <dynamic>[];
      for (var s in data) {
        final email = (s['studentEmail'] ?? '').toString().toLowerCase();
        if (email.isNotEmpty && !seen.contains(email)) {
          seen.add(email);
          unique.add(s);
        }
      }
      if (mounted) setState(() { _stagiaires = unique; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List get _filtered {
    if (_search.isEmpty) return _stagiaires;
    final q = _search.toLowerCase();
    return _stagiaires.where((s) {
      final name  = (s['studentName'] ?? '').toString().toLowerCase();
      final email = (s['studentEmail'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Conversations",
              style: TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.bold)),
            Text("${_filtered.length} stagiaire${_filtered.length != 1 ? 's' : ''}",
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _load),
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
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Rechercher un stagiaire...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.6), size: 18),
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
              child: _filtered.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kRoyal.withOpacity(0.08),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: _kRoyal)),
                        const SizedBox(height: 16),
                        const Text("Aucun stagiaire",
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold, color: _kRoyalDark)),
                        const SizedBox(height: 8),
                        const Text(
                          "Vos stagiaires acceptés\napparaîtront ici.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13,
                            color: _kTextSec, height: 1.5)),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        final name  = (s['studentName'] ?? 'Étudiant').toString();
                        final email = (s['studentEmail'] ?? '').toString();
                        final photo = (s['studentPhoto'] ?? '').toString();
                        final status = (s['status'] ?? 'accepted').toString();

                        Color statusColor;
                        String statusLabel;
                        switch (status.toLowerCase()) {
                          case 'accepted':          statusColor = const Color(0xFF059669); statusLabel = 'Accepté'; break;
                          case 'signed_by_company': statusColor = _kRoyal;                statusLabel = 'Signé'; break;
                          case 'fully_signed':      statusColor = const Color(0xFF0891B2); statusLabel = 'Validé'; break;
                          default:                  statusColor = _kTextSec;              statusLabel = status;
                        }

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
                              border: Border.all(color: _kDivider),
                              boxShadow: [BoxShadow(
                                color: _kRoyal.withOpacity(0.06),
                                blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Row(children: [
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [_kRoyalDark, _kRoyal],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                  boxShadow: [BoxShadow(
                                    color: _kRoyal.withOpacity(0.25),
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
                                    fontSize: 14, fontWeight: FontWeight.bold,
                                    color: _kRoyalDark)),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    const Icon(Icons.email_outlined,
                                      size: 12, color: _kTextSec),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(email,
                                      style: const TextStyle(
                                        fontSize: 12, color: _kTextSec),
                                      overflow: TextOverflow.ellipsis)),
                                  ]),
                                ],
                              )),
                              const SizedBox(width: 8),
                              // Badge statut
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3))),
                                child: Text(statusLabel,
                                  style: TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor)),
                              ),
                              const SizedBox(width: 8),
                              // Icône chat
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF059669).withOpacity(0.2))),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF059669), size: 16),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
