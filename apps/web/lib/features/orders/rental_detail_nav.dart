import 'package:flutter/material.dart';

/// Factory for [RentalDetailScreen] without importing `app_shell.dart`
/// (which already imports the New Order flow).
typedef RentalDetailScreenFactory = Widget Function({required String rentalId});

RentalDetailScreenFactory? _rentalDetailScreenFactory;

/// Registers the detail screen builder. Idempotent; first call wins.
void registerRentalDetailScreenFactory(RentalDetailScreenFactory factory) {
  _rentalDetailScreenFactory ??= factory;
}

RentalDetailScreenFactory _requireRentalDetailFactory() {
  final RentalDetailScreenFactory? factory = _rentalDetailScreenFactory;
  if (factory == null) {
    throw StateError(
      'RentalDetailScreen factory not registered. '
      'Ensure AppShell (or a test) called registerRentalDetailScreenFactory.',
    );
  }
  return factory;
}

/// Pushes rental detail for [rentalId].
void pushRentalDetail(
  BuildContext context, {
  required String rentalId,
}) {
  final RentalDetailScreenFactory factory = _requireRentalDetailFactory();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => factory(rentalId: rentalId),
    ),
  );
}

/// Replaces the current route with rental detail for [rentalId].
void pushReplacementRentalDetail(
  BuildContext context, {
  required String rentalId,
}) {
  final RentalDetailScreenFactory factory = _requireRentalDetailFactory();
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => factory(rentalId: rentalId),
    ),
  );
}
