import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/location_map.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/address.dart';
import '../providers/profile_providers.dart';
import '../widgets/address_form_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() f,
    String ok,
  ) async {
    try {
      await f();
      if (context.mounted) showSnack(context, ok);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My addresses')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => showAddressForm(
          context,
          forceDefault: (value.value ?? const []).isEmpty,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: AsyncView<List<Address>>(
        value: value,
        onRetry: () => ref.read(addressesProvider.notifier).reload(),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No addresses yet',
              message: 'Add a delivery address to check out faster.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(addressesProvider.notifier).reload(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = list[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.receiverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (a.isDefault)
                              const Chip(
                                label: Text('Default'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        Text(a.phone),
                        Text(a.fullLine),
                        if (a.hasLocation) ...[
                          const SizedBox(height: 8),
                          MapPreview(
                            key: Key('address_map_${a.id}'),
                            latitude: a.latitude!,
                            longitude: a.longitude!,
                          ),
                        ],
                        Row(
                          children: [
                            if (!a.isDefault)
                              TextButton(
                                onPressed: () => _run(
                                  context,
                                  () => ref
                                      .read(addressesProvider.notifier)
                                      .setDefault(a.id),
                                  'Default address updated',
                                ),
                                child: const Text('Set default'),
                              ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () =>
                                  showAddressForm(context, existing: a),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  // Pop with the DIALOG's context, never the screen's.
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete address?'),
                                    actions: [
                                      TextButton(
                                        key: const Key('delete_address_cancel'),
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        key: const Key(
                                          'delete_address_confirm',
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(100, 44),
                                          backgroundColor: AppColors.danger,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  await _run(
                                    context,
                                    () => ref
                                        .read(addressesProvider.notifier)
                                        .remove(a.id),
                                    'Address deleted',
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
