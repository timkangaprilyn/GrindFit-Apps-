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
  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  String _selectedCategory = 'All';
  String _selectedMonth = 'All Months';
  final int _currentIndex = 3; // Naka-link sa Analytics tab

  final List<String> _categories = const ['All', 'Gym', 'Home', 'Outdoor'];
  
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
    'December'
  ];

  // ───────────────────────── Helpers ─────────────────────────

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Home':
        return Icons.home_rounded;
      case 'Outdoor':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _white,
                        size: 18,
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
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.16),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 6),
              _buildCategoryFilters(),
              const SizedBox(height: 10),
              _buildMonthFilterDropdown(),
              const SizedBox(height: 14),
              Expanded(
                child: user == null
                    ? _buildEmptyState('Please log in to view workout history.')
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('workouts')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(color: _gold));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState('No workouts logged yet.');
                          }

                          // I-filter ang mga nakuhang dokumento mula sa Firestore
                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final category = data['category'] ?? 'Gym';
                            
                            // Petsa para sa Month filter
                            DateTime date = DateTime.now();
                            if (data['timestamp'] is Timestamp) {
                              date = (data['timestamp'] as Timestamp).toDate();
                            } else if (data['date'] != null) {
                              try {
                                date = DateFormat('MMM dd, yyyy').parse(data['date']);
                              } catch (_) {}
                            }

                            final monthName = DateFormat('MMMM').format(date);

                            bool matchCategory = _selectedCategory == 'All' ||
                                category.toString().toLowerCase() == _selectedCategory.toLowerCase();
                            bool matchMonth = _selectedMonth == 'All Months' ||
                                monthName.toLowerCase() == _selectedMonth.toLowerCase();

                            return matchCategory && matchMonth;
                          }).toList();

                          // Kuhanin ang Total Minutes
                          int totalMinutes = 0;
                          for (var doc in docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final durStr = data['duration']?.toString() ?? '0 min';
                            totalMinutes += _parseMinutes(durStr);
                          }

                          return Column(
                            children: [
                              _buildSummary(docs.length, totalMinutes),
                              const SizedBox(height: 10),
                              Expanded(
                                child: docs.isEmpty
                                    ? _buildEmptyState('No workouts found for the selected filter.')
                                    : ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                        itemCount: docs.length,
                                        itemBuilder: (context, index) {
                                          final data = docs[index].data() as Map<String, dynamic>;
                                          
                                          // Format ng totoong petsa mula Firestore
                                          String formattedDate = 'Recently';
                                          if (data['timestamp'] is Timestamp) {
                                            formattedDate = DateFormat('MMM dd, yyyy')
                                                .format((data['timestamp'] as Timestamp).toDate());
                                          } else if (data['date'] != null) {
                                            formattedDate = data['date'].toString();
                                          }

                                          final workoutMap = {
                                            'date': formattedDate,
                                            'title': data['title']?.toString() ?? data['workoutName']?.toString() ?? 'Workout Session',
                                            'category': data['category']?.toString() ?? 'Gym',
                                            'duration': data['duration']?.toString() ?? '45 min',
                                            'intensity': data['intensity']?.toString() ?? 'Moderate',
                                            'notes': data['notes']?.toString() ?? '',
                                          };

                                          return _buildWorkoutCard(workoutMap);
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
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────── Category Filters ─────────────────────────

  Widget _buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < _categories.length; i++) ...[
            if (i != 0) const SizedBox(width: 8),
            Expanded(child: _buildFilterChip(_categories[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final bool isSelected = _selectedCategory == filter;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedCategory = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_goldLight, _gold])
              : null,
          color: isSelected ? null : _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? _gold : _border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.black : _gray,
            fontWeight: FontWeight.w800,
            fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: _gold, size: 18),
                SizedBox(width: 10),
                Text(
                  'Filter Month:',
                  style: TextStyle(
                    color: _gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth, // Inayos dito: 'value' gamit sa halip na 'initialValue'
                dropdownColor: _card,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
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

  Widget _buildSummary(int count, int minutes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _summaryTile(
              icon: Icons.local_fire_department_rounded,
              label: 'Workouts',
              value: '$count',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryTile(
              icon: Icons.timer_outlined,
              label: 'Total time',
              value: _formatMinutes(minutes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _gold, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    color: _white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Workout Card ─────────────────────────

  Widget _buildWorkoutCard(Map<String, String> workout) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: _border, width: 1.2),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: _card,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => _showDetailsModal(context, workout),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _gold.withValues(alpha: 0.28),
                            _gold.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: _gold.withValues(alpha: 0.35)),
                      ),
                      child: Icon(
                        _categoryIcon(workout['category']!),
                        color: _gold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout['date']!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _goldBright,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            workout['title']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: _muted, size: 26),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: _border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip(Icons.place_outlined, workout['category']!),
                          _infoChip(Icons.timer_outlined, workout['duration']!),
                          _intensityChip(workout['intensity']!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _goldBright,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.30)),
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
    );
  }

  // ───────────────────────── Empty State ─────────────────────────

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.10),
                border: Border.all(color: _gold.withValues(alpha: 0.30)),
              ),
              child: const Icon(Icons.history_rounded, color: _gold, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No workouts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
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
                builder: (_) => MainNavigationScreen(initialIndex: index)),
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _goldBright,
        unselectedItemColor: _muted,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  // ───────────────────────── Details Modal ─────────────────────────

  Widget _detailTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _tile,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: _gold, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
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
    );
  }

  void _showDetailsModal(BuildContext context, Map<String, String> workout) {
    final String notes = workout['notes'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
                      color: _gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _gold.withValues(alpha: 0.4)),
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
                            fontWeight: FontWeight.w900,
                            color: _white,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  _detailTile(Icons.place_outlined, 'Category',
                      workout['category']!),
                  const SizedBox(width: 10),
                  _detailTile(
                      Icons.timer_outlined, 'Duration', workout['duration']!),
                  const SizedBox(width: 10),
                  _detailTile(Icons.bolt_rounded, 'Intensity',
                      workout['intensity']!),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: _gold, size: 20),
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
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Notes: $notes',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _gray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_goldLight, _gold],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: const Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
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