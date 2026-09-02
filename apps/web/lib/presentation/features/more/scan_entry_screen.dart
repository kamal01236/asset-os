import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/local_repository.dart';
import '../../../application/providers/app_providers.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../customers/customer_detail_screen.dart';
import '../inventory/inventory_detail_screen.dart';
import '../orders/rental_detail_screen.dart';

class ScanEntryScreen extends ConsumerStatefulWidget {
  const ScanEntryScreen({super.key});

  @override
  ConsumerState<ScanEntryScreen> createState() => _ScanEntryScreenState();
}

class _ScanEntryScreenState extends ConsumerState<ScanEntryScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> quickCodes = <String>[
      'customer:1001',
      'rental:3001',
      'inventory:2001',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.actionScan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.scanIntro),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.qrContentLabel,
              hintText: l10n.qrContentHint,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCodes
                .map(
                  (code) => ActionChip(
                    label: Text(code),
                    onPressed: () => setState(() => _controller.text = code),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton.icon(
          onPressed: () async {
            final QrDestination? destination =
                await ref.read(repositoryProvider).resolveQr(_controller.text);
            if (!context.mounted) {
              return;
            }
            if (destination == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.noEntityMatched)),
              );
              return;
            }
            if (destination is QrCustomer) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CustomerDetailScreen(customerId: destination.customerId),
                ),
              );
              return;
            }
            if (destination is QrRental) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RentalDetailScreen(rentalId: destination.rentalId),
                ),
              );
              return;
            }
            if (destination is QrInventory) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InventoryDetailScreen(itemId: destination.itemId),
                ),
              );
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.openLinkedRecord),
        ),
      ),
    );
  }
}
