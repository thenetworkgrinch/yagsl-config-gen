import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frc_swerve_config/providers/config_provider.dart';
import 'dart:convert';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _exportedJson = '';
  bool _showCopiedMessage = false;
  
  @override
  void initState() {
    super.initState();
    _generateExportJson();
  }
  
  void _generateExportJson() {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final config = configProvider.config;
    
    // Convert the config to YAGSL format
    final Map<String, dynamic> yagslConfig = _convertToYagslFormat(config);
    
    // Convert to pretty JSON
    final encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(yagslConfig);
    
    setState(() {
      _exportedJson = jsonString;
    });
  }
  
  Map<String, dynamic> _convertToYagslFormat(SwerveConfig config) {
    // This is a simplified version of the YAGSL config format
    // In a real implementation, this would generate the full YAGSL config
    
    final Map<String, dynamic> yagslConfig = {
      'robotWidth': 0.6, // Default values in meters
      'robotLength': 0.6,
      'gyro': _generateGyroConfig(config),
      'modules': _generateModulesConfig(config),
    };
    
    return yagslConfig;
  }
  
  Map<String, dynamic> _generateGyroConfig(SwerveConfig config) {
    final Map<String, dynamic> gyroConfig = {
      'type': config.gyroType == GyroType.navX 
          ? navXConnectionTypeToYagslType(config.navXConnectionType)
          : gyroTypeToYagslType(config.gyroType),
    };
    
    // Add CAN ID if applicable
    if (config.gyroType != GyroType.navX && config.gyroCAN > 0) {
      gyroConfig['id'] = config.gyroCAN;
    }
    
    // Add CAN bus if applicable
    if (config.gyroType != GyroType.navX && config.gyroCANBus.isNotEmpty) {
      gyroConfig['canbus'] = config.gyroCANBus;
    }
    
    return gyroConfig;
  }
  
  List<Map<String, dynamic>> _generateModulesConfig(SwerveConfig config) {
    return config.modules.map((module) {
      // Convert inches to meters for YAGSL
      final double locationXMeters = module.locationX * 0.0254;
      final double locationYMeters = module.locationY * 0.0254;
      
      return {
        'name': modulePositionToString(module.position).replaceAll(' ', ''),
        'position': {
          'x': locationXMeters,
          'y': locationYMeters,
        },
        'drive': {
          'type': motorControllerTypeToYagslType(module.driveMotorControllerType),
          'id': module.driveCanId,
          'canbus': module.driveCanBus.isNotEmpty ? module.driveCanBus : 'rio',
        },
        'angle': {
          'type': motorControllerTypeToYagslType(module.azimuthMotorControllerType),
          'id': module.azimuthCanId,
          'canbus': module.azimuthCanBus.isNotEmpty ? module.azimuthCanBus : 'rio',
        },
        'encoder': {
          'type': encoderTypeToYagslType(module.encoderType),
          'id': module.encoderCanId,
          'canbus': module.encoderCanBus.isNotEmpty ? module.encoderCanBus : 'rio',
          'offset': module.encoderOffset,
        },
        'inverted': {
          'drive': false,
          'angle': false,
        },
        'absoluteEncoderOffset': module.encoderOffset,
      };
    }).toList();
  }
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _exportedJson));
    
    setState(() {
      _showCopiedMessage = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCopiedMessage = false;
        });
      }
    });
  }
  
  void _saveToFile() {
    // In a real implementation, this would save the JSON to a file
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving to file is not implemented in this demo'),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YAGSL Configuration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your swerve drive configuration has been converted to YAGSL format. Copy this JSON and save it to your robot project.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // JSON display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _exportedJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _saveToFile,
                  icon: const Icon(Icons.save),
                  label: const Text('Save to File'),
                ),
              ],
            ),
            
            // Copied message
            if (_showCopiedMessage)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'Copied to clipboard!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Navigation buttons
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
                  onPressed: () {
                    // Navigate back to the home screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Finish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
