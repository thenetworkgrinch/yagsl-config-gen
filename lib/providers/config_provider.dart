import 'package:flutter/foundation.dart';
import 'package:frc_swerve_config/models/module_config.dart';
import 'package:frc_swerve_config/models/enums.dart';

class SwerveConfig {
  final List<ModuleConfig> modules;
  final GyroType gyroType;
  final int gyroCAN;
  final String gyroCANBus;
  final NavXConnectionType navXConnectionType;
  
  SwerveConfig({
    required this.modules,
    this.gyroType = GyroType.navX,
    this.gyroCAN = 0,
    this.gyroCANBus = '',
    this.navXConnectionType = NavXConnectionType.mxp,
  });
  
  // Create a copy of this SwerveConfig with optional new values
  SwerveConfig copyWith({
    List<ModuleConfig>? modules,
    GyroType? gyroType,
    int? gyroCAN,
    String? gyroCANBus,
    NavXConnectionType? navXConnectionType,
  }) {
    return SwerveConfig(
      modules: modules ?? this.modules,
      gyroType: gyroType ?? this.gyroType,
      gyroCAN: gyroCAN ?? this.gyroCAN,
      gyroCANBus: gyroCANBus ?? this.gyroCANBus,
      navXConnectionType: navXConnectionType ?? this.navXConnectionType,
    );
  }
  
  // Convert to a Map for serialization
  Map<String, dynamic> toJson() {
    return {
      'modules': modules.map((module) => module.toJson()).toList(),
      'gyroType': gyroType.toString().split('.').last,
      'gyroCAN': gyroCAN,
      'gyroCANBus': gyroCANBus,
      'navXConnectionType': navXConnectionType.toString().split('.').last,
    };
  }
  
  // Create a SwerveConfig from a Map
  factory SwerveConfig.fromJson(Map<String, dynamic> json) {
    return SwerveConfig(
      modules: (json['modules'] as List?)
          ?.map((moduleJson) => ModuleConfig.fromJson(moduleJson))
          .toList() ??
          [],
      gyroType: GyroType.values.firstWhere(
        (e) => e.toString().split('.').last == json['gyroType'],
        orElse: () => GyroType.navX,
      ),
      gyroCAN: json['gyroCAN'] ?? 0,
      gyroCANBus: json['gyroCANBus'] ?? '',
      navXConnectionType: NavXConnectionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['navXConnectionType'],
        orElse: () => NavXConnectionType.mxp,
      ),
    );
  }
}

class ConfigProvider extends ChangeNotifier {
  // Default configuration
  SwerveConfig _config = SwerveConfig(
    modules: [
      ModuleConfig(position: ModulePosition.frontLeft, locationX: -12, locationY: 12),
      ModuleConfig(position: ModulePosition.frontRight, locationX: 12, locationY: 12),
      ModuleConfig(position: ModulePosition.backLeft, locationX: -12, locationY: -12),
      ModuleConfig(position: ModulePosition.backRight, locationX: 12, locationY: -12),
    ],
  );
  
  // Current module index
  int _currentModuleIndex = 0;
  
  // Getters
  SwerveConfig get config => _config;
  int get currentModuleIndex => _currentModuleIndex;
  ModuleConfig get currentModule => _config.modules[_currentModuleIndex];
  
  // Set current module index
  void setCurrentModuleIndex(int index) {
    if (index >= 0 && index < _config.modules.length) {
      _currentModuleIndex = index;
      notifyListeners();
    }
  }
  
  // Move to next module
  void nextModule() {
    if (_currentModuleIndex < _config.modules.length - 1) {
      _currentModuleIndex++;
      notifyListeners();
    }
  }
  
  // Move to previous module
  void previousModule() {
    if (_currentModuleIndex > 0) {
      _currentModuleIndex--;
      notifyListeners();
    }
  }
  
  // Update module location
  void updateModuleLocation(double x, double y) {
    final updatedModule = currentModule.copyWith(
      locationX: x,
      locationY: y,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update drive motor type
  void updateDriveMotorType(MotorType type) {
    final updatedModule = currentModule.copyWith(
      driveMotorType: type,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update drive motor controller
  void updateDriveMotorController(MotorControllerType type) {
    final updatedModule = currentModule.copyWith(
      driveMotorControllerType: type,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update drive CAN ID
  void updateDriveCanId(int id) {
    final updatedModule = currentModule.copyWith(
      driveCanId: id,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update drive CAN bus
  void updateDriveCanBus(String bus) {
    final updatedModule = currentModule.copyWith(
      driveCanBus: bus,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update azimuth motor type
  void updateAzimuthMotorType(MotorType type) {
    final updatedModule = currentModule.copyWith(
      azimuthMotorType: type,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update azimuth motor controller
  void updateAzimuthMotorController(MotorControllerType type) {
    final updatedModule = currentModule.copyWith(
      azimuthMotorControllerType: type,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update azimuth CAN ID
  void updateAzimuthCanId(int id) {
    final updatedModule = currentModule.copyWith(
      azimuthCanId: id,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update azimuth CAN bus
  void updateAzimuthCanBus(String bus) {
    final updatedModule = currentModule.copyWith(
      azimuthCanBus: bus,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update encoder type
  void updateEncoderType(EncoderType type) {
    final updatedModule = currentModule.copyWith(
      encoderType: type,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update encoder CAN ID
  void updateEncoderCanId(int id) {
    final updatedModule = currentModule.copyWith(
      encoderCanId: id,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update encoder CAN bus
  void updateEncoderCanBus(String bus) {
    final updatedModule = currentModule.copyWith(
      encoderCanBus: bus,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update encoder offset
  void updateEncoderOffset(double offset) {
    final updatedModule = currentModule.copyWith(
      encoderOffset: offset,
    );
    
    final updatedModules = List<ModuleConfig>.from(_config.modules);
    updatedModules[_currentModuleIndex] = updatedModule;
    
    _config = _config.copyWith(modules: updatedModules);
    notifyListeners();
  }
  
  // Update gyro type
  void updateGyroType(GyroType type) {
    _config = _config.copyWith(gyroType: type);
    notifyListeners();
  }
  
  // Update gyro CAN ID
  void updateGyroCAN(int id) {
    _config = _config.copyWith(gyroCAN: id);
    notifyListeners();
  }
  
  // Update gyro CAN bus
  void updateGyroCANBus(String bus) {
    _config = _config.copyWith(gyroCANBus: bus);
    notifyListeners();
  }
  
  // Update NavX connection type
  void updateNavXConnectionType(NavXConnectionType type) {
    _config = _config.copyWith(navXConnectionType: type);
    notifyListeners();
  }
}
