import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _kDark   = Color(0xFF0A1F44);
const Color _kBlue   = Color(0xFF1A3C8F);
const Color _kLight  = Color(0xFF4A72D4);
const Color _kBg     = Color(0xFFF5F7FF);
const Color _kCard   = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSec    = Color(0xFF64748B);
const Color _kGreen  = Color(0xFF059669);

class RapportDetailPage extends StatefulWidget {
  final Map rapport;
  const RapportDetailPage({super.key, required this.rapport});

  @override
  State<RapportDetailPage> createState() => _RapportDetailPageState();
}

class _RapportDetailPageState extends State<RapportDetailPage> {
  final ApiService api = ApiService();
  Map? rapportData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRapport();
  }

  Future<void> _loadRapport() async {
    try {
      final data = await api.getRapportById(widget.rapport["id"]);
      setState(() { rapportData = data; _loading = false; });
    } catch (e) {
      setState(() { rapportData = widget.rapport; _loading = false; });
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'final':        return 'Final';
      case 'hebdomadaire': return 'Hebdomadaire';
      case 'mi-stage':     return 'Mi-stage';
      default:             return type;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'final':        return const Color(0xFF7C3AED);
      case 'hebdomadaire': return const Color(0xFF0891B2);
      case 'mi-stage':     return const Color(0xFFF59E0B);
      default:             return _kBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'final':        return Icons.verified_rounded;
      case 'hebdomadaire': return Icons.calendar_month_rounded;
      case 'mi-stage':     return Icons.school_rounded;
      default:             return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kBlue)),
      );
    }

    final r           = rapportData ?? widget.rapport;
    final String titre = (r["title"] ?? r["titre"] ?? "Rapport").toString();
    final String type  = (r["type"] ?? "").toString();
    final String date  = (r["createdAt"] ?? "").toString();
    final String resume = (r["resume"] ?? "").toString();
    final String commentaire = (r["commentaire"] ?? r["comment"] ?? "").toString();
    final String pdfFile = (r["file"] ?? r["pdf"] ?? "").toString();

    // Encadrant
    final encadrant = r["encadrant"];
    final String encName  = (encadrant?["name"] ?? encadrant?["nom"] ?? "").toString();
    final String encEmail = (encadrant?["email"] ?? r["encadrant"] ?? "").toString();

    final String dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final typeColor = _typeColor(type);
    final typeIcon  = _typeIcon(type);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _kDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kDark, _kBlue, _kLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Badge type
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: typeColor.withOpacity(0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(typeIcon, size: 12, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(_typeLabel(type),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Text(titre,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.bold),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        if (dateStr.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.white70),
                            const SizedBox(width: 5),
                            Text(dateStr,
                              style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                          ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Encadrant ──────────────────────────────────────────
                  if (encName.isNotEmpty || encEmail.isNotEmpty) ...[
                    _sectionLabel("Encadrant académique",
                      Icons.school_outlined),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kBorder),
                        boxShadow: [BoxShadow(
                          color: _kBlue.withOpacity(0.05),
                          blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kBlue.withOpacity(0.08),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.person_outline_rounded,
                            color: _kBlue, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (encName.isNotEmpty)
                              Text(encName, style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold,
                                color: _kDark)),
                            if (encEmail.isNotEmpty)
                              Text(encEmail, style: const TextStyle(
                                fontSize: 12, color: _kSec)),
                          ],
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Résumé ─────────────────────────────────────────────
                  _sectionLabel("Résumé des travaux",
                    Icons.description_outlined),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                      boxShadow: [BoxShadow(
                        color: _kBlue.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Text(
                      resume.isNotEmpty ? resume : "Aucun résumé",
                      style: const TextStyle(
                        fontSize: 14, color: _kDark, height: 1.6)),
                  ),

                  const SizedBox(height: 20),

                  // ── Commentaire encadrant ──────────────────────────────
                  _sectionLabel("Commentaire de l'encadrant",
                    Icons.comment_outlined),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: commentaire.isNotEmpty
                          ? _kGreen.withOpacity(0.05)
                          : _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: commentaire.isNotEmpty
                            ? _kGreen.withOpacity(0.3)
                            : _kBorder),
                      boxShadow: [BoxShadow(
                        color: _kGreen.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          commentaire.isNotEmpty
                              ? Icons.check_circle_outline_rounded
                              : Icons.hourglass_empty_rounded,
                          color: commentaire.isNotEmpty
                              ? _kGreen : _kSec,
                          size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          commentaire.isNotEmpty
                              ? commentaire
                              : "En attente du commentaire de l'encadrant",
                          style: TextStyle(
                            fontSize: 14, height: 1.5,
                            color: commentaire.isNotEmpty
                                ? _kDark : _kSec,
                            fontStyle: commentaire.isEmpty
                                ? FontStyle.italic : FontStyle.normal))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Bouton PDF ─────────────────────────────────────────
                  if (pdfFile.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final url =
                            "${ApiService.baseUrl}/uploads/rapports/$pdfFile";
                          await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                        },
                        icon: const SizedBox.shrink(),
                        label: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text("Ouvrir le PDF",
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── Bouton retour ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                        color: _kSec, size: 18),
                      label: const Text("Retour",
                        style: TextStyle(color: _kSec,
                          fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _kBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 15, color: _kBlue)),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold, color: _kDark)),
    ]);
  }
}
