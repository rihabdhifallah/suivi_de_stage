import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreerReunionPage extends StatefulWidget {
  const CreerReunionPage({super.key});

  @override
  State<CreerReunionPage> createState() => _CreerReunionPageState();
}

class _CreerReunionPageState extends State<CreerReunionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _lienController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedPlatform;

  List<Map<String, dynamic>> _allStagiaires = [];
  bool _isLoadingStagiaires = true;
  bool _isSubmitting = false;
  String _userRole = '';
  // ignore: unused_field
  final List<Map<String, dynamic>> _selectedStagiaires = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      final profile = await ApiService().getProfile();
      setState(() {
        _userRole = profile['role'] ?? '';
      });

      if (_userRole == 'student') {
        await _fetchSupervisors();
      } else {
        await _fetchStagiaires();
      }
    } catch (e) {
      debugPrint("Error initializing page: $e");
      setState(() {
        _isLoadingStagiaires = false;
      });
    }
  }

  Future<void> _fetchSupervisors() async {
    setState(() {
      _isLoadingStagiaires = true;
      _allStagiaires = [];
    });

    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
    ];

    List<Map<String, dynamic>> supervisors = [];

    // 1. Fetch Academic Supervisor
    try {
      final encadrements = await ApiService().getStudentEncadrements();
      if (encadrements is List && encadrements.isNotEmpty) {
        final e = encadrements[0]; // Take current active encadrement
        final enc = e['encadrant'];
        if (enc != null) {
          final name = "${enc['name'] ?? ''} ${enc['prenom'] ?? ''}".trim();
          final email = (enc['email'] ?? '').toString().trim();
          if (email.isNotEmpty) {
            supervisors.add({
              'name': name.isNotEmpty ? name : email,
              'email': email,
              'avatar': name.isNotEmpty ? name[0].toUpperCase() : 'A',
              'color': colors[0],
              'type': 'academic',
              'photo': (enc['photo'] ?? '').toString(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching academic supervisor: $e");
    }

    // 2. Fetch Professional Supervisor
    try {
      final applications = await ApiService().getMyApplications();
      if (applications is List) {
        for (var app in applications) {
          final statusRaw = (app["status"] ?? "").toString().toLowerCase();
          if (statusRaw == "accepted" || statusRaw.contains("signed")) {
            final stage = app["stage"] ?? app["offre"] ?? {};
            final invitations = stage["invitations"];
            if (invitations is List && invitations.isNotEmpty) {
              final encadrant = invitations[0]["encadrant"];
              if (encadrant != null) {
                final String name = (encadrant["nomComplet"] ?? "").toString().trim();
                final String email = (encadrant["email"] ?? "").toString().trim();
                if (email.isNotEmpty) {
                  supervisors.add({
                    'name': name.isNotEmpty ? name : email,
                    'email': email,
                    'avatar': name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    'color': colors[1],
                    'type': 'pro',
                    'photo': '', 
                  });
                  break; 
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching professional supervisor: $e");
    }

    setState(() {
      _allStagiaires = supervisors;
      _isLoadingStagiaires = false;
    });
  }

  Future<void> _fetchStagiaires() async {
    try {
      final data = await ApiService().getStagiairesForEncadrantPro();
      final List<Map<String, dynamic>> loaded = [];
      final colors = [
        const Color(0xFF6366F1),
        const Color(0xFFEC4899),
        const Color(0xFF10B981),
        const Color(0xFFF59E0B),
        const Color(0xFF06B6D4),
        const Color(0xFF8B5CF6)
      ];

      for (int i = 0; i < data.length; i++) {
        final s = data[i];
        final name  = (s['studentName'] ?? '').toString().trim();
        final email = (s['studentEmail'] ?? '').toString().trim();
        if (email.isEmpty) continue;
        final firstChar = name.isNotEmpty ? name[0].toUpperCase() : 'E';
        final color = colors[i % colors.length];

        // Dédupliquer par email
        if (!loaded.any((item) => item['email'] == email)) {
          loaded.add({
            'name':   name.isNotEmpty ? name : email,
            'email':  email,
            'avatar': firstChar,
            'color':  color,
            'photo':  (s['studentPhoto'] ?? '').toString(),
          });
        }
      }

      setState(() {
        _allStagiaires = loaded;
        _isLoadingStagiaires = false;
      });
    } catch (e) {
      debugPrint("Error loading stagiaires pro: $e");
      setState(() => _isLoadingStagiaires = false);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _lienController.dispose();
    super.dispose();
  }

  // ── Date Picker ──
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

  // ── Time Picker ──
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
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
        _selectedTime = picked;
      });
    }
  }

  // ── Format Helper ──
  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(TimeOfDay tod) {
    return "${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}";
  }

  // ── Beautiful Custom SnackBar ──
  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Open Guests Selector Modal ──
  void _openStagiairesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(
                          _userRole == 'student' ? Icons.supervisor_account_rounded : Icons.people_outline_rounded,
                          color: const Color(0xFF0E7490),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _userRole == 'student' ? "Inviter des Encadrants" : "Inviter des Stagiaires",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _userRole == 'student'
                          ? "Sélectionnez les encadrants à inviter à cette réunion."
                          : "Sélectionnez les membres à inviter à cette réunion.",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: _isLoadingStagiaires
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0E7490),
                            ),
                          )
                        : _allStagiaires.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _userRole == 'student' ? Icons.supervisor_account_rounded : Icons.people_outline_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _userRole == 'student' ? "Aucun encadrant à inviter" : "Aucun étudiant à inviter",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        _userRole == 'student'
                                            ? "Vous n'avez pas encore d'encadrant académique ou professionnel assigné."
                                            : "Vous n'avez pas encore d'étudiants assignés dans vos encadrements.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _allStagiaires.length,
                                itemBuilder: (context, index) {
                        final s = _allStagiaires[index];
                        final bool isSelected = _selectedStagiaires.any((item) => item['email'] == s['email']);
                        final String photoUrl = (s['photo'] ?? '').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CheckboxListTile(
                            activeColor: const Color(0xFF0E7490),
                            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            secondary: CircleAvatar(
                              backgroundColor: s['color'] as Color,
                              radius: 20,
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage("${ApiService.baseUrl}/uploads/$photoUrl")
                                  : null,
                              child: photoUrl.isEmpty
                                  ? Text(
                                      s['avatar'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              s['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: const Color(0xFF0A1F44),
                              ),
                            ),
                            subtitle: Text(
                              _userRole == 'student'
                                  ? "${s['email']} • ${s['type'] == 'academic' ? 'Encadrant Académique' : 'Encadrant Professionnel'}"
                                  : s['email'] as String,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            value: isSelected,
                            onChanged: (bool? val) {
                              setModalState(() {
                                if (val == true) {
                                  _selectedStagiaires.add(s);
                                } else {
                                  _selectedStagiaires.removeWhere((item) => item['email'] == s['email']);
                                }
                              });
                              setState(() {});
                            },
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E7490),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Terminer la sélection", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Show Success Dialog and Pop ──
  void _showSuccessDialog(Map<String, dynamic> newReunion) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Succès",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Réunion Planifiée !",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Votre réunion \"${newReunion['titre']}\" a été créée avec succès et ajoutée à votre agenda.",
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Pop success dialog
                        Navigator.pop(context);
                        // Pop CreerReunionPage and return the new meeting
                        Navigator.pop(context, newReunion);
                      },
                      child: const Text(
                        "Super !",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  // ── Creation Logic & Validation ──
  void _submitForm() {
    if (_titreController.text.trim().isEmpty) {
      _showWarningSnackBar("Veuillez saisir un titre pour la réunion.");
      return;
    }
    if (_selectedPlatform == null) {
      _showWarningSnackBar("Veuillez sélectionner une plateforme (Teams, Meet, Zoom).");
      return;
    }
    if (_selectedDate == null) {
      _showWarningSnackBar("Veuillez choisir une date pour la réunion.");
      return;
    }
    if (_selectedTime == null) {
      _showWarningSnackBar("Veuillez choisir une heure pour la réunion.");
      return;
    }
    if (_lienController.text.trim().isEmpty) {
      _showWarningSnackBar("Veuillez saisir le lien de la réunion.");
      return;
    }

    // Standard link validation regex
    final String urlText = _lienController.text.trim();
    if (!urlText.startsWith("http://") && !urlText.startsWith("https://")) {
      _showWarningSnackBar("Le lien de la réunion doit commencer par http:// ou https://");
      return;
    }

    final newReunion = {
      'titre': _titreController.text.trim(),
      'date': _formatDate(_selectedDate!),
      'heure': _formatTime(_selectedTime!),
      'plateforme': _selectedPlatform,
      'lien': urlText,
      'participantEmails': _selectedStagiaires.map((s) => s['email']).toList(),
    };

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    ApiService().createReunion(newReunion).then((created) {
      setState(() {
        _isSubmitting = false;
      });
      _showSuccessDialog(created);
    }).catchError((err) {
      setState(() {
        _isSubmitting = false;
      });
      _showWarningSnackBar("Erreur lors de la création de la réunion: $err");
    });
  }

  // ── Platform Select Card Widget ──
  Widget _platformCard(String name, IconData icon, Color activeColor, Color activeBg, Color inactiveBg) {
    final bool isSelected = _selectedPlatform == name;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlatform = name;
            final uniqueId = DateTime.now().millisecondsSinceEpoch;
            if (name == 'Meet') {
              _lienController.text = "https://meet.jit.si/suivi-de-stage-$uniqueId";
            } else if (name == 'Teams') {
              _lienController.text = "https://teams.live.com/meet/$uniqueId";
            } else if (name == 'Zoom') {
              _lienController.text = "https://zoom.us/j/$uniqueId";
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey.shade500,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF0A1F44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Planifier une Réunion",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Détails de la Session",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Configurez et invitez les participants en quelques clics.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // CARD 1: Info & Titre
                Container(
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
                        children: const [
                          Icon(Icons.edit_note_rounded, color: Color(0xFF0E7490)),
                          SizedBox(width: 8),
                          Text(
                            "Objet de la réunion",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A1F44)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titreController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "Saisir le titre (ex: Bilan de mi-parcours)",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.title_rounded, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF0E7490), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CARD 2: Plateforme
                Container(
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
                        children: const [
                          Icon(Icons.video_chat_rounded, color: Color(0xFF0E7490)),
                          SizedBox(width: 8),
                          Text(
                            "Plateforme de visioconférence",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A1F44)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _platformCard(
                            "Teams",
                            Icons.groups_rounded,
                            const Color(0xFF5B5EA6),
                            const Color(0xFFEFF0FF),
                            const Color(0xFFF8FAFC),
                          ),
                          const SizedBox(width: 10),
                          _platformCard(
                            "Meet",
                            Icons.video_call_rounded,
                            const Color(0xFF16A34A),
                            const Color(0xFFF0FDF4),
                            const Color(0xFFF8FAFC),
                          ),
                          const SizedBox(width: 10),
                          _platformCard(
                            "Zoom",
                            Icons.video_camera_front_rounded,
                            const Color(0xFF2563EB),
                            const Color(0xFFEFF6FF),
                            const Color(0xFFF8FAFC),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CARD 3: Date & Heure
                Container(
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
                        children: const [
                          Icon(Icons.calendar_month_rounded, color: Color(0xFF0E7490)),
                          SizedBox(width: 8),
                          Text(
                            "Date & Horaire",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A1F44)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Date picker card button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedDate != null ? const Color(0xFF0E7490) : Colors.transparent,
                                    width: _selectedDate != null ? 1 : 0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.today_rounded,
                                      color: _selectedDate != null ? const Color(0xFF0E7490) : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedDate != null ? _formatDate(_selectedDate!) : "Choisir date",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                                          color: _selectedDate != null ? const Color(0xFF0A1F44) : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Time picker card button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedTime != null ? const Color(0xFF0E7490) : Colors.transparent,
                                    width: _selectedTime != null ? 1 : 0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: _selectedTime != null ? const Color(0xFF0E7490) : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedTime != null ? _formatTime(_selectedTime!) : "Choisir heure",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _selectedTime != null ? FontWeight.bold : FontWeight.normal,
                                          color: _selectedTime != null ? const Color(0xFF0A1F44) : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CARD 4: Lien
                Container(
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
                        children: const [
                          Icon(Icons.link_rounded, color: Color(0xFF0E7490)),
                          SizedBox(width: 8),
                          Text(
                            "Lien de la réunion",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A1F44)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedPlatform == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0E7490).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: const Color(0xFF0E7490).withOpacity(0.7), size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "Choisissez une plateforme ci-dessus pour générer le lien automatiquement.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0E7490),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _lienController.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A1F44),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Auto",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CARD 5: Participants
                Container(
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
                          Icon(
                            _userRole == 'student' ? Icons.supervisor_account_rounded : Icons.people_outline_rounded,
                            color: const Color(0xFF0E7490),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _userRole == 'student' ? "Encadrants invités" : "Stagiaires invités",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A1F44)),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _openStagiairesModal,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0E7490)),
                            label: const Text(
                              "Gérer",
                              style: TextStyle(fontSize: 13, color: Color(0xFF0E7490), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _selectedStagiaires.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade400),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _userRole == 'student'
                                          ? "Aucun encadrant invité pour l'instant."
                                          : "Aucun stagiaire invité pour l'instant.",
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedStagiaires.map((s) {
                                return Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: s['color'] as Color,
                                    child: Text(
                                      s['avatar'] as String,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  label: Text(
                                    s['name'] as String,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A1F44)),
                                  ),
                                  deleteIcon: const Icon(Icons.cancel_rounded, size: 16, color: Colors.grey),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedStagiaires.removeWhere((item) => item['name'] == s['name']);
                                    });
                                  },
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Button submit
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _submitForm,
                    icon: const SizedBox.shrink(), // Dummy icon to let container decoration handle visuals
                    label: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0E7490), Color(0xFF0891B2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _isSubmitting ? "Création..." : "Créer la Réunion",
                              style: const TextStyle(
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
}