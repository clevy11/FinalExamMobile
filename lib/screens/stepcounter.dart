import 'dart:async';
import 'dart:math'; // Import dart:math for sqrt function
import 'package:calebproject/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  int _stepCount = 0;
  bool _motionDetected = false;
  bool _notificationShown = false;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late double _previousMagnitude;
  late DateTime _lastStepTime;

  @override
  void initState() {
    super.initState();
    _previousMagnitude = 0.0;
    _lastStepTime = DateTime.now();
    _startListeningToAccelerometer();
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _startListeningToAccelerometer() {
    Timer? motionTimer;

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (_isStepDetected(magnitude)) {
        setState(() {
          _stepCount++;
          _motionDetected = true;
          _triggerNotification();
          _notificationShown = true;
          motionTimer?.cancel();
          motionTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _motionDetected = false;
                _notificationShown = false;
              });
            }
          });
        });
      }

      _previousMagnitude = magnitude;
    });
  }

  bool _isStepDetected(double magnitude) {
    final currentTime = DateTime.now();
    final timeDifference = currentTime.difference(_lastStepTime).inMilliseconds;

    // Threshold and time gap to avoid multiple detections for a single step
    if (magnitude > 12 && timeDifference > 300) {
      _lastStepTime = currentTime;
      return true;
    }
    return false;
  }

  void _triggerNotification() async {
    if (!_notificationShown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'StepCounter_channel',
        'StepCounter Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'yolla!',
        'Motion detected! keep moving ',
        platformChannelSpecifics,
      );
      print('Motion detected! Alerting user...');
      _notificationShown = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C5470), // Main color from main.dart
        title: Text(
          'Step Counter',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1B24), // Dark background
              Color(0xFF5C5470), // Mid-tone purple
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.run_circle_outlined,
                  size: 100,
                  color: Color.fromARGB(255, 226, 225, 228),
                ),
              ),
              const SizedBox(height: 20),
              _buildStepCounterWidget(),
              const SizedBox(height: 20),
              _motionDetected
                  ? Text(
                      'Motion Detected!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red, // Highlight in red for emphasis
                      ),
                    )
                  : Text(
                      'At rest',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green, // Use green color for rest
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCounterWidget() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: _stepCount % 100 / 100, // Normalized to percentage
              strokeWidth: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFF5C5470)),
            ),
          ),
          Center(
            child: Text(
              '$_stepCount',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
