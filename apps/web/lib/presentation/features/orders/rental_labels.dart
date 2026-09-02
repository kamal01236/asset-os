import '../../../domain/models/entities.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';

String closedLineStatusLabel(AppLocalizations l10n, RentalLine line) {
  if (line.isSell) {
    return l10n.soldLineBadge;
  }
  if (line.isJob) {
    return l10n.completedJobLineBadge;
  }
  if (line.isLost) {
    return l10n.lineLostLabel;
  }
  return l10n.lineReturnedLabel;
}

String closedLinesHeading(AppLocalizations l10n, List<RentalLine> closed) {
  final bool anyRent = closed.any((RentalLine l) => l.isRent);
  final bool anySell = closed.any((RentalLine l) => l.isSell);
  final bool anyJob = closed.any((RentalLine l) => l.isJob);
  final bool anyLost = closed.any((RentalLine l) => l.isLost);
  final bool anyReturnedRent =
      closed.any((RentalLine l) => l.isRent && !l.isLost);
  if (anySell && !anyRent && !anyJob) {
    return l10n.soldLineBadge;
  }
  if (anyJob && !anyRent && !anySell) {
    return l10n.completedJobLineBadge;
  }
  if (anyLost && !anyReturnedRent && !anySell && !anyJob) {
    return l10n.lostLinesHeading;
  }
  return l10n.returnedLinesHeading;
}

String rentalLinesLabel(Rental rental) {
  final List<RentalLine> preferred =
      rental.isActive ? rental.openLines : rental.lines;
  final List<RentalLine> source =
      preferred.isNotEmpty ? preferred : rental.lines;
  if (source.isEmpty) {
    return rental.id;
  }
  return source.map((RentalLine line) => line.displayLabel).join(', ');
}
