import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("ePO Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Connection Status: ${appState.connectionState.toString().split('.').last}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: const Text("Settings"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: appState.bleService.scanResults,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final result = snapshot.data![index];
                      return ListTile(
                        title: Text(result.device.platformName.isEmpty ? "Unknown Device" : result.device.platformName),
                        subtitle: Text(result.device.remoteId.toString()),
                        onTap: () => appState.bleService.connect(result.device),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => appState.bleService.startScan(),
              child: const Text("Scan for Pill Box"),
            ),
          ],
        ),
      ),
    );
  }
}
