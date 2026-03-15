import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/data/models/medication.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/ui/theme/colors.dart';
import 'package:epo_app/ui/theme/strings.dart';
import 'medication_edit_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: ClaraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MedListHeader(
              onAdd: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationEditScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: appState.medications.isEmpty
                  ? _EmptyState(
                      onAdd: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MedicationEditScreen(),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: appState.medications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final med = appState.medications[index];
                        return _MedicationCard(
                          medication: med,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MedicationEditScreen(medication: med),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedListHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _MedListHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ClaraColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            color: ClaraColors.textPrimary,
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ClaraStrings.myMedications,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: ClaraColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ClaraColors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onEdit;

  const _MedicationCard({required this.medication, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bool lowStock = medication.stockCount < 5;
    final int dosesPerDay = medication.scheduleHours.isEmpty ? 1 : medication.scheduleHours.length;
    final int refillIn = dosesPerDay > 0 ? medication.stockCount ~/ dosesPerDay : medication.stockCount;
    final double stockFraction = (medication.stockCount / 30.0).clamp(0.0, 1.0);
    final bool progressIsLow = stockFraction <= 0.2;

    return Container(
      decoration: BoxDecoration(
        color: ClaraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClaraColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ClaraColors.purpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('💊', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ClaraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medication.dosage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ClaraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: ClaraColors.textTertiary, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  ],
                ),
              ],
            ),
          ),

          // Low stock banner
          if (lowStock) ...[
            Container(
              width: double.infinity,
              color: ClaraColors.amberLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ClaraColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    ClaraStrings.lowStock,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB87A10),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Stats row
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(
                  label: ClaraStrings.stockLabel,
                  value: '${medication.stockCount}',
                  isLow: lowStock,
                ),
                const VerticalDivider(width: 1, color: ClaraColors.border),
                _StatCell(
                  label: ClaraStrings.dosesPerDay,
                  value: '${dosesPerDay}x',
                  isLow: false,
                ),
                const VerticalDivider(width: 1, color: ClaraColors.border),
                _StatCell(
                  label: ClaraStrings.refillIn,
                  value: '$refillIn ${ClaraStrings.days}',
                  isLow: lowStock,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: ClaraColors.border),

          // Progress bar section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text(
                  ClaraStrings.stockLevel,
                  style: TextStyle(fontSize: 11, color: ClaraColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${medication.stockCount} / 30',
                  style: const TextStyle(fontSize: 11, color: ClaraColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stockFraction,
                minHeight: 5,
                backgroundColor: ClaraColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressIsLow ? ClaraColors.amber : ClaraColors.green,
                ),
              ),
            ),
          ),

          // Schedule chips
          if (medication.scheduleHours.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(medication.scheduleHours.length, (i) {
                  final h = medication.scheduleHours[i];
                  final m = medication.scheduleMinutes.length > i
                      ? medication.scheduleMinutes[i]
                      : 0;
                  final timeStr =
                      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: lowStock ? ClaraColors.redLight : ClaraColors.purpleLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$timeStr ${ClaraStrings.daily}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: lowStock ? ClaraColors.red : ClaraColors.purple,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isLow;

  const _StatCell({
    required this.label,
    required this.value,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: ClaraColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLow ? ClaraColors.red : ClaraColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
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
            'Tap the + button to add your first medication',
            style: TextStyle(fontSize: 13, color: ClaraColors.textSecondary),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: ClaraColors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                ClaraStrings.addMedication,
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
