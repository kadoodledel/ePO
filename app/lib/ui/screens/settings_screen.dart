import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/ui/screens/medication_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  final _durationController = TextEditingController();
  final _intervalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text("Manage Medications"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicationListScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            const Text("Alarm Time (HH:MM)"),
            Row(
              children: [
                Expanded(child: TextField(controller: _hourController, decoration: const InputDecoration(hintText: "HH"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _minuteController, decoration: const InputDecoration(hintText: "MM"))),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                int? h = int.tryParse(_hourController.text);
                int? m = int.tryParse(_minuteController.text);
                if (h == null || h < 0 || h > 23) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid hour: must be between 0 and 23")),
                  );
                } else if (m == null || m < 0 || m > 59) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid minute: must be between 0 and 59")),
                  );
                } else {
                  appState.bleService.setAlarm(h, m);
                  appState.medicationRepository.updateSettings(alarmHour: h, alarmMinute: m);
                }
              },
              child: const Text("Sync Alarm"),
            ),
            const Divider(),
            TextField(controller: _durationController, decoration: const InputDecoration(labelText: "Alarm Duration (s)"), keyboardType: TextInputType.number),
            ElevatedButton(
              onPressed: () {
                int? d = int.tryParse(_durationController.text);
                if (d != null) {
                  appState.bleService.setDuration(d);
                  appState.medicationRepository.updateSettings(duration: d);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Duration")));
                }
              },
              child: const Text("Sync Duration"),
            ),
            const Divider(),
            TextField(controller: _intervalController, decoration: const InputDecoration(labelText: "Reminder Interval (m)"), keyboardType: TextInputType.number),
            ElevatedButton(
              onPressed: () {
                int? i = int.tryParse(_intervalController.text);
                if (i != null) {
                  appState.bleService.setReminderInterval(i);
                  appState.medicationRepository.updateSettings(interval: i);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Interval")));
                }
              },
              child: const Text("Sync Interval"),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MedicationEditScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: appState.medications.length,
        itemBuilder: (context, index) {
          final med = appState.medications[index];
          return ListTile(
            title: Text(med.name),
            subtitle: Text("Dosage: ${med.dosage} | Stock: ${med.stockCount}"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MedicationEditScreen(medication: med)),
            ),
          );
        },
      ),
    );
  }
}
