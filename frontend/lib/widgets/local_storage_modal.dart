import 'package:flutter/material.dart';
import '../services/simulator_state.dart';
import '../theme/app_theme.dart';

class LocalStorageModal extends StatefulWidget {
  final SimulatorState state;

  const LocalStorageModal({super.key, required this.state});

  @override
  State<LocalStorageModal> createState() => _LocalStorageModalState();
}

class _LocalStorageModalState extends State<LocalStorageModal> {
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _savedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    final items = await widget.state.getLocalStorageTopologies();
    if (mounted) {
      setState(() {
        _savedItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSaveCurrent() async {
    final name = _nameController.text;
    final success = await widget.state.saveTopologyToLocalStorage(name);
    if (success) {
      _nameController.clear();
      await _loadSavedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Network saved locally to device!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650,
        height: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              children: [
                const Icon(Icons.sd_card_outlined, color: AppColors.primaryAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Offline Local Saved Work Manager',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '100% Offline Ready',
                        style: TextStyle(
                          color: isDark ? AppColors.success : const Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Save Current Canvas Section
            Text(
              'Save Current Canvas to Local Storage',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter topology name (e.g. My Lab Network)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.state.devices.isEmpty ? null : _handleSaveCurrent,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Local'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // File Export / Import Actions
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: widget.state.devices.isEmpty
                      ? null
                      : () async {
                          await widget.state.exportTopologyFile();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export JSON File'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final success = await widget.state.importTopologyFile();
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import JSON File'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Saved Topologies List
            Text(
              'Saved Offline Topologies (${_savedItems.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 40, color: theme.disabledColor),
                              const SizedBox(height: 8),
                              Text(
                                'No local saved topologies yet.\nEnter a name above to save your canvas work offline!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _savedItems.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _savedItems[index];
                            final id = item['id'] as String;
                            final name = item['name'] as String? ?? 'Unnamed Network';
                            final count = item['deviceCount'] as int? ?? 0;
                            final timeStr = item['timestamp'] as String? ?? '';
                            final jsonStr = item['json'] as String? ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryAccent.withOpacity(0.15),
                                child: const Icon(Icons.hub, color: AppColors.primaryAccent, size: 20),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                '$count devices • Saved: ${timeStr.split('T').first}',
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final ok = await widget.state.loadTopologyFromLocalStorage(jsonStr);
                                      if (ok && context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    icon: const Icon(Icons.folder_open, size: 16),
                                    label: const Text('Load'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondaryAccent,
                                      foregroundColor: const Color(0xFF0F172A),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    tooltip: 'Delete local save',
                                    onPressed: () async {
                                      await widget.state.deleteTopologyFromLocalStorage(id);
                                      await _loadSavedItems();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
