import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/core_providers.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_button.dart';
import '../../core/providers/security_provider.dart';
import '../auth/service_key_prompt.dart';
import '../auth/anon_key_prompt.dart';
import '../auth/pat_input_prompt.dart';
import '../../widgets/supa_app_bar_switcher.dart';

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  final String projectRef;
  const ProjectSettingsScreen({super.key, required this.projectRef});

  @override
  ConsumerState<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  bool _showServiceKey = false;

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final serviceKeyAsync = ref.watch(serviceRoleKeyProvider(widget.projectRef));
    final anonKeyAsync = ref.watch(anonKeyProvider(widget.projectRef));
    final patAsync = ref.watch(patProvider);

    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('API Configuration'),
            SupaCard(
              child: Column(
                children: [
                  _buildSettingItem(
                    'Project URL',
                    'https://${widget.projectRef}.supabase.co',
                    onCopy: () => _copyToClipboard('https://${widget.projectRef}.supabase.co', 'URL copied'),
                  ),
                  anonKeyAsync.when(
                    data: (key) => _buildSettingItem(
                      'Anon Key',
                      key ?? 'Not set',
                      isSecret: !_showServiceKey,
                      onToggleSecret: () => setState(() => _showServiceKey = !_showServiceKey),
                      onCopy: key != null ? () => _copyToClipboard(key, 'Anon Key copied') : null,
                      onEdit: () => showAnonKeyPrompt(context, widget.projectRef),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const Divider(height: 32, thickness: 0.5),
                  serviceKeyAsync.when(
                    data: (key) => _buildSettingItem(
                      'Service Role Key',
                      key ?? 'Not set',
                      isSecret: !_showServiceKey,
                      onToggleSecret: () => setState(() => _showServiceKey = !_showServiceKey),
                      onCopy: key != null ? () => _copyToClipboard(key, 'Key copied') : null,
                      onEdit: () => showServiceKeyPrompt(context, widget.projectRef),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Security'),
            SupaCard(
              child: ref.watch(biometricsEnabledProvider).when(
                data: (enabled) => SwitchListTile(
                  title: const Text('Biometric Protection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Require fingerprint or face ID for sensitive actions', style: TextStyle(fontSize: 12)),
                  value: enabled,
                  activeColor: AppColors.supaGreen,
                  onChanged: (val) => ref.read(securityProvider).toggleBiometrics(val),
                  contentPadding: EdgeInsets.zero,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Account & Access'),
            SupaCard(
              child: Column(
                children: [
                  patAsync.when(
                    data: (token) => _buildSettingItem(
                      'Experimental Access Token',
                      token != null ? '••••' + (token.length > 4 ? token.substring(token.length - 4) : token) : 'Not set',
                      isSecret: true,
                      onCopy: token != null ? () => _copyToClipboard(token, 'PAT copied') : null,
                      onEdit: () => token == null ? showPatInputPrompt(context, ref) : _showClearPatDialog(),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const Text('Error loading PAT'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Project Info'),
            SupaCard(
              child: InkWell(
                onLongPress: () => _copyToClipboard(widget.projectRef, 'Project Ref copied'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Project Reference', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Reference code for API requests', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(widget.projectRef, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'JetBrains Mono')),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildSectionHeader('Danger Zone'),
            SupaCard(
              borderColor: Colors.redAccent.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Remove Project', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  Text('Disconnect this project from your local management tool. Data on Supabase will not be deleted.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  SupaButton(text: 'Remove Connection', color: Colors.redAccent, onPressed: () => _showRemoveDialog()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingItem(String label, String value, {bool isSecret = false, VoidCallback? onToggleSecret, VoidCallback? onCopy, VoidCallback? onEdit}) {
    return GestureDetector(
      onLongPress: onCopy,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(
                    (isSecret && value != 'Not set' && value.isNotEmpty) ? '••••••••••••••••••••••••' : value,
                    style: const TextStyle(fontSize: 13, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onToggleSecret != null)
              IconButton(icon: Icon(isSecret ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textMuted), onPressed: onToggleSecret),
            if (onCopy != null)
              IconButton(icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.textMuted), onPressed: onCopy),
            if (onEdit != null)
              IconButton(icon: Icon(Icons.edit_note_rounded, size: 22, color: AppColors.supaGreen), onPressed: onEdit),
          ],
        ),
      ),
    );
  }

  void _showClearPatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Access Token?'),
        content: const Text('This will clear your Experimental Access Token. You will need to provide a new one to fetch project metrics.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(patActionsProvider).clearPat();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access token removed')));
              }
            },
            child: const Text('Remove Token', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Project?'),
        content: const Text('Are you sure you want to remove this project connection?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await ref.read(securityProvider).verify();
              if (success) {
                Navigator.pop(context);
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

