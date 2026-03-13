import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:epo_app/data/models/medication.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ePO Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(appState),
          _buildDateHeader(),
          const Divider(height: 1),
          Expanded(
            child: appState.medications.isEmpty
                ? _buildEmptyState(context, appState)
                : _buildTimeline(appState),
          ),
        ],
      ),
      floatingActionButton: appState.connectionState != BluetoothConnectionState.connected
          ? FloatingActionButton.extended(
              onPressed: () => _showScanDialog(context, appState),
              label: const Text("Connect Device"),
              icon: const Icon(Icons.bluetooth_searching),
            )
          : null,
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            "${now.day} ${_getMonth(now.month)} ${now.year}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              // Simple weekly view placeholder
              bool isToday = index == (now.weekday - 1);
              return Column(
                children: [
                  Text(days[index], style: TextStyle(fontSize: 12, color: isToday ? Colors.blue : Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.blue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${now.subtract(Duration(days: now.weekday - 1 - index)).day}",
                      style: TextStyle(color: isToday ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildConnectionStatus(AppState appState) {
    bool connected = appState.connectionState == BluetoothConnectionState.connected;
    return Container(
      color: connected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: connected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            connected ? "Device Connected" : "Device Disconnected",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: connected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medication_liquid, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No medications scheduled for today."),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            child: const Text("Manage Medications"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(AppState appState) {
    // Medications are pre-sorted in AppState for performance
    final sortedMeds = appState.medications;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedMeds.length,
      itemBuilder: (context, index) {
        final med = sortedMeds[index];
        bool lowStock = med.stockCount < 5;

        return IntrinsicHeight(
          child: Row(
            children: [
              // Timeline line and time
              Column(
                children: [
                  Text(
                    _formatTime(med.scheduleHours.first, med.scheduleMinutes.first),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Medication Card
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Colors.blue.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Dosage: ${med.dosage}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 4),
                              if (lowStock)
                                Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.orange, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Low Stock: ${med.stockCount} left!",
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                )
                              else
                                Text("Remaining: ${med.stockCount}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        _buildStatusIndicator(med),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(Medication med) {
    // Prototype: Simplified status
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
        ),
        const Text("Pending", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatTime(int hour, int minute) {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  void _showScanDialog(BuildContext context, AppState appState) {
    appState.bleService.startScan();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Connect to Pill Box"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<ScanResult>>(
            stream: appState.bleService.scanResults,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final result = snapshot.data![index];
                  return ListTile(
                    title: Text(result.device.platformName.isEmpty ? "Unknown Device" : result.device.platformName),
                    subtitle: Text(result.device.remoteId.toString()),
                    onTap: () {
                      appState.bleService.connect(result.device);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ],
      ),
    );
  }
}
