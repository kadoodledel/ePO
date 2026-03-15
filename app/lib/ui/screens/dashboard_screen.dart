import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/data/models/medication.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/ui/theme/colors.dart';
import 'package:epo_app/ui/theme/strings.dart';
import 'medication_list_screen.dart';

// ---------------------------------------------------------------------------
// Dose status helpers
// ---------------------------------------------------------------------------

enum _DoseStatus { dueNow, later, missed }

_DoseStatus _getStatus({
  required int hour,
  required int minute,
  required bool alarmActive,
}) {
  if (alarmActive) return _DoseStatus.dueNow;
  final now = TimeOfDay.now();
  final nowMinutes = now.hour * 60 + now.minute;
  final schedMinutes = hour * 60 + minute;
  final diff = nowMinutes - schedMinutes;
  if (diff < -30) return _DoseStatus.later;
  if (diff.abs() <= 30) return _DoseStatus.dueNow;
  return _DoseStatus.missed;
}

// ---------------------------------------------------------------------------
// Dashboard Screen (StatefulWidget for bottom nav index)
// ---------------------------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index, BuildContext context) {
    if (index == 2) {
      // Meds tab → push named route
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicationListScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: ClaraColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(appState: appState),
          const _ComingSoonScreen(label: 'History'),
          const SizedBox.shrink(), // index 2 = Meds (navigated, never shown)
          const _ComingSoonScreen(label: 'Profile'),
        ],
      ),
      floatingActionButton: appState.connectionState != BluetoothConnectionState.connected
          ? FloatingActionButton(
              onPressed: () => _showScanDialog(context, appState),
              backgroundColor: ClaraColors.purple,
              child: const Icon(Icons.bluetooth_searching, color: Colors.white),
            )
          : null,
      bottomNavigationBar: _ClaraBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => _onNavTap(i, context),
      ),
    );
  }

  void _showScanDialog(BuildContext context, AppState appState) {
    appState.bleService.startScan();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(ClaraStrings.connectToPillBox),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<ScanResult>>(
            stream: appState.bleService.scanResults,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (_, index) {
                  final result = snapshot.data![index];
                  final name = result.device.platformName.isEmpty
                      ? ClaraStrings.unknownDevice
                      : result.device.platformName;
                  return ListTile(
                    leading: const Icon(Icons.bluetooth, color: ClaraColors.purple),
                    title: Text(name),
                    subtitle: Text(result.device.remoteId.toString()),
                    onTap: () {
                      appState.bleService.connect(result.device);
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(ClaraStrings.cancel),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Tab
// ---------------------------------------------------------------------------

class _DashboardTab extends StatelessWidget {
  final AppState appState;

  const _DashboardTab({required this.appState});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildWeekStrip()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              ClaraStrings.todaysDoses,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ClaraColors.textSecondary,
                letterSpacing: 0.06 * 11,
              ),
            ),
          ),
        ),
        if (appState.medications.isEmpty)
          SliverFillRemaining(child: _buildEmptyDoses(context))
        else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: _DoseCard(
                  medication: appState.medications[index],
                  alarmActive: appState.alarmActive,
                ),
              ),
              childCount: appState.medications.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _AdherenceCard(medications: appState.medications),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final bool connected = appState.connectionState == BluetoothConnectionState.connected;
    return Container(
      color: ClaraColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      ClaraStrings.goodMorning,
                      style: TextStyle(
                        fontSize: 10,
                        color: ClaraColors.textSecondary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ClaraStrings.greetingDefault,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        color: ClaraColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar with optional connected dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: ClaraColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ClaraColors.purple,
                        ),
                      ),
                    ),
                  ),
                  if (connected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: ClaraColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: ClaraColors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Streak pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: ClaraColors.amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ClaraColors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  ClaraStrings.streakLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB87A10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Container(
      color: ClaraColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final day = startOfWeek.add(Duration(days: i));
          final isToday = i == now.weekday - 1;
          final isPast = day.isBefore(DateTime(now.year, now.month, now.day));

          Color dotColor = Colors.transparent;
          if (isToday) {
            dotColor = appState.alarmActive ? ClaraColors.red : ClaraColors.green;
          } else if (isPast) {
            // No history data — leave transparent for past days
          }

          return _DayCell(
            dayName: dayNames[i],
            dayNumber: day.day,
            isToday: isToday,
            dotColor: dotColor,
          );
        }),
      ),
    );
  }

  Widget _buildEmptyDoses(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ClaraColors.purpleLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.medication_rounded, size: 36, color: ClaraColors.purple),
          ),
          const SizedBox(height: 16),
          const Text(
            ClaraStrings.noMedsMessage,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: ClaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add medications to track your doses',
            style: TextStyle(fontSize: 13, color: ClaraColors.textSecondary),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicationListScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: ClaraColors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                ClaraStrings.manageMedications,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day cell widget
// ---------------------------------------------------------------------------

class _DayCell extends StatelessWidget {
  final String dayName;
  final int dayNumber;
  final bool isToday;
  final Color dotColor;

  const _DayCell({
    required this.dayName,
    required this.dayNumber,
    required this.isToday,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: isToday ? ClaraColors.purple : ClaraColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isToday ? ClaraColors.purple : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isToday ? Colors.white : ClaraColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dose Card
// ---------------------------------------------------------------------------

class _DoseCard extends StatelessWidget {
  final Medication medication;
  final bool alarmActive;

  const _DoseCard({required this.medication, required this.alarmActive});

  @override
  Widget build(BuildContext context) {
    final int hour = medication.scheduleHours.isNotEmpty ? medication.scheduleHours.first : 0;
    final int minute = medication.scheduleMinutes.isNotEmpty ? medication.scheduleMinutes.first : 0;
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final status = _getStatus(hour: hour, minute: minute, alarmActive: alarmActive);

    return Container(
      decoration: BoxDecoration(
        color: ClaraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClaraColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ClaraColors.purpleLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('💊', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Center: name + detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ClaraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  medication.dosage,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ClaraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Right: time + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ClaraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _StatusBadge(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _DoseStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case _DoseStatus.dueNow:
        bg = ClaraColors.purpleLight;
        textColor = ClaraColors.purple;
        label = ClaraStrings.dueNow;
      case _DoseStatus.missed:
        bg = ClaraColors.redLight;
        textColor = ClaraColors.red;
        label = ClaraStrings.missed;
      case _DoseStatus.later:
        bg = const Color(0xFFF0EFF8);
        textColor = ClaraColors.textSecondary;
        label = ClaraStrings.later;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Adherence Card
// ---------------------------------------------------------------------------

class _AdherenceCard extends StatelessWidget {
  final List<Medication> medications;

  const _AdherenceCard({required this.medications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF7C6EF5), Color(0xFF9B8DF7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Circular progress ring (placeholder 75%)
          SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(
              painter: _RingPainter(value: 0.75),
              child: const Center(
                child: Text(
                  '--',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  ClaraStrings.trackDoses,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ClaraStrings.dosesOnTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value; // 0.0 to 1.0

  const _RingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ---------------------------------------------------------------------------
// Bottom Navigation Bar
// ---------------------------------------------------------------------------

class _ClaraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ClaraBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ClaraColors.surface,
        border: Border(top: BorderSide(color: ClaraColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                label: 'Today',
                painter: _TodayIconPainter.new,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'History',
                painter: _HistoryIconPainter.new,
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                label: 'Meds',
                painter: _MedsIconPainter.new,
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                label: 'Profile',
                painter: _ProfileIconPainter.new,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String label;
  final CustomPainter Function({required Color color}) painter;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.painter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;
    final Color color = isActive ? ClaraColors.purple : ClaraColors.textTertiary;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: painter(color: color)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom nav icon painters
// ---------------------------------------------------------------------------

class _TodayIconPainter extends CustomPainter {
  final Color color;

  _TodayIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gap = size.width * 0.12;
    final cellSize = (size.width - gap) / 2;
    final radius = const Radius.circular(3);

    // Top-left
    canvas.drawRRect(RRect.fromLTRBR(0, 0, cellSize, cellSize, radius), paint);
    // Top-right
    canvas.drawRRect(RRect.fromLTRBR(cellSize + gap, 0, size.width, cellSize, radius), paint);
    // Bottom-left
    canvas.drawRRect(RRect.fromLTRBR(0, cellSize + gap, cellSize, size.height, radius), paint);
    // Bottom-right
    canvas.drawRRect(RRect.fromLTRBR(cellSize + gap, cellSize + gap, size.width, size.height, radius), paint);
  }

  @override
  bool shouldRepaint(_TodayIconPainter old) => old.color != color;
}

class _HistoryIconPainter extends CustomPainter {
  final Color color;

  _HistoryIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // Clock face circle
    canvas.drawCircle(center, radius, strokePaint);

    // Hour hand (pointing to roughly 12:00 - 3 o'clock angle)
    final hourEnd = Offset(
      center.dx + radius * 0.45 * math.cos(-math.pi / 2),
      center.dy + radius * 0.45 * math.sin(-math.pi / 2),
    );
    canvas.drawLine(center, hourEnd, strokePaint);

    // Minute hand
    final minuteEnd = Offset(
      center.dx + radius * 0.6 * math.cos(0),
      center.dy + radius * 0.6 * math.sin(0),
    );
    canvas.drawLine(center, minuteEnd, strokePaint);
  }

  @override
  bool shouldRepaint(_HistoryIconPainter old) => old.color != color;
}

class _MedsIconPainter extends CustomPainter {
  final Color color;

  _MedsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      // Left wall up
      ..moveTo(1, h * 0.6)
      ..lineTo(1, h - 2)
      ..lineTo(w - 1, h - 2)
      ..lineTo(w - 1, h * 0.6)
      // Roof
      ..moveTo(0, h * 0.6)
      ..lineTo(w / 2, 1)
      ..lineTo(w, h * 0.6);

    canvas.drawPath(path, strokePaint);

    // Door rectangle at bottom center
    final doorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dw = w * 0.28;
    final dh = h * 0.32;
    canvas.drawRRect(
      RRect.fromLTRBR(
        (w - dw) / 2,
        h - 2 - dh,
        (w + dw) / 2,
        h - 2,
        const Radius.circular(2),
      ),
      doorPaint,
    );
  }

  @override
  bool shouldRepaint(_MedsIconPainter old) => old.color != color;
}

class _ProfileIconPainter extends CustomPainter {
  final Color color;

  _ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Head circle
    final headRadius = size.width * 0.22;
    final headCenter = Offset(size.width / 2, size.height * 0.3);
    canvas.drawCircle(headCenter, headRadius, paint);

    // Body arc (shoulders)
    final bodyPath = Path();
    final bodyTop = size.height * 0.58;
    bodyPath.moveTo(0, size.height);
    bodyPath.quadraticBezierTo(
      size.width / 2,
      bodyTop,
      size.width,
      size.height,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(_ProfileIconPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Coming Soon screen
// ---------------------------------------------------------------------------

class _ComingSoonScreen extends StatelessWidget {
  final String label;

  const _ComingSoonScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaraColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ClaraColors.purpleLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 36, color: ClaraColors.purple),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ClaraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                ClaraStrings.comingSoon,
                style: TextStyle(fontSize: 14, color: ClaraColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
