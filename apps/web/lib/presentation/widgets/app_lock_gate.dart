import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../application/privacy/privacy_settings.dart';
import '../../application/providers/app_providers.dart';
import '../../infrastructure/l10n/l10n_ext.dart';

/// Full-screen PIN / biometric gate when app lock is enabled.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _ready = false;
  String _pinEntry = '';
  String? _errorText;
  int _shakeTick = 0;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateLock(initial: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateLock(initial: false);
    }
  }

  void _evaluateLock({required bool initial}) {
    final PrivacySettings settings = ref.read(privacySettingsProvider);
    if (!settings.appLockEnabled || !settings.hasValidAppLockPin) {
      setState(() {
        _locked = false;
        _ready = true;
        _pinEntry = '';
        _errorText = null;
      });
      return;
    }
    setState(() {
      _locked = true;
      _ready = true;
      _pinEntry = '';
      _errorText = null;
    });
    if (!kIsWeb && settings.biometricEnabled) {
      unawaited(_tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck || !mounted) {
        return;
      }
      final bool ok = await _localAuth.authenticate(
        localizedReason: context.l10n.appLockBiometricReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok && mounted) {
        setState(() {
          _locked = false;
          _pinEntry = '';
          _errorText = null;
        });
      }
    } catch (_) {
      // PIN fallback — no stack traces in UI.
    }
  }

  void _appendDigit(String digit) {
    final PrivacySettings settings = ref.read(privacySettingsProvider);
    final int maxLen = settings.appLockPin?.length ?? 6;
    if (_pinEntry.length >= maxLen) {
      return;
    }
    setState(() {
      _pinEntry += digit;
      _errorText = null;
    });
    if (_pinEntry.length >= 4 &&
        _pinEntry.length == (settings.appLockPin?.length ?? 4)) {
      _submitPin();
    }
  }

  void _backspace() {
    if (_pinEntry.isEmpty) {
      return;
    }
    setState(() {
      _pinEntry = _pinEntry.substring(0, _pinEntry.length - 1);
      _errorText = null;
    });
  }

  void _submitPin() {
    final PrivacySettings settings = ref.read(privacySettingsProvider);
    if (_pinEntry == settings.appLockPin) {
      setState(() {
        _locked = false;
        _pinEntry = '';
        _errorText = null;
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _errorText = context.l10n.appLockWrongPin;
      _pinEntry = '';
      _shakeTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.child;
    }
    return Stack(
      children: <Widget>[
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: _LockOverlay(
                  pinEntry: _pinEntry,
                  errorText: _errorText,
                  shakeTick: _shakeTick,
                  biometricEnabled: !kIsWeb &&
                      ref.watch(privacySettingsProvider).biometricEnabled,
                  onDigit: _appendDigit,
                  onBackspace: _backspace,
                  onSubmit: _submitPin,
                  onBiometric: _tryBiometric,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay({
    required this.pinEntry,
    required this.errorText,
    required this.shakeTick,
    required this.biometricEnabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.onBiometric,
  });

  final String pinEntry;
  final String? errorText;
  final int shakeTick;
  final bool biometricEnabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const Spacer(),
          Icon(Icons.lock_outline, size: 48, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            l10n.appLockTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appLockSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey<int>(shakeTick),
              child: _PinDots(length: pinEntry.length, error: errorText != null),
            ),
          ),
          if (errorText != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          _PinPad(
            onDigit: onDigit,
            onBackspace: onBackspace,
            onSubmit: onSubmit,
            canSubmit: pinEntry.length >= 4,
          ),
          if (biometricEnabled) ...<Widget>[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onBiometric,
              icon: const Icon(Icons.fingerprint),
              label: Text(l10n.appLockUseBiometric),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, required this.error});

  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color fill = error ? colors.error : colors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(6, (int index) {
        final bool filled = index < length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? fill : Colors.transparent,
              border: Border.all(color: fill, width: 2),
            ),
          ),
        );
      }),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.canSubmit,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> keys = <String>[
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫',
    ];
    return SizedBox(
      width: 280,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: keys.length,
        itemBuilder: (BuildContext context, int index) {
          final String key = keys[index];
          if (key.isEmpty) {
            return canSubmit
                ? FilledButton(
                    onPressed: onSubmit,
                    child: Text(l10n.appLockUnlockAction),
                  )
                : const SizedBox.shrink();
          }
          if (key == '⌫') {
            return OutlinedButton(
              onPressed: onBackspace,
              child: const Icon(Icons.backspace_outlined),
            );
          }
          return OutlinedButton(
            onPressed: () => onDigit(key),
            child: Text(key, style: Theme.of(context).textTheme.titleLarge),
          );
        },
      ),
    );
  }
}
