import 'package:cashly/data/services/notification_capture_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  List<Map<String, String>> _installedApps = [];
  Set<String> _blockedPackages = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = NotificationCaptureService();
    final apps = await service.getInstalledApps();
    final blocked = await service.getBlockedApps();

    if (mounted) {
      setState(() {
        _installedApps = apps;
        _blockedPackages = blocked.toSet();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleApp(String packageName, bool block) async {
    final service = NotificationCaptureService();
    if (block) {
      await service.blockApp(packageName);
    } else {
      await service.unblockApp(packageName);
    }
    setState(() {
      if (block) {
        _blockedPackages.add(packageName);
      } else {
        _blockedPackages.remove(packageName);
      }
    });
  }

  List<Map<String, String>> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;
    final query = _searchQuery.toLowerCase();
    return _installedApps.where((app) {
      final name = (app['appName'] ?? '').toLowerCase();
      final pkg = (app['packageName'] ?? '').toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();
  }

  List<Map<String, String>> get _blockedAppsFirst {
    final filtered = _filteredApps;
    final blocked = filtered.where((a) => _blockedPackages.contains(a['packageName'])).toList();
    final unblocked = filtered.where((a) => !_blockedPackages.contains(a['packageName'])).toList();
    return [...blocked, ...unblocked];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.blockedApps),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: localizations.searchApps,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),

                // Blocked count
                if (_blockedPackages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 16, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          localizations.blockedAppsCount(_blockedPackages.length),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // App list
                Expanded(
                  child: ListView.builder(
                    itemCount: _blockedAppsFirst.length,
                    itemBuilder: (context, index) {
                      final app = _blockedAppsFirst[index];
                      final packageName = app['packageName']!;
                      final appName = app['appName']!;
                      final isBlocked = _blockedPackages.contains(packageName);

                      return SwitchListTile(
                        title: Text(
                          appName,
                          style: TextStyle(
                            fontWeight: isBlocked ? FontWeight.w600 : FontWeight.normal,
                            color: isBlocked ? theme.colorScheme.error : null,
                          ),
                        ),
                        subtitle: Text(
                          packageName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: isBlocked,
                        onChanged: (value) => _toggleApp(packageName, value),
                        secondary: Icon(
                          isBlocked ? Icons.block : Icons.apps,
                          color: isBlocked ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
