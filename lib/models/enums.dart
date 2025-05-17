/// Enum representing the position of a swerve module on the robot
enum ModulePosition {
  frontLeft,
  frontRight,
  backLeft,
  backRight,
}

/// Enum representing the type of motor
enum MotorType {
  neo,
  neoVortex,
  falcon,
  falcon500,
  kraken,
  other,
}

/// Enum representing the type of motor controller
enum MotorControllerType {
  sparkMax,
  sparkFlex,
  talonFX,
  talonFXS,
  talonSRX,
  victorSPX,
  other,
}

/// Enum representing the type of absolute encoder
enum EncoderType {
  canCoder,
  ctre,
  rev,
  ma3,
  thrifty,
  dutyCycle,
  analogAbsolute,
  integratedEncoder,
  other,
}

/// Enum representing the type of gyroscope
enum GyroType {
  navX,
  pigeon,
  pigeon2,
  adis16448,
  adis16470,
  analog,
  other,
}

/// Enum representing the connection type for NavX
enum NavXConnectionType {
  mxp,
  usb,
  i2c,
  spi,
}

/// Convert ModulePosition to a human-readable string
String modulePositionToString(ModulePosition position) {
  switch (position) {
    case ModulePosition.frontLeft:
      return 'Front Left';
    case ModulePosition.frontRight:
      return 'Front Right';
    case ModulePosition.backLeft:
      return 'Back Left';
    case ModulePosition.backRight:
      return 'Back Right';
  }
}

/// Convert MotorType to a human-readable string
String motorTypeToString(MotorType type) {
  switch (type) {
    case MotorType.neo:
      return 'NEO';
    case MotorType.neoVortex:
      return 'NEO Vortex';
    case MotorType.falcon:
      return 'Falcon';
    case MotorType.falcon500:
      return 'Falcon 500';
    case MotorType.kraken:
      return 'Kraken X60';
    case MotorType.other:
      return 'Other';
  }
}

/// Convert MotorControllerType to a human-readable string
String motorControllerTypeToString(MotorControllerType type) {
  switch (type) {
    case MotorControllerType.sparkMax:
      return 'SPARK MAX';
    case MotorControllerType.sparkFlex:
      return 'SPARK FLEX';
    case MotorControllerType.talonFX:
      return 'Talon FX';
    case MotorControllerType.talonFXS:
      return 'Talon FX (S)';
    case MotorControllerType.talonSRX:
      return 'Talon SRX';
    case MotorControllerType.victorSPX:
      return 'Victor SPX';
    case MotorControllerType.other:
      return 'Other';
  }
}

/// Convert EncoderType to a human-readable string
String encoderTypeToString(EncoderType type) {
  switch (type) {
    case EncoderType.canCoder:
      return 'CANCoder';
    case EncoderType.ctre:
      return 'CTRE Encoder';
    case EncoderType.rev:
      return 'REV Encoder';
    case EncoderType.ma3:
      return 'MA3 Encoder';
    case EncoderType.thrifty:
      return 'Thrifty Encoder';
    case EncoderType.dutyCycle:
      return 'Duty Cycle Encoder';
    case EncoderType.analogAbsolute:
      return 'Analog Absolute Encoder';
    case EncoderType.integratedEncoder:
      return 'Integrated Encoder';
    case EncoderType.other:
      return 'Other';
  }
}

/// Convert GyroType to a human-readable string
String gyroTypeToString(GyroType type) {
  switch (type) {
    case GyroType.navX:
      return 'NavX';
    case GyroType.pigeon:
      return 'Pigeon IMU';
    case GyroType.pigeon2:
      return 'Pigeon 2.0';
    case GyroType.adis16448:
      return 'ADIS16448';
    case GyroType.adis16470:
      return 'ADIS16470';
    case GyroType.analog:
      return 'Analog Gyro';
    case GyroType.other:
      return 'Other';
  }
}

/// Convert NavXConnectionType to a human-readable string
String navXConnectionTypeToString(NavXConnectionType type) {
  switch (type) {
    case NavXConnectionType.mxp:
      return 'MXP';
    case NavXConnectionType.usb:
      return 'USB';
    case NavXConnectionType.i2c:
      return 'I2C';
    case NavXConnectionType.spi:
      return 'SPI';
  }
}

/// Convert NavXConnectionType to a YAGSL type string
String navXConnectionTypeToYagslType(NavXConnectionType type) {
  switch (type) {
    case NavXConnectionType.mxp:
      return 'navx';
    case NavXConnectionType.usb:
      return 'navx_usb';
    case NavXConnectionType.i2c:
      return 'navx_i2c';
    case NavXConnectionType.spi:
      return 'navx_spi';
  }
}

/// Convert MotorType to a YAGSL type string
String motorTypeToYagslType(MotorType type) {
  switch (type) {
    case MotorType.neo:
      return 'neo';
    case MotorType.neoVortex:
      return 'neo_vortex';
    case MotorType.falcon:
      return 'falcon';
    case MotorType.falcon500:
      return 'falcon_500';
    case MotorType.kraken:
      return 'kraken';
    case MotorType.other:
      return 'other';
  }
}

/// Convert MotorControllerType to a YAGSL type string
String motorControllerTypeToYagslType(MotorControllerType type) {
  switch (type) {
    case MotorControllerType.sparkMax:
      return 'sparkmax';
    case MotorControllerType.sparkFlex:
      return 'sparkflex';
    case MotorControllerType.talonFX:
      return 'talonfx';
    case MotorControllerType.talonFXS:
      return 'talonfx_s';
    case MotorControllerType.talonSRX:
      return 'talonsrx';
    case MotorControllerType.victorSPX:
      return 'victorspx';
    case MotorControllerType.other:
      return 'other';
  }
}

/// Convert EncoderType to a YAGSL type string
String encoderTypeToYagslType(EncoderType type) {
  switch (type) {
    case EncoderType.canCoder:
      return 'cancoder';
    case EncoderType.ctre:
      return 'ctre';
    case EncoderType.rev:
      return 'rev';
    case EncoderType.ma3:
      return 'ma3';
    case EncoderType.thrifty:
      return 'thrifty';
    case EncoderType.dutyCycle:
      return 'dutycycle';
    case EncoderType.analogAbsolute:
      return 'analogabsolute';
    case EncoderType.integratedEncoder:
      return 'integrated';
    case EncoderType.other:
      return 'other';
  }
}

/// Convert GyroType to a YAGSL type string
String gyroTypeToYagslType(GyroType type) {
  switch (type) {
    case GyroType.navX:
      return 'navx'; // This will be overridden by navXConnectionTypeToYagslType
    case GyroType.pigeon:
      return 'pigeon';
    case GyroType.pigeon2:
      return 'pigeon2';
    case GyroType.adis16448:
      return 'adis16448';
    case GyroType.adis16470:
      return 'adis16470';
    case GyroType.analog:
      return 'analog';
    case GyroType.other:
      return 'other';
  }
}
