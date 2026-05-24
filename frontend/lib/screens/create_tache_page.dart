import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class CreateTachePage extends StatefulWidget {
  const CreateTachePage({super.key});

  @override
  State<CreateTachePage> createState() => _CreateTachePageState();
}

class _CreateTachePageState extends State<CreateTachePage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  Map<String, String>? _selectedTutor;
  List<Map<String, String>> _tutors = [];
  bool _isLoadingTutors = true;
  String _studentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadStudentEmailAndTutors();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Charge l'email de l'étudiant puis récupère les encadrants professionnels
  /// liés à ses demandes acceptées (via offre → invitations → encadrant).
  Future<void> _loadStudentEmailAndTutors() async {
    try {
      final email = await _api.storage.read(key: "email") ?? '';
      setState(() {
        _studentEmail = email;
      });

      // Récupérer les candidatures de l'étudiant
      final List applications = await _api.getMyApplications();

      final Set<String> seenEmails = {};
      final List<Map<String, String>> loadedTutors = [];

      for (var app in applications) {
        // On prend seulement les demandes acceptées ou signées
        final status = (app["status"] ?? "").toString().toLowerCase();
        if (status != "accepted" &&
            status != "signed_by_company" &&
            status != "fully_signed") {
          continue;
        }

        // Chercher l'encadrant professionnel dans offre.invitations
        final stage = app["stage"] ?? app["offre"] ?? {};
        final invitations = stage["invitations"];
        if (invitations is List && invitations.isNotEmpty) {
          for (var inv in invitations) {
            final encadrant = inv["encadrant"];
            if (encadrant != null) {
              final encEmail =
                  (encadrant["email"] ?? "").toString().trim().toLowerCase();
              final encName =
                  (encadrant["nomComplet"] ?? encadrant["name"] ?? "")
                      .toString()
                      .trim();
              if (encEmail.isNotEmpty && !seenEmails.contains(encEmail)) {
                seenEmails.add(encEmail);
                loadedTutors.add({
                  'name': encName.isNotEmpty ? encName : encEmail,
                  'email': encEmail,
                  'offreTitre': (stage["titre"] ?? "").toString(),
                });
              }
            }
          }
        }
      }

      setState(() {
        _tutors = loadedTutors;
        _isLoadingTutors = false;
      });
    } catch (e) {
      debugPrint("Error fetching tutors from applications: $e");
      setState(() {
        _tutors = [];
        _isLoadingTutors = false;
      });
    }
  }

  // ── Date Picker ──
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0E7490),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0A1F44),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Succès",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFA7F3D0), width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Tâche Soumise !",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Votre tâche \"${_titleController.text.trim()}\" a bien été enregistrée et envoyée à votre encadrant professionnel pour suivi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E7490),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      child: const Text("Fermer",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_titleController.text.trim().isEmpty) {
      _showWarningSnackBar("Veuillez donner un titre à votre tâche.");
      return;
    }
    if (_selectedTutor == null) {
      _showWarningSnackBar("Veuillez sélectionner l'encadrant destinataire.");
      return;
    }
    if (_selectedDate == null) {
      _showWarningSnackBar("Veuillez choisir une date d'échéance.");
      return;
    }

    final Map<String, dynamic> payload = {
      'titre': _titleController.text.trim(),
      'sender': _studentEmail,
      'receiver': _selectedTutor!['email'],
      'status': 'en attente',
      'fac_name': _formatDate(_selectedDate!),
      'message': _descController.text.trim(),
    };

    setState(() {
      _isLoadingTutors = true;
    });

    try {
      await _api.createTask(payload);
      _showSuccessDialog();
    } catch (e) {
      debugPrint("Error creating task: $e");
      _showWarningSnackBar(
          "Une erreur est survenue lors de la création de la tâche.");
      setState(() {
        _isLoadingTutors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1F44), Color(0xFF0E7490)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Créer une Tâche",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingTutors
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF0E7490)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Nouvelle Tâche de Stage",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F44),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Renseignez les détails pour informer votre encadrant professionnel de vos activités.",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // ── CARD 1 : Titre & Description ──
                      _buildCard(
                        icon: Icons.assignment_outlined,
                        title: "Détails de la tâche",
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText:
                                    "Objet (ex: Finalisation du dashboard)",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.title_rounded,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF0E7490), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descController,
                              maxLines: 4,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText:
                                    "Décrivez brièvement les travaux réalisés...",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF0E7490), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── CARD 2 : Encadrant professionnel ──
                      _buildCard(
                        icon: Icons.assignment_ind_outlined,
                        title: "Encadrant professionnel",
                        child: _tutors.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFED7AA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFF97316),
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Aucun encadrant professionnel trouvé. Vous devez avoir une demande acceptée avec un encadrant assigné.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : DropdownButtonFormField<Map<String, String>>(
                                value: _selectedTutor,
                                hint: Text(
                                  "Sélectionnez votre encadrant",
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13),
                                ),
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0A1F44)),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _tutors.map((t) {
                                  return DropdownMenuItem<Map<String, String>>(
                                    value: t,
                                    child: Text(
                                      (t['offreTitre'] ?? '').isNotEmpty
                                          ? "${t['name'] ?? ''} — ${t['offreTitre']}"
                                          : t['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0A1F44),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedTutor = val;
                                  });
                                },
                              ),
                      ),
                      const SizedBox(height: 20),

                      // ── CARD 3 : Date limite ──
                      _buildCard(
                        icon: Icons.today_rounded,
                        title: "Date limite / Échéance",
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? const Color(0xFF0E7490)
                                    : Colors.transparent,
                                width: _selectedDate != null ? 1 : 0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: _selectedDate != null
                                      ? const Color(0xFF0E7490)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? _formatDate(_selectedDate!)
                                        : "Choisir une date limite",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedDate != null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _selectedDate != null
                                          ? const Color(0xFF0A1F44)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Bouton Envoyer ──
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: _submitForm,
                          icon: const SizedBox.shrink(),
                          label: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0E7490),
                                  Color(0xFF0891B2)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Envoyer la Tâche",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0E7490)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0A1F44)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
