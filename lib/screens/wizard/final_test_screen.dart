import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frc_swerve_config/providers/config_provider.dart';
import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/screens/wizard/export_screen.dart';
import 'package:frc_swerve_config/services/network_tables_service.dart';
import 'dart:math' as math;

class FinalTestScreen extends StatefulWidget {
  const FinalTestScreen({super.key});

  @override
  State<FinalTestScreen> createState() => _FinalTestScreenState();
}

class _FinalTestScreenState extends State<FinalTestScreen> {
  bool _isConnected = false;
  bool _isDriveTestRunning = false;
  bool _isRotationTestRunning = false;
  int? _selectedModuleIndex;
  List<double> _moduleAngles = [0, 0, 0, 0];
  List<double> _moduleSpeeds = [0, 0, 0, 0];
  
  @override
  void initState() {
    super.initState();
    _connectToRobot();
  }

  @override
  void dispose() {
    _stopAllTests();
    super.dispose();
  }

  Future<void> _connectToRobot() async {
    try {
      await NetworkTablesService.instance.connect();
      setState(() {
        _isConnected = true;
      });
      _startModuleUpdates();
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to robot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startModuleUpdates() {
    NetworkTablesService.instance.subscribeToAllModuleAngles(
      onValueChanged: (angles) {
        if (mounted) {
          setState(() {
            _moduleAngles = angles;
          });
        }
      },
    );
    
    NetworkTablesService.instance.subscribeToAllModuleSpeeds(
      onValueChanged: (speeds) {
        if (mounted) {
          setState(() {
            _moduleSpeeds = speeds;
          });
        }
      },
    );
  }

  void _startDriveTest() {
    NetworkTablesService.instance.startDriveStraightTest();
    
    setState(() {
      _isDriveTestRunning = true;
      _isRotationTestRunning = false;
    });
  }

  void _startRotationTest() {
    NetworkTablesService.instance.startRotationTest();
    
    setState(() {
      _isRotationTestRunning = true;
      _isDriveTestRunning = false;
    });
  }

  void _stopAllTests() {
    if (_isDriveTestRunning || _isRotationTestRunning) {
      NetworkTablesService.instance.stopAllTests();
      
      setState(() {
        _isDriveTestRunning = false;
        _isRotationTestRunning = false;
      });
    }
  }

  void _selectModule(int index) {
    setState(() {
      _selectedModuleIndex = index;
    });
  }

  void _addOffsetToModule() {
    if (_selectedModuleIndex != null) {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      final module = configProvider.config.modules[_selectedModuleIndex!];
      
      // Add 180 degrees to the encoder offset
      final newOffset = (module.encoderOffset + 180) % 360;
      
      // Update the offset in the provider
      configProvider.setCurrentModuleIndex(_selectedModuleIndex!);
      configProvider.updateEncoderOffset(newOffset);
      
      // Update the offset in the robot
      NetworkTablesService.instance.updateModuleEncoderOffset(
        modulePosition: module.position,
        offset: newOffset,
      );
      
      setState(() {
        _selectedModuleIndex = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added 180° to module encoder offset'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final config = configProvider.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Testing'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Final Swerve Drive Testing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test the complete swerve drive to ensure everything is working correctly.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // Visual swerve drive representation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Swerve Drive Visualization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                // Robot direction indicator
                                Positioned(
                                  top: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.arrow_upward, color: Colors.blue, size: 30),
                                        const Text(
                                          'Front',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Modules
                                ...config.modules.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final module = entry.value;
                                  
                                  // Calculate position based on module location
                                  final x = 125 + (module.locationX / 30 * 100); // Scale to fit
                                  final y = 125 - (module.locationY / 30 * 100); // Y is inverted in UI
                                  
                                  // Get module color
                                  Color moduleColor;
                                  switch (module.position) {
                                    case ModulePosition.frontLeft:
                                      moduleColor = Colors.red;
                                      break;
                                    case ModulePosition.frontRight:
                                      moduleColor = Colors.green;
                                      break;
                                    case ModulePosition.backLeft:
                                      moduleColor = Colors.blue;
                                      break;
                                    case ModulePosition.backRight:
                                      moduleColor = Colors.orange;
                                      break;
                                  }
                                  
                                  return Positioned(
                                    left: x - 25,
                                    top: y - 25,
                                    child: GestureDetector(
                                      onTap: () => _selectModule(index),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: moduleColor.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _selectedModuleIndex == index ? Colors.yellow : Colors.black,
                                            width: _selectedModuleIndex == index ? 3 : 1,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Module label
                                            Center(
                                              child: Text(
                                                module.position == ModulePosition.frontLeft ? 'FL' :
                                                module.position == ModulePosition.frontRight ? 'FR' :
                                                module.position == ModulePosition.backLeft ? 'BL' : 'BR',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            
                                            // Module angle indicator
                                            Center(
                                              child: Transform.rotate(
                                                angle: _moduleAngles[index] * math.pi / 180,
                                                child: Container(
                                                  width: 40,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.8),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: _moduleSpeeds[index] != 0 ? Colors.green : Colors.white,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            // Speed indicator
                                            if (_moduleSpeeds[index] != 0)
                                              Positioned(
                                                bottom: 2,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: Text(
                                                    '${_moduleSpeeds[index].abs().toStringAsFixed(1)} m/s',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Legend
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              const Text('Front Left'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              const Text('Front Right'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              const Text('Back Left'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              const Text('Back Right'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Drive straight test
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drive Straight Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All modules should face forward (0°) and drive slowly forward.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isConnected && !_isDriveTestRunning && !_isRotationTestRunning
                              ? _startDriveTest
                              : (_isDriveTestRunning ? _stopAllTests : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDriveTestRunning ? Colors.red : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            _isDriveTestRunning ? 'Stop Test' : 'Start Drive Test',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Rotation test
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rotation Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The robot should rotate counter-clockwise in place.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isConnected && !_isDriveTestRunning && !_isRotationTestRunning
                              ? _startRotationTest
                              : (_isRotationTestRunning ? _stopAllTests : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRotationTestRunning ? Colors.red : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            _isRotationTestRunning ? 'Stop Test' : 'Start Rotation Test',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Module correction
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Module Correction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If a module is not behaving correctly, select it and apply the recommended fix.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select the module with issues:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(4, (index) {
                          return ChoiceChip(
                            label: Text(modulePositionToString(ModulePosition.values[index])),
                            selected: _selectedModuleIndex == index,
                            onSelected: (selected) {
                              if (selected) {
                                _selectModule(index);
                              } else {
                                setState(() {
                                  _selectedModuleIndex = null;
                                });
                              }
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedModuleIndex != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommended fix:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'If the module is driving in the wrong direction, add 180° to the encoder offset instead of inverting the motor controller.',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: _addOffsetToModule,
                                child: const Text('Add 180° to Encoder Offset'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _stopAllTests();
                      Navigator.pop(context);
                    },
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _stopAllTests();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExportScreen(),
                        ),
                      );
                    },
                    child: const Text('Next: Export Configuration'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
