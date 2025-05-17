import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_swerve_config/services/network_tables_service.dart';
import 'package:frc_swerve_config/screens/welcome_screen.dart';
import 'package:frc_swerve_config/services/robot_simulator.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isCheckingLocal = true;
  bool _isLocalAvailable = false;
  bool _isConnecting = false;
  bool _showTeamInput = false;
  String? _connectionError;
  bool _isSimulatorRunning = false;
  
  final _teamNumberController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkLocalServer();
  }
  
  @override
  void dispose() {
    _teamNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _checkLocalServer() async {
    setState(() {
      _isCheckingLocal = true;
      _connectionError = null;
    });
    
    try {
      final isAvailable = await NetworkTablesService.instance.isLocalServerAvailable();
      
      setState(() {
        _isCheckingLocal = false;
        _isLocalAvailable = isAvailable;
        
        // If no local server, show team number input
        if (!isAvailable) {
          _showTeamInput = true;
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingLocal = false;
        _isLocalAvailable = false;
        _showTeamInput = true;
        _connectionError = 'Error checking local server: $e';
      });
    }
  }
  
  Future<void> _connectToLocalServer() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });
    
    try {
      final success = await NetworkTablesService.instance.connectToServer('127.0.0.1');
      
      if (success) {
        // Navigate to welcome screen on successful connection
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      } else {
        setState(() {
          _isConnecting = false;
          _connectionError = 'Failed to connect to local server';
          _showTeamInput = true;
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionError = 'Error connecting to local server: $e';
        _showTeamInput = true;
      });
    }
  }
  
  Future<void> _connectToRobot() async {
    // Validate team number
    final teamNumberText = _teamNumberController.text.trim();
    if (teamNumberText.isEmpty) {
      setState(() {
        _connectionError = 'Please enter a team number';
      });
      return;
    }
    
    int? teamNumber;
    try {
      teamNumber = int.parse(teamNumberText);
      if (teamNumber <= 0) {
        throw FormatException('Team number must be positive');
      }
    } catch (e) {
      setState(() {
        _connectionError = 'Invalid team number';
      });
      return;
    }
    
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });
    
    try {
      // Start connection attempts
      bool connected = false;
      int attempts = 0;
      const maxAttempts = 10;
      
      while (!connected && attempts < maxAttempts) {
        attempts++;
        
        setState(() {
          _connectionError = 'Attempting to connect (${attempts}/${maxAttempts})...';
        });
        
        connected = await NetworkTablesService.instance.connectToRobot(teamNumber);
        
        if (!connected && attempts < maxAttempts) {
          // Wait before trying again
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (connected) {
        // Navigate to welcome screen on successful connection
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      } else {
        setState(() {
          _isConnecting = false;
          _connectionError = 'Failed to connect to robot after multiple attempts';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionError = 'Error connecting to robot: $e';
      });
    }
  }
  
  void _toggleSimulator() {
    if (_isSimulatorRunning) {
      RobotSimulator.instance.stop();
    } else {
      RobotSimulator.instance.start();
    }
    
    setState(() {
      _isSimulatorRunning = !_isSimulatorRunning;
      if (_isSimulatorRunning) {
        _isLocalAvailable = true;
        _connectionError = 'Simulator started. You can now connect to the local server.';
      } else {
        _checkLocalServer(); // Re-check for local server
        _connectionError = 'Simulator stopped.';
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Robot'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.settings_remote,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'FRC Swerve Configuration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect to your robot to configure and test your swerve drive',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Simulator toggle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Robot Simulator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start a simulated robot for testing without hardware',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _toggleSimulator,
                          icon: Icon(_isSimulatorRunning ? Icons.stop : Icons.play_arrow),
                          label: Text(_isSimulatorRunning ? 'Stop Simulator' : 'Start Simulator'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSimulatorRunning ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Local server check
                if (_isCheckingLocal)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Checking for local NetworkTables server...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else if (_isLocalAvailable)
                  Column(
                    children: [
                      const Text(
                        'Local NetworkTables server found!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Would you like to connect to the local server?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isConnecting ? null : _connectToLocalServer,
                            child: const Text('Connect to Local Server'),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: _isConnecting ? null : () {
                              setState(() {
                                _showTeamInput = true;
                                _isLocalAvailable = false;
                              });
                            },
                            child: const Text('Connect to Robot Instead'),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                // Team number input
                if (_showTeamInput && !_isLocalAvailable)
                  Column(
                    children: [
                      const Text(
                        'Connect to Robot',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please deploy the tuning robot program to your robot and enter your team number below.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _teamNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Team Number',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 1234',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !_isConnecting,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isConnecting ? null : _connectToRobot,
                        child: _isConnecting
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Connecting...'),
                                ],
                              )
                            : const Text('Connect to Robot'),
                      ),
                    ],
                  ),
                
                // Error message
                if (_connectionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _connectionError!,
                      style: TextStyle(
                        color: _isSimulatorRunning ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
