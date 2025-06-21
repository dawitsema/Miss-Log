// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const VolumeBoosterApp());
}

class VolumeBoosterApp extends StatelessWidget {
  const VolumeBoosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Booster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const VolumeBoosterPage(),
    );
  }
}

class VolumeBoosterPage extends StatefulWidget {
  const VolumeBoosterPage({super.key});

  @override
  State<VolumeBoosterPage> createState() => _VolumeBoosterPageState();
}

class _VolumeBoosterPageState extends State<VolumeBoosterPage> {
  static const _platform = MethodChannel('com.example.volumebooster/channel');
  static const _prefsPhoneKey = 'phoneNumber';
  static const _prefsMaxCallsKey = 'maxCalls';
  static const _prefsWindowKey = 'windowMinutes';

  final _phoneController = TextEditingController();

  int _maxCalls = 3;
  double _windowMinutes = 5;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phone = prefs.getString(_prefsPhoneKey);
      _maxCalls = prefs.getInt(_prefsMaxCallsKey) ?? 3;
      _windowMinutes = (prefs.getInt(_prefsWindowKey) ?? 5).toDouble();
      _phoneController.text = _phone ?? '';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPhoneKey, _phone ?? '');
    await prefs.setInt(_prefsMaxCallsKey, _maxCalls);
    await prefs.setInt(_prefsWindowKey, _windowMinutes.toInt());
  }

  Future<void> _startMonitoring() async {
    var perm = await Permission.phone.status;
    if (!perm.isGranted) {
      perm = await Permission.phone.request();
      if (!perm.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone permission denied')),
          );
        }
        return;
      }
    }

    try {
      final result = await _platform.invokeMethod('setThresholds', {
        'maxCalls': _maxCalls,
        'windowMin': _windowMinutes.toInt(),
      });
      await _platform.invokeMethod('startMonitoring', {'phone': _phone});
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.toString())));
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      }
    }
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _phone = v.trim(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text('Max calls'), Text('$_maxCalls')],
                ),
                Slider(
                  value: _maxCalls.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_maxCalls',
                  onChanged: (v) => setState(() => _maxCalls = v.round()),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Window (minutes)'),
                    Text('${_windowMinutes.toInt()}'),
                  ],
                ),
                Slider(
                  value: _windowMinutes,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '${_windowMinutes.toInt()}',
                  onChanged: (v) => setState(() => _windowMinutes = v),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    _savePrefs();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Booster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _phone == null || _phone!.isEmpty
                          ? 'No phone registered'
                          : 'Monitoring $_phone',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trigger when a number calls more than $_maxCalls times within ${_windowMinutes.toInt()} min.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Monitoring'),
                      onPressed: _startMonitoring,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
