import 'package:flutter/material.dart';

import '../../../infrastructure/l10n/l10n_ext.dart';

class VoiceSearchStubScreen extends StatelessWidget {
  const VoiceSearchStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return _StubScaffold(
      title: l10n.voiceSearchTitle,
      body: l10n.voiceSearchBody,
    );
  }
}

class _StubScaffold extends StatelessWidget {
  const _StubScaffold({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(body),
          ),
        ),
      ),
    );
  }
}
