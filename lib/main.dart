import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frc_swerve_config/providers/config_provider.dart';
import 'package:frc_swerve_config/screens/connection_screen.dart';
import 'package:frc_swerve_config/services/network_tables_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Clean up NetworkTables service
    NetworkTablesService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ConfigProvider(),
      child: MaterialApp(
        title: 'FRC Swerve Configuration',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ConnectionScreen(),
      ),
    );
  }
}
