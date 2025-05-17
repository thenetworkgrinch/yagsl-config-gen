import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frc_swerve_config/providers/config_provider.dart';
import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/screens/wizard/export_screen.dart';
import 'package:frc_swerve_config/services/network_tables_service.dart';

class DriveMotorTestScreen extends StatefulWidget {
  const DriveMotorTestScreen({super.key});

  @override
  State<DriveMotorTestScreen> createState() => _DriveMotorTestScreenState();
}

class _DriveMotorTestScreenState extends State<DriveMotorTestScreen> {
  double _driveSpeed = 0.0;
  double _azimuthAngle = 0.0;
  bool _isConnected = false;
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
  }
  
  void _checkConnection() {
    setState(() {
      _isConnected = NetworkTablesService.instance.isConnected;
    });
  }
  
  void _setDriveSpeed(double speed) {
    if (!_isConnected) return;
    
    setState(() {
      _driveSpeed = speed;
    });
    
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final currentModule = configProvider.currentModule;
    
    NetworkTablesService.instance.setDriveMotorSpeed(
      modulePosition: currentModule.position,
      speed: speed,
    );
  }
  
  void _setAzimuthAngle(double angle) {
    if (!_isConnected) return;
    
    setState(() {
      _azimuthAngle = angle;
    });
    
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final currentModule = configProvider.currentModule;
    
    NetworkTablesService.instance.setAzimuthMotorSpeed(
      modulePosition: currentModule.position,
      speed: angle / 180.0, // Convert angle to a speed value between -1 and 1
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final currentModule = configProvider.currentModule;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Drive Motor Test - ${modulePositionToString(currentModule.position)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drive Motor Testing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the drive and azimuth motors to ensure they are working correctly.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Connection status
            if (!_isConnected)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Not Connected to Robot',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You must be connected to a robot to test the motors.',
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            
            // Drive motor control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drive Motor Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Adjust the slider to control the drive motor speed.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('-1.0'),
                        Expanded(
                          child: Slider(
                            value: _driveSpeed,
                            min: -1.0,
                            max: 1.0,
                            divisions: 20,
                            label: _driveSpeed.toStringAsFixed(2),
                            onChanged: _isConnected ? _setDriveSpeed : null,
                          ),
                        ),
                        const Text('1.0'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Current Speed: ${_driveSpeed.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isConnected ? () => _setDriveSpeed(0.0) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Azimuth motor control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Azimuth Motor Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Adjust the slider to control the azimuth motor angle.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('-180°'),
                        Expanded(
                          child: Slider(
                            value: _azimuthAngle,
                            min: -180.0,
                            max: 180.0,
                            divisions: 36,
                            label: '${_azimuthAngle.toStringAsFixed(0)}°',
                            onChanged: _isConnected ? _setAzimuthAngle : null,
                          ),
                        ),
                        const Text('180°'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Current Angle: ${_azimuthAngle.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _isConnected ? () => _setAzimuthAngle(0.0) : null,
                          child: const Text('0°'),
                        ),
                        ElevatedButton(
                          onPressed: _isConnected ? () => _setAzimuthAngle(90.0) : null,
                          child: const Text('90°'),
                        ),
                        ElevatedButton(
                          onPressed: _isConnected ? () => _setAzimuthAngle(180.0) : null,
                          child: const Text('180°'),
                        ),
                        ElevatedButton(
                          onPressed: _isConnected ? () => _setAzimuthAngle(-90.0) : null,
                          child: const Text('-90°'),
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
                    // Stop motors before going back
                    if (_isConnected) {
                      _setDriveSpeed(0.0);
                      _setAzimuthAngle(0.0);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Stop motors before continuing
                    if (_isConnected) {
                      _setDriveSpeed(0.0);
                      _setAzimuthAngle(0.0);
                    }
                    
                    // Move to the next module or to the export screen
                    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
                    final currentIndex = configProvider.currentModuleIndex;
                    
                    if (currentIndex < configProvider.config.modules.length - 1) {
                      configProvider.nextModule();
                      Navigator.pop(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExportScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    configProvider.currentModuleIndex < configProvider.config.modules.length - 1
                        ? 'Next Module'
                        : 'Next: Export Configuration',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
