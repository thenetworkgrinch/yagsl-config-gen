import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frc_swerve_config/providers/config_provider.dart';
import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/screens/wizard/drive_motor_test_screen.dart';
import 'package:frc_swerve_config/services/network_tables_service.dart';
import 'dart:math' as math;

class ModuleVerificationScreen extends StatefulWidget {
  const ModuleVerificationScreen({super.key});

  @override
  State<ModuleVerificationScreen> createState() => _ModuleVerificationScreenState();
}

class _ModuleVerificationScreenState extends State<ModuleVerificationScreen> {
  double? _currentEncoderValue;
  double? _currentMotorEncoderValue;
  bool _encodersInSync = true;

  @override
  void initState() {
    super.initState();
    _startEncoderValueUpdates();
  }

  void _startEncoderValueUpdates() {
    // Check if already connected
    if (!NetworkTablesService.instance.isConnected) {
      return;
    }
    
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final currentModule = configProvider.currentModule;
    
    // Subscribe to absolute encoder value
    NetworkTablesService.instance.subscribeToEncoderValue(
      modulePosition: currentModule.position,
      onValueChanged: (value) {
        if (mounted) {
          setState(() {
            _currentEncoderValue = value;
            _checkEncoderSync();
          });
        }
      },
    );
    
    // Subscribe to motor encoder value
    NetworkTablesService.instance.subscribeToMotorEncoderValue(
      modulePosition: currentModule.position,
      onValueChanged: (value) {
        if (mounted) {
          setState(() {
            _currentMotorEncoderValue = value;
            _checkEncoderSync();
          });
        }
      },
    );
  }
  
  void _checkEncoderSync() {
    if (_currentEncoderValue != null && _currentMotorEncoderValue != null) {
      // Check if encoders are roughly in sync (within 5 degrees)
      // This is a simplified check - in reality, there might be an offset
      final diff = (_currentEncoderValue! - _currentMotorEncoderValue!).abs() % 360;
      final normalizedDiff = diff > 180 ? 360 - diff : diff;
      
      setState(() {
        _encodersInSync = normalizedDiff < 5;
      });
    }
  }

  void _recordEncoderOffset() {
    if (_currentEncoderValue != null) {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      configProvider.updateEncoderOffset(_currentEncoderValue!);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DriveMotorTestScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final currentModule = configProvider.currentModule;
    final isConnected = NetworkTablesService.instance.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Module - ${modulePositionToString(currentModule.position)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Module Verification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ensure the module is positioned with the bevel gear facing to the right and the module is straight.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Visual module orientation
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Module representation
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Stack(
                              children: [
                                // Wheel
                                Center(
                                  child: Container(
                                    width: 80,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                
                                // Bevel gear indicator
                                Positioned(
                                  right: 10,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'B',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Absolute encoder value indicator
                                if (_currentEncoderValue != null)
                                  Center(
                                    child: Transform.rotate(
                                      angle: _currentEncoderValue! * math.pi / 180,
                                      child: Container(
                                        width: 60,
                                        height: 2,
                                        color: Colors.blue,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Motor encoder value indicator
                                if (_currentMotorEncoderValue != null)
                                  Center(
                                    child: Transform.rotate(
                                      angle: _currentMotorEncoderValue! * math.pi / 180,
                                      child: Container(
                                        width: 40,
                                        height: 2,
                                        color: Colors.yellow,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.yellow,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Direction indicators
                        const Positioned(
                          top: 5,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text('Forward'),
                          ),
                        ),
                        const Positioned(
                          bottom: 5,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text('Backward'),
                          ),
                        ),
                        const Positioned(
                          left: 5,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text('Left'),
                          ),
                        ),
                        const Positioned(
                          right: 5,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text('Right'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Correct Module Orientation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Legend for encoder indicators
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: Colors.blue,
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Absolute Encoder'),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 2,
                        color: Colors.yellow,
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Motor Encoder'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Encoder readings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Encoder Readings:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isConnected)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentEncoderValue != null)
                            Text(
                              'Absolute Encoder: ${_currentEncoderValue!.toStringAsFixed(2)}°',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_currentMotorEncoderValue != null)
                            Text(
                              'Motor Encoder: ${_currentMotorEncoderValue!.toStringAsFixed(2)}°',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          
                          // Encoder synchronization status
                          if (_currentEncoderValue != null && _currentMotorEncoderValue != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _encodersInSync ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _encodersInSync ? Icons.check_circle : Icons.warning,
                                    color: _encodersInSync ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _encodersInSync
                                          ? 'Encoders are synchronized'
                                          : 'Encoders are not synchronized. They should read similar values when the module is at rest.',
                                      style: TextStyle(
                                        color: _encodersInSync ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const Text(
                            'Not connected to robot',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const ConnectionScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Connect to Robot'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: isConnected && _currentEncoderValue != null
                      ? _recordEncoderOffset
                      : null,
                  child: const Text('Confirm & Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
