import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/ui/theme/colors.dart';
import 'package:epo_app/ui/theme/strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _duration = 30;
  double _interval = 15;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool connected = appState.connectionState == BluetoothConnectionState.connected;

    return Scaffold(
      backgroundColor: ClaraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: appState.medicationRepository.getSettings(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && !_initialized) {
                    final settings = snapshot.data!;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _duration = ((settings['duration'] as int?) ?? 30).toDouble();
                          _interval = ((settings['interval'] as int?) ?? 15).toDouble();
                          _initialized = true;
                        });
                      }
                    });
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SectionLabel(ClaraStrings.myDevice),
                      const SizedBox(height: 8),
                      _DeviceCard(
                        connected: connected,
                        onConnect: () => _showScanDialog(context, appState),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(ClaraStrings.reminders),
                      const SizedBox(height: 8),
                      _RemindersCard(
                        duration: _duration,
                        interval: _interval,
                        onDurationChanged: (v) => setState(() => _duration = v),
                        onDurationEnd: (v) {
                          final secs = v.round();
                          appState.bleService.setDuration(secs);
                          appState.medicationRepository.updateSettings(duration: secs);
                        },
                        onIntervalChanged: (v) => setState(() => _interval = v),
                        onIntervalEnd: (v) {
                          final mins = v.round();
                          appState.bleService.setReminderInterval(mins);
                          appState.medicationRepository.updateSettings(interval: mins);
                        },
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(ClaraStrings.aboutClara),
                      const SizedBox(height: 8),
                      _AboutCard(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
// Header
// ---------------------------------------------------------------------------

class _SettingsHeader extends StatelessWidget {
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
          Text(
            'Settings',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: ClaraColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Device Card
// ---------------------------------------------------------------------------

class _DeviceCard extends StatelessWidget {
  final bool connected;
  final VoidCallback onConnect;

  const _DeviceCard({required this.connected, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClaraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClaraColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? ClaraColors.green : ClaraColors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  ClaraStrings.deviceName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ClaraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  ClaraStrings.deviceSubtitle,
                  style: TextStyle(fontSize: 12, color: ClaraColors.textSecondary),
                ),
              ],
            ),
          ),
          if (connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ClaraColors.greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                ClaraStrings.connected,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClaraColors.green,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onConnect,
              style: OutlinedButton.styleFrom(
                foregroundColor: ClaraColors.purple,
                side: const BorderSide(color: ClaraColors.purple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: const Text(ClaraStrings.connectDevice, style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminders Card
// ---------------------------------------------------------------------------

class _RemindersCard extends StatelessWidget {
  final double duration;
  final double interval;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<double> onDurationEnd;
  final ValueChanged<double> onIntervalChanged;
  final ValueChanged<double> onIntervalEnd;

  const _RemindersCard({
    required this.duration,
    required this.interval,
    required this.onDurationChanged,
    required this.onDurationEnd,
    required this.onIntervalChanged,
    required this.onIntervalEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClaraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClaraColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alarm duration
          Row(
            children: [
              const Expanded(
                child: Text(
                  ClaraStrings.alarmDuration,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ClaraColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${duration.round()}${ClaraStrings.seconds}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ClaraColors.purple,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ClaraColors.purple,
              inactiveTrackColor: ClaraColors.purpleLight,
              thumbColor: ClaraColors.purple,
              overlayColor: ClaraColors.purpleLight,
            ),
            child: Slider(
              value: duration,
              min: 10,
              max: 120,
              divisions: 22,
              onChanged: onDurationChanged,
              onChangeEnd: onDurationEnd,
            ),
          ),
          const Divider(color: ClaraColors.border),
          const SizedBox(height: 8),
          // Reminder interval
          Row(
            children: [
              const Expanded(
                child: Text(
                  ClaraStrings.reminderInterval,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ClaraColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${interval.round()}${ClaraStrings.minutes}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ClaraColors.purple,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ClaraColors.purple,
              inactiveTrackColor: ClaraColors.purpleLight,
              thumbColor: ClaraColors.purple,
              overlayColor: ClaraColors.purpleLight,
            ),
            child: Slider(
              value: interval,
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: onIntervalChanged,
              onChangeEnd: onIntervalEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About Card
// ---------------------------------------------------------------------------

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClaraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClaraColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'App Version',
              style: TextStyle(fontSize: 14, color: ClaraColors.textPrimary),
            ),
            trailing: const Text(
              ClaraStrings.appVersion,
              style: TextStyle(fontSize: 13, color: ClaraColors.textSecondary),
            ),
          ),
          const Divider(height: 1, color: ClaraColors.border),
          ListTile(
            title: const Text(
              'Support',
              style: TextStyle(fontSize: 14, color: ClaraColors.textPrimary),
            ),
            trailing: const Text(
              ClaraStrings.supportEmail,
              style: TextStyle(fontSize: 12, color: ClaraColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}
