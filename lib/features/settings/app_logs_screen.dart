import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_logger_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLogsScreen extends ConsumerStatefulWidget {
  const AppLogsScreen({super.key});

  @override
  ConsumerState<AppLogsScreen> createState() => _AppLogsScreenState();
}

class _AppLogsScreenState extends ConsumerState<AppLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLoggerProvider.notifier).markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggerState = ref.watch(appLoggerProvider);
    final logs = loggerState.logs.reversed.toList(); // Newest first

    return Scaffold(
      appBar: SupaAppBarSwitcher(
        title: 'App Logs (Debug)',
        actions: [
          if (logs.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.mail_outline, color: AppColors.textPrimary),
              onPressed: () async {
                final allLogs = logs.map((l) => '[${l.formattedTime}] [${l.level.toUpperCase()}] ${l.message}').join('\n');
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'supamobile@protonmail.com',
                  queryParameters: {
                    'subject': 'SupaMobile Bug Report',
                    'body': 'Describe your issue here...\n\n\n--- App Logs ---\n$allLogs',
                  },
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  Clipboard.setData(ClipboardData(text: allLogs));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open email client. Logs copied to clipboard instead.')),
                    );
                  }
                }
              },
              tooltip: 'Email All Logs',
            ),
            IconButton(
              icon: Icon(Icons.copy_all, color: AppColors.textPrimary),
              onPressed: () {
                final allLogs = logs.map((l) => '[${l.formattedTime}] [${l.level.toUpperCase()}] ${l.message}').join('\n');
                Clipboard.setData(ClipboardData(text: allLogs));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All logs copied to clipboard')),
                );
              },
              tooltip: 'Copy All Logs',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              ref.read(appLoggerProvider.notifier).clear();
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'No logs recorded yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.borderDefault),
              itemBuilder: (context, index) {
                final log = logs[index];
                
                Color levelColor = AppColors.textPrimary;
                if (log.level == 'error') levelColor = Colors.redAccent;
                if (log.level == 'warning') levelColor = Colors.amber;

                return GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: '[${log.formattedTime}] [${log.level.toUpperCase()}] ${log.message}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied log to clipboard')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    log.formattedTime,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: levelColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.level.toUpperCase(),
                                      style: TextStyle(
                                        color: levelColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.message,
                                style: TextStyle(
                                  color: levelColor,
                                  fontSize: 12,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.content_copy, size: 16),
                          color: AppColors.textMuted,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '[${log.formattedTime}] [${log.level.toUpperCase()}] ${log.message}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied log to clipboard')),
                            );
                          },
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(top: BorderSide(color: AppColors.borderDefault)),
            ),
            child: Column(
              children: [
                Icon(Icons.bug_report_outlined, color: AppColors.textMuted, size: 24),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'supamobile@protonmail.com',
                      queryParameters: {'subject': 'SupaMobile Feedback'},
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      Clipboard.setData(const ClipboardData(text: 'supamobile@protonmail.com'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied to clipboard')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Found a bug? Email us at supamobile@protonmail.com and we will solve it in the next update.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse('https://supamobile-26.web.app/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      Clipboard.setData(const ClipboardData(text: 'https://supamobile-26.web.app/'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Website link copied to clipboard')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Official Website: https://supamobile-26.web.app/',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
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
