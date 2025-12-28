import 'package:cashly/data/services/log_file_service.dart';
import 'package:flutter/material.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _logs = 'Cargando logs...';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logService = LogFileService();
    await logService.initialize();
    final logs = await logService.readLogs();
    setState(() {
      _logs = logs.isEmpty ? 'No hay logs disponibles.' : logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: const Text('Logs'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLogs,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                LogFileService().clearLogs().then((_) => _loadLogs());
              },
            ),
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            _logs,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
    );
  }
}
