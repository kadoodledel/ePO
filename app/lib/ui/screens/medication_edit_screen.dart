import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/data/models/medication.dart';
import 'package:epo_app/ui/theme/colors.dart';
import 'package:epo_app/ui/theme/strings.dart';

class MedicationEditScreen extends StatefulWidget {
  final Medication? medication;

  const MedicationEditScreen({super.key, this.medication});

  @override
  State<MedicationEditScreen> createState() => _MedicationEditScreenState();
}

class _MedicationEditScreenState extends State<MedicationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  int _alarmHour = 8;
  int _alarmMinute = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _dosageController = TextEditingController(text: widget.medication?.dosage ?? '');
    _stockController = TextEditingController(text: widget.medication?.stockCount.toString() ?? '0');
    if (widget.medication != null && widget.medication!.scheduleHours.isNotEmpty) {
      _alarmHour = widget.medication!.scheduleHours.first;
      _alarmMinute = widget.medication!.scheduleMinutes.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _alarmHour, minute: _alarmMinute),
    );
    if (picked != null) {
      setState(() {
        _alarmHour = picked.hour;
        _alarmMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isEdit = widget.medication != null;

    return Scaffold(
      backgroundColor: ClaraColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
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
                        isEdit ? ClaraStrings.editMedication : ClaraStrings.newMedication,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          color: ClaraColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Medication Info section
                    _SectionLabel(ClaraStrings.medicationInfo),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ClaraColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ClaraColors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Medication Name',
                              hintText: 'e.g. Aspirin',
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Please enter a name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dosageController,
                            decoration: const InputDecoration(
                              labelText: 'Dosage',
                              hintText: 'e.g. 10mg',
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Please enter dosage' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stock section
                    _SectionLabel(ClaraStrings.stock),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ClaraColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ClaraColors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Count',
                          hintText: 'e.g. 30',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || int.tryParse(value) == null
                                ? 'Please enter a number'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Schedule section
                    _SectionLabel(ClaraStrings.schedule),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ClaraColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ClaraColors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Dose time',
                            style: TextStyle(
                              fontSize: 14,
                              color: ClaraColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: ClaraColors.purpleLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: ClaraColors.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_alarmHour.toString().padLeft(2, '0')}:${_alarmMinute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ClaraColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final med = Medication(
                            id: widget.medication?.id ?? '',
                            name: _nameController.text,
                            dosage: _dosageController.text,
                            stockCount: int.parse(_stockController.text),
                            scheduleHours: [_alarmHour],
                            scheduleMinutes: [_alarmMinute],
                          );

                          if (widget.medication == null) {
                            await appState.medicationRepository.addMedication(med);
                          } else {
                            await appState.medicationRepository.updateMedication(med);
                          }

                          await appState.bleService.syncMedication(med);

                          // TODO: [Technical Debt] Remove global hardware settings update when multi-slot hardware is available.
                          // For the prototype, we also update the hardware settings globally.
                          await appState.medicationRepository.updateSettings(
                            alarmHour: _alarmHour,
                            alarmMinute: _alarmMinute,
                          );

                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text(ClaraStrings.saveButton),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ClaraColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}
