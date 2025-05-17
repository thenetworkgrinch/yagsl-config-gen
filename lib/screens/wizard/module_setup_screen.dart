import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frc_swerve_config/providers/config_provider.dart';
import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/screens/wizard/module_verification_screen.dart';
import 'package:frc_swerve_config/screens/connection_screen.dart';
import 'package:frc_swerve_config/widgets/number_input_field.dart';
import 'package:frc_swerve_config/widgets/module_position_editor.dart';
import 'package:frc_swerve_config/services/network_tables_service.dart';

class ModuleSetupScreen extends StatefulWidget {
  const ModuleSetupScreen({super.key});

  @override
  State<ModuleSetupScreen> createState() => _ModuleSetupScreenState();
}

class _ModuleSetupScreenState extends State<ModuleSetupScreen> {
  double? _motorEncoderValue;
  
  @override
  void initState() {
    super.initState();
    if (NetworkTablesService.instance.isConnected) {
      _startMotorEncoderUpdates();
    }
  }
  
  void _startMotorEncoderUpdates() {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final currentModule = configProvider.currentModule;
    
    NetworkTablesService.instance.subscribeToMotorEncoderValue(
      modulePosition: currentModule.position,
      onValueChanged: (value) {
        if (mounted) {
          setState(() {
            _motorEncoderValue = value;
          });
        }
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final currentModule = configProvider.currentModule;
    final currentModuleIndex = configProvider.currentModuleIndex;
    final isConnected = NetworkTablesService.instance.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Text('Module Setup - ${modulePositionToString(currentModule.position)}'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.link : Icons.link_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Module Configuration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure each module with the appropriate hardware settings. Make sure the module is positioned with the bevel gear facing to the right and the module straight.',
                style: TextStyle(fontSize: 16),
              ),
              
              // Connection warning if not connected
              if (!isConnected)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
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
                        'You are not connected to a robot. Some features will not be available.',
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ConnectionScreen(),
                            ),
                          );
                        },
                        child: const Text('Connect to Robot'),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Visual module position editor
              const Text(
                'Module Positions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter precise module positions using the numeric fields below. The visual representation will update automatically.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ModulePositionEditor(
                modules: configProvider.config.modules,
                selectedModuleIndex: currentModuleIndex,
                onModuleSelected: (index) {
                  configProvider.setCurrentModuleIndex(index);
                  
                  // Update motor encoder subscription for the new module if connected
                  if (isConnected) {
                    _startMotorEncoderUpdates();
                  }
                },
                encoderOffset: currentModule.encoderOffset,
                motorEncoderValue: _motorEncoderValue,
              ),
              const SizedBox(height: 16),
              
              // Module location numeric inputs
              Row(
                children: [
                  Expanded(
                    child: NumberInputField(
                      label: 'X Position (inches)',
                      value: currentModule.locationX,
                      onChanged: (value) {
                        configProvider.updateModuleLocation(value, currentModule.locationY);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NumberInputField(
                      label: 'Y Position (inches)',
                      value: currentModule.locationY,
                      onChanged: (value) {
                        configProvider.updateModuleLocation(currentModule.locationX, value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Drive motor configuration
              const Text(
                'Drive Motor Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MotorType>(
                decoration: const InputDecoration(
                  labelText: 'Drive Motor Type',
                  border: OutlineInputBorder(),
                ),
                value: currentModule.driveMotorType,
                items: MotorType.values.map((type) {
                  return DropdownMenuItem<MotorType>(
                    value: type,
                    child: Text(motorTypeToString(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    configProvider.updateDriveMotorType(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MotorControllerType>(
                decoration: const InputDecoration(
                  labelText: 'Drive Motor Controller Type',
                  border: OutlineInputBorder(),
                ),
                value: currentModule.driveMotorControllerType,
                items: MotorControllerType.values.map((type) {
                  return DropdownMenuItem<MotorControllerType>(
                    value: type,
                    child: Text(motorControllerTypeToString(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    configProvider.updateDriveMotorController(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              NumberInputField(
                label: 'Drive Motor CAN ID',
                value: currentModule.driveCanId.toDouble(),
                onChanged: (value) {
                  configProvider.updateDriveCanId(value.toInt());
                },
                isInteger: true,
              ),
              const SizedBox(height: 16),
              if (currentModule.driveMotorControllerType == MotorControllerType.talonFX ||
                  currentModule.driveMotorControllerType == MotorControllerType.talonFXS)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Drive Motor CAN Bus Name',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for default "rio" bus',
                  ),
                  onChanged: (value) {
                    configProvider.updateDriveCanBus(value);
                  },
                  controller: TextEditingController(text: currentModule.driveCanBus),
                ),
              if (currentModule.driveMotorControllerType == MotorControllerType.talonFX ||
                  currentModule.driveMotorControllerType == MotorControllerType.talonFXS)
                const SizedBox(height: 16),
              
              // Azimuth motor configuration
              const SizedBox(height: 24),
              const Text(
                'Azimuth Motor Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MotorType>(
                decoration: const InputDecoration(
                  labelText: 'Azimuth Motor Type',
                  border: OutlineInputBorder(),
                ),
                value: currentModule.azimuthMotorType,
                items: MotorType.values.map((type) {
                  return DropdownMenuItem<MotorType>(
                    value: type,
                    child: Text(motorTypeToString(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    configProvider.updateAzimuthMotorType(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MotorControllerType>(
                decoration: const InputDecoration(
                  labelText: 'Azimuth Motor Controller Type',
                  border: OutlineInputBorder(),
                ),
                value: currentModule.azimuthMotorControllerType,
                items: MotorControllerType.values.map((type) {
                  return DropdownMenuItem<MotorControllerType>(
                    value: type,
                    child: Text(motorControllerTypeToString(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    configProvider.updateAzimuthMotorController(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              NumberInputField(
                label: 'Azimuth Motor CAN ID',
                value: currentModule.azimuthCanId.toDouble(),
                onChanged: (value) {
                  configProvider.updateAzimuthCanId(value.toInt());
                },
                isInteger: true,
              ),
              const SizedBox(height: 16),
              if (currentModule.azimuthMotorControllerType == MotorControllerType.talonFX ||
                  currentModule.azimuthMotorControllerType == MotorControllerType.talonFXS)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Azimuth Motor CAN Bus Name',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for default "rio" bus',
                  ),
                  onChanged: (value) {
                    configProvider.updateAzimuthCanBus(value);
                  },
                  controller: TextEditingController(text: currentModule.azimuthCanBus),
                ),
              if (currentModule.azimuthMotorControllerType == MotorControllerType.talonFX ||
                  currentModule.azimuthMotorControllerType == MotorControllerType.talonFXS)
                const SizedBox(height: 16),
              
              // Encoder configuration
              const SizedBox(height: 24),
              const Text(
                'Absolute Encoder Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EncoderType>(
                decoration: const InputDecoration(
                  labelText: 'Absolute Encoder Type',
                  border: OutlineInputBorder(),
                ),
                value: currentModule.encoderType,
                items: EncoderType.values.map((type) {
                  return DropdownMenuItem<EncoderType>(
                    value: type,
                    child: Text(encoderTypeToString(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    configProvider.updateEncoderType(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Only show CAN ID field if not using integrated encoder
              if (currentModule.encoderType != EncoderType.integratedEncoder)
                NumberInputField(
                  label: 'Encoder CAN ID',
                  value: currentModule.encoderCanId.toDouble(),
                  onChanged: (value) {
                    configProvider.updateEncoderCanId(value.toInt());
                  },
                  isInteger: true,
                ),
              if (currentModule.encoderType != EncoderType.integratedEncoder)
                const SizedBox(height: 16),
              
              // Only show CAN Bus field for CANCoder
              if (currentModule.encoderType == EncoderType.canCoder)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Encoder CAN Bus Name',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty for default "rio" bus',
                  ),
                  onChanged: (value) {
                    configProvider.updateEncoderCanBus(value);
                  },
                  controller: TextEditingController(text: currentModule.encoderCanBus),
                ),
              if (currentModule.encoderType == EncoderType.canCoder)
                const SizedBox(height: 16),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentModuleIndex > 0)
                    ElevatedButton(
                      onPressed: () {
                        configProvider.previousModule();
                        if (isConnected) {
                          _startMotorEncoderUpdates();
                        }
                      },
                      child: const Text('Previous Module'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleVerificationScreen(),
                        ),
                      );
                    },
                    child: const Text('Next: Verify Module'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
