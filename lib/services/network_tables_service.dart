import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/services/nt4_client.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class NetworkTablesService {
  static final NetworkTablesService _instance = NetworkTablesService._internal();
  static NetworkTablesService get instance => _instance;
  
  NetworkTablesService._internal();
  
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  ConnectionStatus get connectionStatus => _connectionStatus;
  
  String? _connectedAddress;
  String? get connectedAddress => _connectedAddress;
  
  // Stream controller for connection status updates
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  
  // Subscription IDs for cleanup
  final Map<String, int> _subscriptionIds = {};
  
  // Check if a NetworkTables server is running on localhost
  Future<bool> isLocalServerAvailable() async {
    try {
      _connectionStatus = ConnectionStatus.connecting;
      _connectionStatusController.add(_connectionStatus);
      
      // Try to connect to localhost
      final socket = await Socket.connect('127.0.0.1', 5810, timeout: const Duration(seconds: 1));
      await socket.close();
      
      return true;
    } catch (e) {
      print('Local NT server not available: $e');
      return false;
    } finally {
      if (_connectionStatus == ConnectionStatus.connecting) {
        _connectionStatus = ConnectionStatus.disconnected;
        _connectionStatusController.add(_connectionStatus);
      }
    }
  }
  
  // Connect to a NetworkTables server at the specified address
  Future<bool> connectToServer(String address) async {
    try {
      _connectionStatus = ConnectionStatus.connecting;
      _connectionStatusController.add(_connectionStatus);
      
      final success = await NT4Client.instance.connect(address);
      
      if (success) {
        _connectionStatus = ConnectionStatus.connected;
        _connectedAddress = address;
      } else {
        _connectionStatus = ConnectionStatus.disconnected;
        _connectedAddress = null;
      }
      
      _connectionStatusController.add(_connectionStatus);
      return success;
    } catch (e) {
      print('Failed to connect to NT server at $address: $e');
      _connectionStatus = ConnectionStatus.disconnected;
      _connectedAddress = null;
      _connectionStatusController.add(_connectionStatus);
      return false;
    }
  }
  
  // Connect to a NetworkTables server on the robot using team number
  Future<bool> connectToRobot(int teamNumber) async {
    // Format team number for IP address (e.g., 1234 -> 12.34)
    final teamStr = teamNumber.toString().padLeft(4, '0');
    final teamIp = '10.${teamStr.substring(0, 2)}.${teamStr.substring(2, 4)}.2';
    final mDns = 'roboRIO-$teamNumber-FRC.local';
    final usbAddress = '172.22.11.2';
    
    // Try connecting to each address
    if (await connectToServer(teamIp)) {
      return true;
    }
    
    if (await connectToServer(mDns)) {
      return true;
    }
    
    return await connectToServer(usbAddress);
  }
  
  // Disconnect from the current NetworkTables server
  Future<void> disconnect() async {
    await NT4Client.instance.disconnect();
    _connectionStatus = ConnectionStatus.disconnected;
    _connectedAddress = null;
    _connectionStatusController.add(_connectionStatus);
  }
  
  // Check if connected to NetworkTables
  bool get isConnected => NT4Client.instance.isConnected;
  
  // Simple connect method that delegates to connectToServer
  Future<bool> connect() async {
    return await connectToServer('127.0.0.1');
  }
  
  // Get the NT topic path for a module's encoder value
  String _getEncoderValueTopic(ModulePosition modulePosition) {
    final moduleName = modulePositionToString(modulePosition).replaceAll(' ', '').toLowerCase();
    return '/SwerveTuning/$moduleName/encoderValue';
  }
  
  // Get the NT topic path for a module's motor encoder value
  String _getMotorEncoderValueTopic(ModulePosition modulePosition) {
    final moduleName = modulePositionToString(modulePosition).replaceAll(' ', '').toLowerCase();
    return '/SwerveTuning/$moduleName/motorEncoderValue';
  }
  
  // Get the NT topic path for a module's drive motor speed
  String _getDriveMotorSpeedTopic(ModulePosition modulePosition) {
    final moduleName = modulePositionToString(modulePosition).replaceAll(' ', '').toLowerCase();
    return '/SwerveTuning/$moduleName/driveSpeed';
  }
  
  // Get the NT topic path for a module's azimuth motor speed
  String _getAzimuthMotorSpeedTopic(ModulePosition modulePosition) {
    final moduleName = modulePositionToString(modulePosition).replaceAll(' ', '').toLowerCase();
    return '/SwerveTuning/$moduleName/azimuthSpeed';
  }
  
  // Get the NT topic path for a module's encoder offset
  String _getEncoderOffsetTopic(ModulePosition modulePosition) {
    final moduleName = modulePositionToString(modulePosition).replaceAll(' ', '').toLowerCase();
    return '/SwerveTuning/$moduleName/encoderOffset';
  }
  
  // Subscribe to encoder value
  void subscribeToEncoderValue({
    required ModulePosition modulePosition,
    required void Function(double) onValueChanged,
  }) {
    final topic = _getEncoderValueTopic(modulePosition);
    final subscriptionKey = 'encoder_${modulePosition.toString()}';
    
    // Unsubscribe if already subscribed
    if (_subscriptionIds.containsKey(subscriptionKey)) {
      NT4Client.instance.unsubscribe(_subscriptionIds[subscriptionKey]!);
    }
    
    // Subscribe to the topic
    final subId = NT4Client.instance.subscribe(
      [topic],
      [],
      (topic, value, timestamp) {
        if (value is num) {
          onValueChanged(value.toDouble());
        }
      },
    );
    
    _subscriptionIds[subscriptionKey] = subId;
  }
  
  // Subscribe to motor encoder value
  void subscribeToMotorEncoderValue({
    required ModulePosition modulePosition,
    required void Function(double) onValueChanged,
  }) {
    final topic = _getMotorEncoderValueTopic(modulePosition);
    final subscriptionKey = 'motorEncoder_${modulePosition.toString()}';
    
    // Unsubscribe if already subscribed
    if (_subscriptionIds.containsKey(subscriptionKey)) {
      NT4Client.instance.unsubscribe(_subscriptionIds[subscriptionKey]!);
    }
    
    // Subscribe to the topic
    final subId = NT4Client.instance.subscribe(
      [topic],
      [],
      (topic, value, timestamp) {
        if (value is num) {
          onValueChanged(value.toDouble());
        }
      },
    );
    
    _subscriptionIds[subscriptionKey] = subId;
  }
  
  // Set drive motor speed
  void setDriveMotorSpeed({
    required ModulePosition modulePosition,
    required double speed,
  }) {
    final topic = _getDriveMotorSpeedTopic(modulePosition);
    NT4Client.instance.publish(topic, speed, DataType.double);
  }
  
  // Set azimuth motor speed
  void setAzimuthMotorSpeed({
    required ModulePosition modulePosition,
    required double speed,
  }) {
    final topic = _getAzimuthMotorSpeedTopic(modulePosition);
    NT4Client.instance.publish(topic, speed, DataType.double);
  }
  
  // Subscribe to all module angles
  void subscribeToAllModuleAngles({
    required void Function(List<double>) onValueChanged,
  }) {
    final subscriptionKey = 'allModuleAngles';
    
    // Unsubscribe if already subscribed
    if (_subscriptionIds.containsKey(subscriptionKey)) {
      NT4Client.instance.unsubscribe(_subscriptionIds[subscriptionKey]!);
    }
    
    // Create topics for all modules
    final topics = ModulePosition.values.map((pos) => _getEncoderValueTopic(pos)).toList();
    
    // Track values for all modules
    final values = List<double>.filled(4, 0.0);
    
    // Subscribe to all topics
    final subId = NT4Client.instance.subscribe(
      topics,
      [],
      (topic, value, timestamp) {
        if (value is! num) return;
        
        // Determine which module this is for
        for (int i = 0; i < ModulePosition.values.length; i++) {
          if (topic == _getEncoderValueTopic(ModulePosition.values[i])) {
            values[i] = value.toDouble();
            break;
          }
        }
        
        // Notify with all values
        onValueChanged(List<double>.from(values));
      },
    );
    
    _subscriptionIds[subscriptionKey] = subId;
  }
  
  // Set azimuth PID values
  void setAzimuthPid({
    required double p,
    required double i,
    required double d,
  }) {
    NT4Client.instance.publish('/SwerveTuning/azimuthPID/p', p, DataType.double);
    NT4Client.instance.publish('/SwerveTuning/azimuthPID/i', i, DataType.double);
    NT4Client.instance.publish('/SwerveTuning/azimuthPID/d', d, DataType.double);
  }
  
  // Set azimuth target angle
  void setAzimuthTarget({
    required double angle,
  }) {
    NT4Client.instance.publish('/SwerveTuning/azimuthTarget', angle, DataType.double);
  }
  
  // Subscribe to all module speeds
  void subscribeToAllModuleSpeeds({
    required void Function(List<double>) onValueChanged,
  }) {
    final subscriptionKey = 'allModuleSpeeds';
    
    // Unsubscribe if already subscribed
    if (_subscriptionIds.containsKey(subscriptionKey)) {
      NT4Client.instance.unsubscribe(_subscriptionIds[subscriptionKey]!);
    }
    
    // Create topics for all modules
    final topics = ModulePosition.values.map((pos) => _getDriveMotorSpeedTopic(pos)).toList();
    
    // Track values for all modules
    final values = List<double>.filled(4, 0.0);
    
    // Subscribe to all topics
    final subId = NT4Client.instance.subscribe(
      topics,
      [],
      (topic, value, timestamp) {
        if (value is! num) return;
        
        // Determine which module this is for
        for (int i = 0; i < ModulePosition.values.length; i++) {
          if (topic == _getDriveMotorSpeedTopic(ModulePosition.values[i])) {
            values[i] = value.toDouble();
            break;
          }
        }
        
        // Notify with all values
        onValueChanged(List<double>.from(values));
      },
    );
    
    _subscriptionIds[subscriptionKey] = subId;
  }
  
  // Set drive PID values
  void setDrivePid({
    required double p,
    required double i,
    required double d,
  }) {
    NT4Client.instance.publish('/SwerveTuning/drivePID/p', p, DataType.double);
    NT4Client.instance.publish('/SwerveTuning/drivePID/i', i, DataType.double);
    NT4Client.instance.publish('/SwerveTuning/drivePID/d', d, DataType.double);
  }
  
  // Start drive test
  void startDriveTest() {
    NT4Client.instance.publish('/SwerveTuning/test/driveTest', true, DataType.boolean);
  }
  
  // Stop drive test
  void stopDriveTest() {
    NT4Client.instance.publish('/SwerveTuning/test/driveTest', false, DataType.boolean);
  }
  
  // Start drive straight test
  void startDriveStraightTest() {
    NT4Client.instance.publish('/SwerveTuning/test/driveStraightTest', true, DataType.boolean);
  }
  
  // Start rotation test
  void startRotationTest() {
    NT4Client.instance.publish('/SwerveTuning/test/rotationTest', true, DataType.boolean);
  }
  
  // Stop all tests
  void stopAllTests() {
    NT4Client.instance.publish('/SwerveTuning/test/driveTest', false, DataType.boolean);
    NT4Client.instance.publish('/SwerveTuning/test/driveStraightTest', false, DataType.boolean);
    NT4Client.instance.publish('/SwerveTuning/test/rotationTest', false, DataType.boolean);
  }
  
  // Update module encoder offset
  void updateModuleEncoderOffset({
    required ModulePosition modulePosition,
    required double offset,
  }) {
    final topic = _getEncoderOffsetTopic(modulePosition);
    NT4Client.instance.publish(topic, offset, DataType.double);
  }
  
  // Clean up resources
  void dispose() {
    // Unsubscribe from all topics
    for (var id in _subscriptionIds.values) {
      NT4Client.instance.unsubscribe(id);
    }
    _subscriptionIds.clear();
    
    // Disconnect from NT server
    NT4Client.instance.dispose();
    _connectionStatusController.close();
  }
}
