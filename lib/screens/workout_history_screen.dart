import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'main_navigation_screen.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  // Black + Gold + White + Gray palette (flat brand gold: no gradients)
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  String _selectedCategory = 'All';
  String _selectedMonth = 'All Months';
  final int _currentIndex = 3; // Naka-link sa Analytics tab

  final List<String> _categories = const [
    'All',
    'Gym',
    'Home (no equipment)',
    'Outdoor',
  ];

  // Listahan ng mga buwan para sa Filter
  final List<String> _months = const [
    'All Months',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool get _hasFilters =>
      _selectedCategory != 'All' || _selectedMonth != 'All Months';

  void _clearFilters() => setState(() {
    _selectedCategory = 'All';
    _selectedMonth = 'All Months';
  });

  // ───────────────────────── Helpers ─────────────────────────

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Home':
      case 'Home (no equipment)':
        return Icons.home_rounded;
      case 'Outdoor':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  /// Short chip label; the filter value itself stays unchanged.
  String _categoryLabel(String category) =>
      category == 'Home (no equipment)' ? 'Home' : category;

  int _intensityLevel(String intensity) {
    switch (intensity) {
      case 'Light':
      case 'Low':
        return 1;
      case 'High':
        return 3;
      default:
        return 2;
    }
  }

  int _parseMinutes(String durationStr) {
    final match = RegExp(r'(\d+)').firstMatch(durationStr);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  String _formatMinutes(int total) {
    if (total < 60) return '$total min';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  /// Real date of a workout document, or null when it has none.
  DateTime? _docDate(Map<String, dynamic> data) {
    if (data['timestamp'] is Timestamp) {
      return (data['timestamp'] as Timestamp).toDate();
    }
    if (data['date'] != null) {
      try {
        return DateFormat('MMM dd, yyyy').parse(data['date'].toString());
      } catch (_) {}
    }
    return null;
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leadingWidth: 68,
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Center(
                  child: Tooltip(
                    message: 'Back',
                    child: Material(
                      color: _card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: _border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.maybePop(context),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: const Text(
          'Workout History',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          _buildCategoryFilters(),
          const SizedBox(height: 10),
          _buildMonthFilterDropdown(),
          const SizedBox(height: 14),
          Expanded(
            child: user == null
                ? _buildEmptyState(
                    title: 'Not signed in',
                    message: 'Please log in to view workout history.',
                    icon: Icons.person_outline_rounded,
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('workouts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(includeMetadataChanges: true),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _gold),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(
                          title: 'No workouts yet',
                          message: 'No workouts logged yet.',
                        );
                      }

                      // I-filter ang mga nakuhang dokumento mula sa Firestore
                      final docs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category = data['category'] ?? 'Gym';

                        // Petsa para sa Month filter
                        final date = _docDate(data) ?? DateTime.now();
                        final monthName = DateFormat('MMMM').format(date);

                        final normalizedCategory =
                            category.toString().toLowerCase() == 'home'
                            ? 'home (no equipment)'
                            : category.toString().toLowerCase();
                        final matchCategory =
                            _selectedCategory == 'All' ||
                            normalizedCategory ==
                                _selectedCategory.toLowerCase();
                        final matchMonth =
                            _selectedMonth == 'All Months' ||
                            monthName.toLowerCase() ==
                                _selectedMonth.toLowerCase();

                        return matchCategory && matchMonth;
                      }).toList();

                      // Kuhanin ang Total Minutes
                      var totalMinutes = 0;
                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final durStr = data['duration']?.toString() ?? '0 min';
                        totalMinutes += _parseMinutes(durStr);
                      }

                      return Column(
                        children: [
                          _buildSummary(docs.length, totalMinutes),
                          const SizedBox(height: 6),
                          Expanded(
                            child: docs.isEmpty
                                ? _buildEmptyState(
                                    title: 'No matches',
                                    message: 'No workouts found for the selected filter.',
                                    icon: Icons.filter_alt_off_outlined,
                                    action: _hasFilters
                                        ? OutlinedButton.icon(
                                            onPressed: _clearFilters,
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Clear filters'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _goldBright,
                                              side: BorderSide(
                                                color: _gold.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              minimumSize: const Size(0, 44),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          )
                                        : null,
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      20,
                                    ),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final data =
                                          docs[index].data()
                                              as Map<String, dynamic>;
                                      final date = _docDate(data);

                                      // Month header whenever the month
                                      // changes (list is newest first).
                                      String? monthHeader;
                                      if (date != null) {
                                        final label = DateFormat('MMMM yyyy')
                                            .format(date);
                                        final prev = index == 0
                                            ? null
                                            : _docDate(
                                                docs[index - 1].data()
                                                    as Map<String, dynamic>,
                                              );
                                        final prevLabel = prev == null
                                            ? null
                                            : DateFormat('MMMM yyyy')
                                                  .format(prev);
                                        if (prevLabel != label) {
                                          monthHeader = label;
                                        }
                                      }

                                      // Format ng totoong petsa mula Firestore
                                      var formattedDate = 'Date unavailable';
                                      if (data['timestamp'] is Timestamp) {
                                        formattedDate =
                                            DateFormat('MMM dd, yyyy').format(
                                              (data['timestamp'] as Timestamp)
                                                  .toDate(),
                                            );
                                      } else if (data['date'] != null) {
                                        formattedDate = data['date'].toString();
                                      }

                                      final workoutMap = {
                                        // Done offline, not on the server yet.
                                        'pending': docs[index]
                                            .metadata
                                            .hasPendingWrites,
                                        'date': formattedDate,
                                        'dateValue': date,
                                        'title':
                                            data['title']?.toString() ??
                                            data['workoutName']?.toString() ??
                                            'Workout Session',
                                        'category':
                                            data['category']?.toString() ??
                                            'Gym',
                                        'duration':
                                            data['duration']?.toString() ??
                                            '45 min',
                                        'intensity':
                                            data['intensity']?.toString() ??
                                            'Moderate',
                                        'notes':
                                            data['notes']?.toString() ?? '',
                                        'exercises': data['exercises'] is List
                                            ? data['exercises'] as List
                                            : const <dynamic>[],
                                        'feedback':
                                            data['feedback']?.toString() ?? '',
                                      };

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (monthHeader != null)
                                            _buildMonthHeader(
                                              monthHeader,
                                              first: index == 0,
                                            ),
                                          _buildWorkoutCard(workoutMap),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────── Category Filters ─────────────────────────

  /// Scrollable row so "Home (no equipment)" never gets squeezed or wrapped
  /// on narrow phones (the old Row of four Expanded chips did).
  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _buildFilterChip(_categories[i]),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final bool isSelected = _selectedCategory == filter;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${_categoryLabel(filter)} workouts',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? _gold : _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isSelected ? _gold : _border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selectedCategory = filter),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (filter != 'All') ...[
                  Icon(
                    _categoryIcon(filter),
                    size: 16,
                    color: isSelected ? Colors.black : _gray,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  _categoryLabel(filter),
                  style: TextStyle(
                    color: isSelected ? Colors.black : _gray,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Month Filter Dropdown ─────────────────────────

  Widget _buildMonthFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedMonth == 'All Months'
                ? _border
                : _gold.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: _gold, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Month',
                style: TextStyle(
                  color: _gray,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth, // Inayos dito: 'value' gamit sa halip na 'initialValue'
                dropdownColor: _card,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _gold,
                ),
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
                items: _months.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMonth = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Summary ─────────────────────────

  /// Workouts + total time as one divided strip instead of two tiles.
  Widget _buildSummary(int count, int minutes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _summaryTile(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Workouts',
                  value: '$count',
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: _border),
              Expanded(
                child: _summaryTile(
                  icon: Icons.timer_outlined,
                  label: 'Total time',
                  value: _formatMinutes(minutes),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      color: _white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Workout List ─────────────────────────

  Widget _buildMonthHeader(String label, {required bool first}) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: first ? 4 : 14, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          color: _muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: _border, width: 1.2),
    );
    final DateTime? date = workout['dateValue'] as DateTime?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _card,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => _showDetailsModal(context, workout),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date block: day + weekday, easy to scan down the list.
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: date == null
                      ? Icon(
                          _categoryIcon(workout['category']!),
                          color: _gold,
                          size: 22,
                        )
                      : Column(
                          children: [
                            Text(
                              DateFormat('EEE').format(date).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _goldBright,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontSize: 19,
                                color: _white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workout['title']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: _white,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _muted,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workout['date']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (workout['pending'] == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 14,
                                color: _muted,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Saved on this phone • not synced yet',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip(
                            _categoryIcon(workout['category']!),
                            workout['category']!,
                          ),
                          _infoChip(Icons.timer_outlined, workout['duration']!),
                          _intensityChip(workout['intensity']!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _tile,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _gray),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: _gray,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _intensityChip(String intensity) {
    final int level = _intensityLevel(intensity);
    return Semantics(
      label: 'Intensity $intensity',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++)
              Icon(
                Icons.bolt_rounded,
                size: 13,
                color: i < level ? _goldBright : _gold.withValues(alpha: 0.25),
              ),
            const SizedBox(width: 4),
            Text(
              intensity,
              style: const TextStyle(
                fontSize: 12,
                color: _goldBright,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Empty State ─────────────────────────

  Widget _buildEmptyState({
    required String title,
    required String message,
    IconData icon = Icons.history_rounded,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.10),
              ),
              child: Icon(icon, color: _gold, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _gray,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action],
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Bottom Nav ─────────────────────────

  Widget _buildBottomNav() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigationScreen(initialIndex: index),
            ),
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _goldBright,
        unselectedItemColor: _muted,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Details Modal ─────────────────────────

  Widget _detailTile(IconData icon, String label, String value) {
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: _gold, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _gray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsModal(BuildContext context, Map<String, dynamic> workout) {
    final String notes = workout['notes'] ?? '';
    final exercises = (workout['exercises'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((exercise) => Map<String, dynamic>.from(exercise))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        // Height cap + scroll: a workout with many exercises used to
        // overflow the sheet. Close stays pinned at the bottom.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _categoryIcon(workout['category']!),
                              color: _gold,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workout['title']!,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _white,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  workout['date']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _goldBright,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Category / duration / intensity as one divided strip.
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _detailTile(
                                _categoryIcon(workout['category']!),
                                'Category',
                                workout['category']!,
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: _border,
                              ),
                              _detailTile(
                                Icons.timer_outlined,
                                'Duration',
                                workout['duration']!,
                              ),
                              const VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: _border,
                              ),
                              _detailTile(
                                Icons.bolt_rounded,
                                'Intensity',
                                workout['intensity']!,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (exercises.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text(
                          'EXERCISES · ${exercises.length}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            children: [
                              for (final (i, exercise)
                                  in exercises.indexed) ...[
                                if (i != 0)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _border,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 26,
                                        child: Text(
                                          (i + 1).toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise['name']?.toString() ??
                                                  'Exercise',
                                              style: TextStyle(
                                                color:
                                                    exercise['skipped'] == true
                                                    ? _gray
                                                    : _white,
                                                fontWeight: FontWeight.w800,
                                                decoration:
                                                    exercise['skipped'] == true
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                decorationColor: _gray,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${exercise['sets'] ?? 0} sets × ${exercise['reps'] ?? 0} reps'
                                              '${exercise['weight']?.toString().isNotEmpty == true ? ' • ${exercise['weight']} kg' : ''}'
                                              '${exercise['skipped'] == true ? ' • Skipped' : ''}',
                                              style: const TextStyle(
                                                color: _gray,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _gold,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Workout Completed Successfully',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: _white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if ((workout['feedback'] as String?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Workout feedback: ${workout['feedback']}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _goldBright,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: $notes',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _gray,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
