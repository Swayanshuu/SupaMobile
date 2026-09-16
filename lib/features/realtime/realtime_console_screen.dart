import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_button.dart';
import '../../widgets/supa_text_field.dart';

import '../../core/providers/core_providers.dart';

class RealtimeConsoleScreen extends ConsumerStatefulWidget {
  final String projectRef;
  const RealtimeConsoleScreen({super.key, required this.projectRef});

  @override
  ConsumerState<RealtimeConsoleScreen> createState() => _RealtimeConsoleScreenState();
}

class _RealtimeConsoleScreenState extends ConsumerState<RealtimeConsoleScreen> {
  final _channelController = TextEditingController(text: 'room-1');
  RealtimeChannel? _channel;
  SupabaseClient? _tempClient;
  final List<String> _logs = [];
  bool _isSubscribed = false;

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().split(' ').last.split('.').first} | $message');
    });
  }

  Future<void> _toggleSubscription() async {
    if (_isSubscribed) {
      _channel?.unsubscribe();
      _log('Unsubscribed from ${_channelController.text}');
      setState(() => _isSubscribed = false);
    } else {
      final anonKey = await ref.read(anonKeyProvider(widget.projectRef).future);
      if (anonKey == null || anonKey.isEmpty) {
        _log('ERROR: No anon key available. Ensure anon key is fetched.');
        return;
      }

      final url = 'https://${widget.projectRef}.supabase.co';
      _tempClient ??= SupabaseClient(url, anonKey);
      _channel = _tempClient!.channel(_channelController.text);
      
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        callback: (payload) {
          _log('DB_CHANGE: ${payload.eventType} on ${payload.table}');
        },
      ).onBroadcast(
        event: '*',
        callback: (payload) {
          _log('BROADCAST: $payload');
        },
      ).subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _log('CONNECTED to ${_channelController.text}');
          setState(() => _isSubscribed = true);
        } else if (error != null) {
          _log('ERROR: $error');
        }
      });
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tempClient?.dispose();
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SupaAppBarSwitcher(
        title: 'Realtime Console',
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
            child: Column(
              children: [
                SupaCard(
                  child: Column(
                    children: [
                      SupaTextField(
                        label: 'Channel Name',
                        controller: _channelController,
                        placeholder: 'e.g. public-room',
                      ),
                      const SizedBox(height: 16),
                      SupaButton(
                        text: _isSubscribed ? 'Disconnect' : 'Connect to Channel',
                        width: double.infinity,
                        color: _isSubscribed ? Colors.redAccent : AppColors.supaGreen,
                        onPressed: _toggleSubscription,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.list_alt_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text('LIVE LOGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                    const Spacer(),
                    if (_logs.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _logs.clear()),
                        child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SupaCard(
                    padding: EdgeInsets.zero,
                    child: _logs.isEmpty 
                      ? Center(child: Text('No events yet. Connect to start listening.', style: TextStyle(color: AppColors.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            return Text(
                              _logs[index],
                              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.supaGreen),
                            );
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
