import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';

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
                if (h != null && m != null) {
                  appState.bleService.setAlarm(h, m);
                  appState.medicationRepository.updateSettings(alarmHour: h, alarmMinute: m);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Time")));
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
