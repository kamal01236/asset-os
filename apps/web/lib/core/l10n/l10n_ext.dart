import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../models/entities.dart';

export '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizedStatusLabel(AppLocalizations l10n, AssetStatus status) {
  switch (status) {
    case AssetStatus.available:
      return l10n.statusAvailable;
    case AssetStatus.rented:
      return l10n.statusRented;
    case AssetStatus.dueToday:
      return l10n.statusDueToday;
    case AssetStatus.overdue:
      return l10n.statusOverdue;
    case AssetStatus.archived:
      return l10n.statusArchived;
  }
}
