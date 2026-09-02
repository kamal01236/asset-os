import 'package:flutter/material.dart';

import '../../../infrastructure/l10n/l10n_ext.dart';

class GlobalActionsButton extends StatelessWidget {
  const GlobalActionsButton({
    required this.onSearch,
    required this.onNewRental,
    required this.onReturnItem,
    required this.onAddInventory,
    required this.onScan,
    super.key,
  });

  final VoidCallback onSearch;
  final VoidCallback onNewRental;
  final VoidCallback onReturnItem;
  final VoidCallback onAddInventory;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return FloatingActionButton.extended(
      tooltip: l10n.actionActions,
      heroTag: 'global-actions-fab',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (BuildContext context) {
            final AppLocalizations sheetL10n = context.l10n;
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(sheetL10n.actionSearch),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSearch();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add_circle_outlined),
                    title: Text(sheetL10n.actionNewRental),
                    onTap: () {
                      Navigator.of(context).pop();
                      onNewRental();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_return_outlined),
                    title: Text(sheetL10n.actionReturn),
                    onTap: () {
                      Navigator.of(context).pop();
                      onReturnItem();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: Text(sheetL10n.actionAddResource),
                    onTap: () {
                      Navigator.of(context).pop();
                      onAddInventory();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner_outlined),
                    title: Text(sheetL10n.actionScan),
                    onTap: () {
                      Navigator.of(context).pop();
                      onScan();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.flash_on),
      label: Text(l10n.actionActions),
    );
  }
}
