import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/data/models/medication.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.medication == null ? "Add Medication" : "Edit Medication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medication Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g. 10mg)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter dosage' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? 'Please enter a number' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text("Schedule Time"),
                subtitle: Text("${_alarmHour.toString().padLeft(2, '0')}:${_alarmMinute.toString().padLeft(2, '0')}"),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 30),
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

                    // TODO: Implement individual medication hardware sync.
                    // For the prototype, we also update the hardware settings globally.
                    await appState.bleService.setAlarm(_alarmHour, _alarmMinute);
                    await appState.medicationRepository.updateSettings(
                      alarmHour: _alarmHour,
                      alarmMinute: _alarmMinute,
                    );

                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
