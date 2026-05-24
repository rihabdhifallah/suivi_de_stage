import 'package:flutter/material.dart';
import 'package:frontend/screens/creer_reunion.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ReunionsPage extends StatefulWidget {
  const ReunionsPage({super.key});

  @override
  State<ReunionsPage> createState() => _ReunionsPageState();
}

class _ReunionsPageState extends State<ReunionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _reunions = [];
  bool _isLoading = true;
  String _userRole = "";

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<String> _frenchMonths = [
    "", "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
  ];
  final List<String> _weekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];

  int _daysInMonth(DateTime date) {
    var firstDayNextMonth = DateTime(date.year, date.month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  int _firstWeekdayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday; // 1 = Monday, 7 = Sunday
  }

  List<Map<String, dynamic>> meetingsForDay(DateTime date) {
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _reunions.where((r) => r['date'] == dateKey).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReunions();
  }

  Future<void> _loadReunions() async {
    try {
      final profile = await ApiService().getProfile();
      setState(() {
        _userRole = profile['role'] ?? '';
      });

      final list = await ApiService().getReunions();
      setState(() {
        _reunions = List<Map<String, dynamic>>.from(list);
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading reunions: $e");
      setState(() {
        _isLoading = false;
        _reunions = [];
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Platform icon & color ──
  Map<String, dynamic> _platformInfo(String p) {
    switch (p.toLowerCase()) {
      case 'teams':
        return {'icon': Icons.groups_rounded, 'color': const Color(0xFF5B5EA6), 'bg': const Color(0xFFEFF0FF)};
      case 'zoom':
        return {'icon': Icons.video_camera_front_rounded, 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFEFF6FF)};
      case 'meet':
        return {'icon': Icons.video_call_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFF0FDF4)};
      default:
        return {'icon': Icons.videocam_rounded, 'color': const Color(0xFF64748B), 'bg': const Color(0xFFF1F5F9)};
    }
  }

  Widget _reunionCard(Map<String, dynamic> r) {
    final info = _platformInfo(r['plateforme'] ?? '');
    final bool isUpcoming = r['statut'] == 'planifiee';
    final String meetingLink = (r['lien'] ?? '').toString();

    // Detect creator name
    final creator = r['creator'];
    String creatorName = '';
    if (creator != null) {
      final String nom = (creator['name'] ?? creator['nom'] ?? '').toString().trim();
      final String prenom = (creator['prenom'] ?? '').toString().trim();
      creatorName = '$nom $prenom'.trim();
      if (creatorName.isEmpty) creatorName = (creator['email'] ?? '').toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top color bar — violet gradient
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: isUpcoming
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade200],
                    ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + platform badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r['titre'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: info['bg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (info['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info['icon'] as IconData, size: 13, color: info['color'] as Color),
                          const SizedBox(width: 4),
                          Text(
                            r['plateforme'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: info['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Creator label
                if (creatorName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Envoyée par  ',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                      Text(
                        creatorName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Date & heure
                Row(
                  children: [
                    _infoChip(Icons.calendar_today_rounded, r['date'] ?? '', const Color(0xFF64748B)),
                    const SizedBox(width: 10),
                    _infoChip(Icons.access_time_rounded, r['heure'] ?? '', const Color(0xFF64748B)),
                  ],
                ),

                const SizedBox(height: 12),

                // Status + Join button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUpcoming ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUpcoming ? Icons.schedule_rounded : Icons.check_circle_rounded,
                            size: 12,
                            color: isUpcoming ? const Color(0xFF7C3AED) : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUpcoming ? 'Planifiée' : 'Passée',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isUpcoming ? const Color(0xFF7C3AED) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isUpcoming && meetingLink.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.tryParse(meetingLink);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.launch_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Rejoindre",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _emptyState(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0891B2).withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_rounded, size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune réunion $label",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Les réunions apparaîtront ici.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _reunions.where((r) => r['statut'] == 'planifiee').toList();
    final past = _reunions.where((r) => r['statut'] == 'passee').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF7C3AED)],
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
          "Mes Réunions",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: "Planifiées (${upcoming.length})"),
            Tab(text: "Passées (${past.length})"),
            const Tab(text: "Calendrier"),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreerReunionPage()),
                );
                if (result != null && result is Map<String, dynamic>) {
                  _loadReunions();
                }
              },
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Nouvelle réunion", style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0891B2),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Planifiées
                upcoming.isEmpty
                    ? _emptyState("planifiée")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: upcoming.length,
                        itemBuilder: (_, i) => _reunionCard(upcoming[i]),
                      ),

                // Passées
                past.isEmpty
                    ? _emptyState("passée")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: past.length,
                        itemBuilder: (_, i) => _reunionCard(past[i]),
                      ),

                // Calendrier
                _buildCalendarTab(),
              ],
            ),
    );
  }

  Widget _buildCalendarTab() {
    final int year = _focusedMonth.year;
    final int month = _focusedMonth.month;

    // Days in current month
    final int totalDays = _daysInMonth(_focusedMonth);
    // First weekday of month
    final int firstWeekday = _firstWeekdayOfMonth(_focusedMonth);
    final int offset = firstWeekday - 1; // 1=Mon => 0 offset, 7=Sun => 6 offset

    // Days in previous month
    final prevMonthDate = DateTime(year, month - 1, 1);
    final int prevTotalDays = _daysInMonth(prevMonthDate);

    // Total cells in calendar grid to always make it 6 rows (42 cells)
    const int totalCells = 42;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header: Month, Year and Chevrons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(year, month - 1, 1);
                          });
                        },
                        icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0E7490)),
                      ),
                      Text(
                        "${_frenchMonths[month]} $year",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F44),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(year, month + 1, 1);
                          });
                        },
                        icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0E7490)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekday labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekDays.map((day) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Grid of days
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      int dayNumber;
                      bool isCurrentMonth = true;
                      DateTime dateVal;

                      if (index < offset) {
                        // Previous month day
                        dayNumber = prevTotalDays - offset + index + 1;
                        isCurrentMonth = false;
                        dateVal = DateTime(year, month - 1, dayNumber);
                      } else if (index < offset + totalDays) {
                        // Current month day
                        dayNumber = index - offset + 1;
                        dateVal = DateTime(year, month, dayNumber);
                      } else {
                        // Next month day
                        dayNumber = index - (offset + totalDays) + 1;
                        isCurrentMonth = false;
                        dateVal = DateTime(year, month + 1, dayNumber);
                      }

                      final bool isSelected = _selectedDay.year == dateVal.year &&
                          _selectedDay.month == dateVal.month &&
                          _selectedDay.day == dateVal.day;

                      final bool isToday = DateTime.now().year == dateVal.year &&
                          DateTime.now().month == dateVal.month &&
                          DateTime.now().day == dateVal.day;

                      final dayMeetings = meetingsForDay(dateVal);
                      final bool hasMeetings = dayMeetings.isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDay = dateVal;
                            // Also adjust focused month if selecting outside
                            if (dateVal.month != _focusedMonth.month) {
                              _focusedMonth = DateTime(dateVal.year, dateVal.month, 1);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF0E7490)
                                : isToday
                                    ? const Color(0xFFECFDF5)
                                    : Colors.transparent,
                            border: isToday && !isSelected
                                ? Border.all(color: const Color(0xFF10B981), width: 1)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : !isCurrentMonth
                                          ? Colors.grey.shade300
                                          : isToday
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF0A1F44),
                                ),
                              ),
                              if (hasMeetings) ...[
                                const SizedBox(height: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.white : const Color(0xFFEC4899),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Meetings list header for selected day
            Row(
              children: [
                const Icon(Icons.event_note_rounded, color: Color(0xFF0E7490), size: 20),
                const SizedBox(width: 8),
                Text(
                  "Réunions du ${_selectedDay.day} ${_frenchMonths[_selectedDay.month]} ${_selectedDay.year}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meetings list or Empty State
            ..._buildSelectedDayMeetingsList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectedDayMeetingsList() {
    final dayMeetings = meetingsForDay(_selectedDay);

    if (dayMeetings.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                "Aucune réunion planifiée",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Profitez de votre journée !",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return dayMeetings.map((r) => _reunionCard(r)).toList();
  }
}