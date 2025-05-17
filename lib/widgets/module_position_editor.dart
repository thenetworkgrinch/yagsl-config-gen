import 'package:flutter/material.dart';
import 'package:frc_swerve_config/models/enums.dart';
import 'package:frc_swerve_config/models/module_config.dart';
import 'dart:math' as math;

class ModulePositionEditor extends StatefulWidget {
  final List<ModuleConfig> modules;
  final int selectedModuleIndex;
  final Function(int) onModuleSelected;
  final double encoderOffset;
  final double? motorEncoderValue;

  const ModulePositionEditor({
    super.key,
    required this.modules,
    required this.selectedModuleIndex,
    required this.onModuleSelected,
    required this.encoderOffset,
    this.motorEncoderValue,
  });

  @override
  State<ModulePositionEditor> createState() => _ModulePositionEditorState();
}

class _ModulePositionEditorState extends State<ModulePositionEditor> {
  // Grid settings
  final double _gridSize = 20.0; // Size of grid cells in pixels
  final double _robotWidth = 200.0; // Width of robot in pixels
  final double _robotHeight = 200.0; // Height of robot in pixels
  final double _moduleSize = 40.0; // Size of module representation in pixels
  
  // Scaling factor (pixels to inches)
  late double _scale;
  
  @override
  void initState() {
    super.initState();
    // Calculate scale based on the robot dimensions
    _calculateScale();
  }
  
  void _calculateScale() {
    // Find the maximum X and Y positions to determine scale
    double maxX = 0;
    double maxY = 0;
    
    for (var module in widget.modules) {
      maxX = math.max(maxX, module.locationX.abs());
      maxY = math.max(maxY, module.locationY.abs());
    }
    
    // Default to 10 inches if no modules are positioned yet
    maxX = maxX == 0 ? 10 : maxX;
    maxY = maxY == 0 ? 10 : maxY;
    
    // Calculate scale (pixels per inch)
    _scale = math.min(
      (_robotWidth / 2) / maxX,
      (_robotHeight / 2) / maxY,
    );
  }
  
  // Convert inches to pixels
  double _inchesToPixels(double inches) {
    return inches * _scale;
  }
  
  // Get module position in pixels
  Offset _getModulePixelPosition(ModuleConfig module) {
    return Offset(
      _robotWidth / 2 + _inchesToPixels(module.locationX),
      _robotHeight / 2 - _inchesToPixels(module.locationY), // Y is inverted in UI
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Grid background
              CustomPaint(
                size: Size(constraints.maxWidth, 350),
                painter: GridPainter(
                  gridSize: _gridSize,
                  robotWidth: _robotWidth,
                  robotHeight: _robotHeight,
                ),
              ),
              
              // Robot outline
              Center(
                child: Container(
                  width: _robotWidth,
                  height: _robotHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Robot direction indicator
                      Positioned(
                        top: 10,
                        left: _robotWidth / 2 - 15,
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
                      
                      // Coordinate system
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Text('+X = Front', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Transform.rotate(
                                  angle: -math.pi / 2,
                                  child: const Icon(Icons.arrow_upward, size: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('+Y = Left', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_back, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Modules
              ...widget.modules.asMap().entries.map((entry) {
                final index = entry.key;
                final module = entry.value;
                final position = _getModulePixelPosition(module);
                
                return Positioned(
                  left: position.dx - _moduleSize / 2,
                  top: position.dy - _moduleSize / 2,
                  child: GestureDetector(
                    onTap: () {
                      widget.onModuleSelected(index);
                    },
                    child: ModuleWidget(
                      modulePosition: module.position,
                      isSelected: index == widget.selectedModuleIndex,
                      encoderOffset: index == widget.selectedModuleIndex ? widget.encoderOffset : 0,
                      motorEncoderValue: index == widget.selectedModuleIndex ? widget.motorEncoderValue : null,
                      size: _moduleSize,
                    ),
                  ),
                );
              }).toList(),
              
              // Legend
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Module Legend:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Front Left'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Front Right'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Back Left'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Back Right'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 2,
                            color: Colors.white,
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Absolute Encoder'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 2,
                            color: Colors.yellow,
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
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
              ),
              
              // Instructions
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use numeric fields to set precise module positions',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Click on a module to select it',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Arrows show encoder orientations',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  final double robotWidth;
  final double robotHeight;
  
  GridPainter({
    required this.gridSize,
    required this.robotWidth,
    required this.robotHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Center point for the robot
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw vertical grid lines
    for (double x = centerX % gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal grid lines
    for (double y = centerY % gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw coordinate axes
    final axisPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 1;
    
    // X-axis
    canvas.drawLine(
      Offset(centerX - robotWidth / 2, centerY),
      Offset(centerX + robotWidth / 2, centerY),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      Offset(centerX, centerY - robotHeight / 2),
      Offset(centerX, centerY + robotHeight / 2),
      axisPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ModuleWidget extends StatelessWidget {
  final ModulePosition modulePosition;
  final bool isSelected;
  final double encoderOffset;
  final double? motorEncoderValue;
  final double size;
  
  const ModuleWidget({
    super.key,
    required this.modulePosition,
    required this.isSelected,
    required this.encoderOffset,
    this.motorEncoderValue,
    required this.size,
  });
  
  Color _getModuleColor() {
    switch (modulePosition) {
      case ModulePosition.frontLeft:
        return Colors.red;
      case ModulePosition.frontRight:
        return Colors.green;
      case ModulePosition.backLeft:
        return Colors.blue;
      case ModulePosition.backRight:
        return Colors.orange;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getModuleColor().withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? Colors.yellow : Colors.black,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Module label
          Center(
            child: Text(
              modulePosition == ModulePosition.frontLeft ? 'FL' :
              modulePosition == ModulePosition.frontRight ? 'FR' :
              modulePosition == ModulePosition.backLeft ? 'BL' : 'BR',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Absolute encoder direction indicator
          Center(
            child: Transform.rotate(
              angle: encoderOffset * math.pi / 180,
              child: Container(
                width: size * 0.8,
                height: 2,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Motor encoder direction indicator (if available)
          if (motorEncoderValue != null)
            Center(
              child: Transform.rotate(
                angle: motorEncoderValue * math.pi / 180,
                child: Container(
                  width: size * 0.6,
                  height: 2,
                  color: Colors.yellow,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
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
    );
  }
}
