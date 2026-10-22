import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/settings_group.dart';

class SessionsSettingsScreen extends ConsumerStatefulWidget {
  const SessionsSettingsScreen({super.key});

  @override
  ConsumerState<SessionsSettingsScreen> createState() =>
      _SessionsSettingsScreenState();
}

class _SessionsSettingsScreenState
    extends ConsumerState<SessionsSettingsScreen> {
  late Future<List<Map<String, dynamic>>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = _loadSessions();
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    final results = await Future.wait([
      ref.read(authDataSourceProvider).getSessions(),
      SecureStorage.getDeviceId(),
      SecureStorage.getDeviceName(),
      SecureStorage.getSessionToken(),
    ]);
    final sessions = results[0] as List<Map<String, dynamic>>;
    final deviceId = results[1] as String;
    final deviceName = results[2] as String;
    final currentSessionId = _sessionIdFromToken(results[3] as String?);

    final currentIndex = currentSessionId == null
        ? sessions.indexWhere((session) => session['device_id'] == deviceId)
        : sessions.indexWhere((session) => session['id'] == currentSessionId);
    if (currentIndex < 0) {
      sessions.insert(0, {
        'id': null,
        'device_id': deviceId,
        'device_name': deviceName,
        'last_active_at': DateTime.now().toIso8601String(),
        'is_current_device': true,
      });
    } else {
      sessions[currentIndex]['is_current_device'] = true;
    }
    return sessions;
  }

  String? _sessionIdFromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map ? payload['session_id']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _revoke(Map<String, dynamic> session) async {
    final id = session['id']?.toString();
    if (id == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out this device?'),
        content: const Text(
          'It will be signed out the next time it checks in. It may take up to an hour for an existing session to expire.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    try {
      await ref.read(authDataSourceProvider).revokeSession(id);
      setState(() {
        _sessions = _loadSessions();
      });
    } catch (_) {
      if (mounted)
        UiHelpers.showError(context, 'Could not sign out this device.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Devices')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _sessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return SettingsLoadError(
            message: 'Could not load devices.',
            onRetry: () => setState(() => _sessions = _loadSessions()),
          );
        }
        final sessions = snapshot.data ?? const [];
        if (sessions.isEmpty) {
          return const Center(child: Text('This device is signed in.'));
        }
        return ListView.separated(
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final session = sessions[index];
            final isCurrent = session['is_current_device'] == true;
            final name = (session['device_name'] as String?)?.trim();
            final active = DateTime.tryParse(
              session['last_active_at']?.toString() ?? '',
            )?.toLocal();
            return ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(name?.isNotEmpty == true ? name! : 'Unknown device'),
              subtitle: Text(
                isCurrent
                    ? 'This device'
                    : active == null
                    ? 'Signed in'
                    : 'Last active ${MaterialLocalizations.of(context).formatMediumDate(active)}',
              ),
              trailing: isCurrent
                  ? const Text('Current')
                  : IconButton(
                      tooltip: 'Sign out device',
                      icon: const Icon(Icons.logout),
                      onPressed: session['id'] == null
                          ? null
                          : () => _revoke(session),
                    ),
            );
          },
        );
      },
    ),
  );
}
