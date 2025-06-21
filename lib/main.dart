// Flutter implementation using platform channels for Android only
// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Booster',
      home: VolumeBoosterPage(),
    );
  }
}

class VolumeBoosterPage extends StatefulWidget {
  @override
  _VolumeBoosterPageState createState() => _VolumeBoosterPageState();
}

class _VolumeBoosterPageState extends State<VolumeBoosterPage> {
  static const platform = MethodChannel('com.example.volumebooster/channel');

  Future<void> requestPermissionsAndStart() async {
    try {
      final result = await platform.invokeMethod('startMonitoring');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.toString())),
      );
    } on PlatformException catch (e) {
      print("Failed: '\${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Volume Booster')),
      body: Center(
        child: ElevatedButton(
          onPressed: requestPermissionsAndStart,
          child: Text('Enable Monitoring'),
        ),
      ),
    );
  }
}