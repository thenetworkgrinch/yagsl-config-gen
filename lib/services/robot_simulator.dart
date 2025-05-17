import 'dart:async';
import 'dart:math' as math;
import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/services/nt4_client.dart';

/// This class simulates a robot's NetworkTables server for testing purposes.
/// In a real implementation, this would be running on the robot.
class RobotSimulator {
  static final RobotSimulator _instance = RobotSimulator._internal();
  static RobotSimulator get instance => _instance;
  
  RobotSimulator._internal();
  
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  
  Timer? _simulationTimer;
  final Map<String, dynamic> _ntValues = {};
  
  // Start the simulator
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _initializeValues();
    
    // Update values periodically
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateSimulation();
    });
  }
  
  // Stop the simulator
  void stop() {
    _isRunning = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
  
  // Initialize default values
  void _initializeValues() {
    // Initialize encoder values for each module
    for (var position in ModulePosition.values) {
      final moduleName = modulePositionToString(position).replaceAll(' ', '').toLowerCase();
      _ntValues['/SwerveTuning/$moduleName/encoderValue'] = 0.0;
      _ntValues['/SwerveTuning/$moduleName/motorEncoderValue'] = 0.0;
      _ntValues['/SwerveTuning/$moduleName/driveSpeed'] = 0.0;
      _ntValues['/SwerveTuning/$moduleName/azimuthSpeed'] = 0.0;
      _ntValues['/SwerveTuning/$moduleName/encoderOffset'] = 0.0;
    }
    
    // Initialize test flags
    _ntValues['/SwerveTuning/test/driveTest'] = false;
    _ntValues['/SwerveTuning/test/driveStraightTest'] = false;
    _ntValues['/SwerveTuning/test/rotationTest'] = false;
    
    // Initialize PID values
    _ntValues['/SwerveTuning/azimuthPID/p'] = 0.5;
    _ntValues['/SwerveTuning/azimuthPID/i'] = 0.0;
    _ntValues['/SwerveTuning/azimuthPID/d'] = 0.1;
    _ntValues['/SwerveTuning/drivePID/p'] = 0.1;
    _ntValues['/SwerveTuning/drivePID/i'] = 0.0;
    _ntValues['/SwerveTuning/drivePID/d'] = 0.0;
    
    // Initialize target values
    _ntValues['/SwerveTuning/azimuthTarget'] = 0.0;
  }
  
  // Update simulation values
  void _updateSimulation() {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final random = math.Random();
    
    // Update encoder values based on current state
    for (var position in ModulePosition.values) {
      final moduleName = modulePositionToString(position).replaceAll(' ', '').toLowerCase();
      final encoderKey = '/SwerveTuning/$moduleName/encoderValue';
      final motorEncoderKey = '/SwerveTuning/$moduleName/motorEncoderValue';
      final driveSpeedKey = '/SwerveTuning/$moduleName/driveSpeed';
      final azimuthSpeedKey = '/SwerveTuning/$moduleName/azimuthSpeed';
      
      // Get current values
      double encoderValue = _ntValues[encoderKey] ?? 0.0;
      double motorEncoderValue = _ntValues[motorEncoderKey] ?? 0.0;
      double driveSpeed = _ntValues[driveSpeedKey] ?? 0.0;
      double azimuthSpeed = _ntValues[azimuthSpeedKey] ?? 0.0;
      
      // Update encoder values based on azimuth speed
      if (azimuthSpeed != 0) {
        encoderValue = (encoderValue + azimuthSpeed * 5) % 360;
        motorEncoderValue = (motorEncoderValue + azimuthSpeed * 5) % 360;
      }
      
      // Add some noise to encoder readings
      encoderValue += (random.nextDouble() - 0.5) * 0.2;
      motorEncoderValue += (random.nextDouble() - 0.5) * 0.2;
      
      // Handle drive straight test
      if (_ntValues['/SwerveTuning/test/driveStraightTest'] == true) {
        encoderValue = encoderValue * 0.9; // Gradually move toward 0
        motorEncoderValue = motorEncoderValue * 0.9;
        driveSpeed = 0.3; // Slow forward speed
      }
      
      // Handle rotation test
      if (_ntValues['/SwerveTuning/test/rotationTest'] == true) {
        // Calculate angle for rotation based on module position
        double targetAngle = 0;
        switch (position) {
          case ModulePosition.frontLeft:
            targetAngle = 135;
            break;
          case ModulePosition.frontRight:
            targetAngle = 45;
            break;
          case ModulePosition.backLeft:
            targetAngle = -135;
            break;
          case ModulePosition.backRight:
            targetAngle = -45;
            break;
        }
        
        // Gradually move toward target angle
        double diff = (targetAngle - encoderValue) % 360;
        if (diff > 180) diff -= 360;
        encoderValue += diff * 0.1;
        motorEncoderValue += diff * 0.1;
        
        driveSpeed = 0.2; // Slow speed for rotation
      }
      
      // Update values
      _ntValues[encoderKey] = encoderValue;
      _ntValues[motorEncoderKey] = motorEncoderValue;
      _ntValues[driveSpeedKey] = driveSpeed;
      
      // Publish updated values to NT
      NT4Client.instance.publish(encoderKey, encoderValue, DataType.double);
      NT4Client.instance.publish(motorEncoderKey, motorEncoderValue, DataType.double);
    }
  }
  
  // Get a value from the simulator
  dynamic getValue(String key) {
    return _ntValues[key];
  }
  
  // Set a value in the simulator
  void setValue(String key, dynamic value) {
    _ntValues[key] = value;
  }
}
