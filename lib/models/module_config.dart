import 'package:frc_swerve_config/models/enums.dart';

class ModuleConfig {
  ModulePosition position;
  double locationX;
  double locationY;
  
  MotorType driveMotorType;
  MotorControllerType driveMotorControllerType;
  int driveCanId;
  String driveCanBus;
  
  MotorType azimuthMotorType;
  MotorControllerType azimuthMotorControllerType;
  int azimuthCanId;
  String azimuthCanBus;
  
  EncoderType encoderType;
  int encoderCanId;
  String encoderCanBus;
  double encoderOffset;
  
  ModuleConfig({
    required this.position,
    this.locationX = 0.0,
    this.locationY = 0.0,
    this.driveMotorType = MotorType.neo,
    this.driveMotorControllerType = MotorControllerType.sparkMax,
    this.driveCanId = 0,
    this.driveCanBus = '',
    this.azimuthMotorType = MotorType.neo,
    this.azimuthMotorControllerType = MotorControllerType.sparkMax,
    this.azimuthCanId = 0,
    this.azimuthCanBus = '',
    this.encoderType = EncoderType.canCoder,
    this.encoderCanId = 0,
    this.encoderCanBus = '',
    this.encoderOffset = 0.0,
  });
  
  // Create a copy of this ModuleConfig with optional new values
  ModuleConfig copyWith({
    ModulePosition? position,
    double? locationX,
    double? locationY,
    MotorType? driveMotorType,
    MotorControllerType? driveMotorControllerType,
    int? driveCanId,
    String? driveCanBus,
    MotorType? azimuthMotorType,
    MotorControllerType? azimuthMotorControllerType,
    int? azimuthCanId,
    String? azimuthCanBus,
    EncoderType? encoderType,
    int? encoderCanId,
    String? encoderCanBus,
    double? encoderOffset,
  }) {
    return ModuleConfig(
      position: position ?? this.position,
      locationX: locationX ?? this.locationX,
      locationY: locationY ?? this.locationY,
      driveMotorType: driveMotorType ?? this.driveMotorType,
      driveMotorControllerType: driveMotorControllerType ?? this.driveMotorControllerType,
      driveCanId: driveCanId ?? this.driveCanId,
      driveCanBus: driveCanBus ?? this.driveCanBus,
      azimuthMotorType: azimuthMotorType ?? this.azimuthMotorType,
      azimuthMotorControllerType: azimuthMotorControllerType ?? this.azimuthMotorControllerType,
      azimuthCanId: azimuthCanId ?? this.azimuthCanId,
      azimuthCanBus: azimuthCanBus ?? this.azimuthCanBus,
      encoderType: encoderType ?? this.encoderType,
      encoderCanId: encoderCanId ?? this.encoderCanId,
      encoderCanBus: encoderCanBus ?? this.encoderCanBus,
      encoderOffset: encoderOffset ?? this.encoderOffset,
    );
  }
  
  // Convert to a Map for serialization
  Map<String, dynamic> toJson() {
    return {
      'position': position.toString().split('.').last,
      'locationX': locationX,
      'locationY': locationY,
      'driveMotorType': driveMotorType.toString().split('.').last,
      'driveMotorControllerType': driveMotorControllerType.toString().split('.').last,
      'driveCanId': driveCanId,
      'driveCanBus': driveCanBus,
      'azimuthMotorType': azimuthMotorType.toString().split('.').last,
      'azimuthMotorControllerType': azimuthMotorControllerType.toString().split('.').last,
      'azimuthCanId': azimuthCanId,
      'azimuthCanBus': azimuthCanBus,
      'encoderType': encoderType.toString().split('.').last,
      'encoderCanId': encoderCanId,
      'encoderCanBus': encoderCanBus,
      'encoderOffset': encoderOffset,
    };
  }
  
  // Create a ModuleConfig from a Map
  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      position: ModulePosition.values.firstWhere(
        (e) => e.toString().split('.').last == json['position'],
        orElse: () => ModulePosition.frontLeft,
      ),
      locationX: json['locationX'] ?? 0.0,
      locationY: json['locationY'] ?? 0.0,
      driveMotorType: MotorType.values.firstWhere(
        (e) => e.toString().split('.').last == json['driveMotorType'],
        orElse: () => MotorType.neo,
      ),
      driveMotorControllerType: MotorControllerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['driveMotorControllerType'],
        orElse: () => MotorControllerType.sparkMax,
      ),
      driveCanId: json['driveCanId'] ?? 0,
      driveCanBus: json['driveCanBus'] ?? '',
      azimuthMotorType: MotorType.values.firstWhere(
        (e) => e.toString().split('.').last == json['azimuthMotorType'],
        orElse: () => MotorType.neo,
      ),
      azimuthMotorControllerType: MotorControllerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['azimuthMotorControllerType'],
        orElse: () => MotorControllerType.sparkMax,
      ),
      azimuthCanId: json['azimuthCanId'] ?? 0,
      azimuthCanBus: json['azimuthCanBus'] ?? '',
      encoderType: EncoderType.values.firstWhere(
        (e) => e.toString().split('.').last == json['encoderType'],
        orElse: () => EncoderType.canCoder,
      ),
      encoderCanId: json['encoderCanId'] ?? 0,
      encoderCanBus: json['encoderCanBus'] ?? '',
      encoderOffset: json['encoderOffset'] ?? 0.0,
    );
  }
}
