import '../models/entities.dart';
import 'l10n_ext.dart';

/// Stable keys written to [RentalEvent.title] / demo seed; localized at display.
abstract final class TimelineTitleKey {
  static const orderOpened = 'order_opened';
  static const replacementOpened = 'replacement_opened';
  static const saleCompleted = 'sale_completed';
  static const jobOpened = 'job_opened';
  static const returned = 'returned';
  static const partialReturn = 'partial_return';
  static const jobsCompleted = 'jobs_completed';
  static const jobCompleted = 'job_completed';
  static const orderCancelled = 'order_cancelled';
  static const noteAdded = 'note_added';
  static const dueToday = 'due_today';
  static const rentalOpened = 'rental_opened';
}

/// Stable subtitle keys (optionally with `|`-separated args). See [encodeTimelineSubtitle].
abstract final class TimelineSubtitleKey {
  static const createdOrderFlow = 'created_order_flow';
  static const createdOrderFlowSale = 'created_order_flow_sale';
  static const createdOrderFlowJob = 'created_order_flow_job';
  static const createdOrderFlowMixed = 'created_order_flow_mixed';
  static const replacementFor = 'replacement_for';
  static const allLinesReturned = 'all_lines_returned';
  static const allLinesReturnedLate = 'all_lines_returned_late';
  static const partialReturnLines = 'partial_return_lines';
  static const allJobsComplete = 'all_jobs_complete';
  static const jobsCompletedCount = 'jobs_completed_count';
  static const cancelSettlement = 'cancel_settlement';
  static const noteBody = 'note_body';
  static const autoReminder = 'auto_reminder';
  static const checkedOutByStaff = 'checked_out_by_staff';
  static const closedAtCounter = 'closed_at_counter';
  static const manualWalkIn = 'manual_walk_in';
}

const String _kDiscountPrefix = 'd:';
const String _kNotePrefix = 'n:';

/// Encode a system subtitle for storage. Args are positional for the key template.
/// Optional [discountFormatted] / [note] append localized tails at display time.
String encodeTimelineSubtitle(
  String key, {
  List<String> args = const <String>[],
  String? discountFormatted,
  String? note,
}) {
  final List<String> parts = <String>[key, ...args];
  if (discountFormatted != null && discountFormatted.isNotEmpty) {
    parts.add('$_kDiscountPrefix$discountFormatted');
  }
  if (note != null && note.isNotEmpty) {
    parts.add('$_kNotePrefix$note');
  }
  return parts.join('|');
}

String localizeTimelineTitle(AppLocalizations l10n, String raw) {
  switch (raw) {
    case TimelineTitleKey.orderOpened:
    case 'Order opened':
      return l10n.timelineTitleOrderOpened;
    case TimelineTitleKey.replacementOpened:
    case 'Replacement opened':
      return l10n.timelineTitleReplacementOpened;
    case TimelineTitleKey.saleCompleted:
    case 'Sale completed':
      return l10n.timelineTitleSaleCompleted;
    case TimelineTitleKey.jobOpened:
    case 'Job opened':
      return l10n.timelineTitleJobOpened;
    case TimelineTitleKey.returned:
    case 'Returned':
      return l10n.timelineTitleReturned;
    case TimelineTitleKey.partialReturn:
    case 'Partial return':
      return l10n.timelineTitlePartialReturn;
    case TimelineTitleKey.jobsCompleted:
    case 'Jobs completed':
      return l10n.timelineTitleJobsCompleted;
    case TimelineTitleKey.jobCompleted:
    case 'Job completed':
      return l10n.timelineTitleJobCompleted;
    case TimelineTitleKey.orderCancelled:
    case 'Order cancelled':
      return l10n.timelineTitleOrderCancelled;
    case TimelineTitleKey.noteAdded:
    case 'Note added':
      return l10n.timelineTitleNoteAdded;
    case TimelineTitleKey.dueToday:
    case 'Due today':
      return l10n.timelineTitleDueToday;
    case TimelineTitleKey.rentalOpened:
    case 'Rental opened':
      return l10n.timelineTitleRentalOpened;
    default:
      return raw;
  }
}

String localizeTimelineSubtitle(AppLocalizations l10n, String raw) {
  if (raw.isEmpty) {
    return raw;
  }

  final String? fromKey = _localizeEncodedSubtitle(l10n, raw);
  if (fromKey != null) {
    return fromKey;
  }

  final String? legacy = _localizeLegacySubtitle(l10n, raw);
  if (legacy != null) {
    return legacy;
  }

  // Legacy note events: "general: body" / "terms: …" / "measurement: …"
  final Match? noteMatch = RegExp(
    r'^(general|terms|measurement):\s*(.*)$',
    dotAll: true,
  ).firstMatch(raw);
  if (noteMatch != null) {
    final RentalNoteKind kind = RentalNoteKind.parse(noteMatch.group(1)!);
    return l10n.timelineSubtitleNoteBody(
      localizedRentalNoteKind(l10n, kind),
      noteMatch.group(2) ?? '',
    );
  }

  return raw;
}

String? _localizeEncodedSubtitle(AppLocalizations l10n, String raw) {
  final List<String> parts = raw.split('|');
  if (parts.isEmpty) {
    return null;
  }
  final String key = parts.first;
  final List<String> args = <String>[];
  String? discount;
  String? note;
  for (int i = 1; i < parts.length; i++) {
    final String part = parts[i];
    if (part.startsWith(_kNotePrefix)) {
      // Notes may contain '|'; join the remainder.
      note = parts.sublist(i).join('|').substring(_kNotePrefix.length);
      break;
    }
    if (part.startsWith(_kDiscountPrefix)) {
      discount = part.substring(_kDiscountPrefix.length);
      continue;
    }
    args.add(part);
  }

  final String? base = _subtitleForKey(l10n, key, args);
  if (base == null) {
    return null;
  }

  final StringBuffer out = StringBuffer(base);
  if (discount != null && discount.isNotEmpty) {
    out.write(' ');
    out.write(l10n.timelineSubtitleDiscountBit(discount));
  }
  if (note != null && note.isNotEmpty) {
    out.write(' ');
    out.write(l10n.timelineSubtitleNoteBit(note));
  }
  return out.toString();
}

String? _subtitleForKey(
  AppLocalizations l10n,
  String key,
  List<String> args,
) {
  switch (key) {
    case TimelineSubtitleKey.createdOrderFlow:
      return l10n.timelineSubtitleCreatedOrderFlow;
    case TimelineSubtitleKey.createdOrderFlowSale:
      return l10n.timelineSubtitleCreatedOrderFlowSale;
    case TimelineSubtitleKey.createdOrderFlowJob:
      return l10n.timelineSubtitleCreatedOrderFlowJob;
    case TimelineSubtitleKey.createdOrderFlowMixed:
      return l10n.timelineSubtitleCreatedOrderFlowMixed;
    case TimelineSubtitleKey.replacementFor:
      if (args.isEmpty) {
        return null;
      }
      return l10n.timelineSubtitleReplacementFor(args[0]);
    case TimelineSubtitleKey.allLinesReturned:
      return l10n.timelineSubtitleAllLinesReturned;
    case TimelineSubtitleKey.allLinesReturnedLate:
      return l10n.timelineSubtitleAllLinesReturnedLate;
    case TimelineSubtitleKey.partialReturnLines:
      if (args.length < 2) {
        return null;
      }
      final int? returned = int.tryParse(args[0]);
      final int? total = int.tryParse(args[1]);
      if (returned == null || total == null) {
        return null;
      }
      return l10n.timelineSubtitlePartialReturnLines(returned, total);
    case TimelineSubtitleKey.allJobsComplete:
      return l10n.timelineSubtitleAllJobsComplete;
    case TimelineSubtitleKey.jobsCompletedCount:
      if (args.isEmpty) {
        return null;
      }
      final int? count = int.tryParse(args[0]);
      if (count == null) {
        return null;
      }
      return l10n.timelineSubtitleJobsCompletedCount(count);
    case TimelineSubtitleKey.cancelSettlement:
      if (args.length < 2) {
        return null;
      }
      return l10n.timelineSubtitleCancelSettlement(args[0], args[1]);
    case TimelineSubtitleKey.noteBody:
      if (args.isEmpty) {
        return null;
      }
      final RentalNoteKind kind = RentalNoteKind.parse(args[0]);
      final String body =
          args.length > 1 ? args.sublist(1).join('|') : '';
      return l10n.timelineSubtitleNoteBody(
        localizedRentalNoteKind(l10n, kind),
        body,
      );
    case TimelineSubtitleKey.autoReminder:
      return l10n.timelineSubtitleAutoReminder;
    case TimelineSubtitleKey.checkedOutByStaff:
      return l10n.timelineSubtitleCheckedOutByStaff;
    case TimelineSubtitleKey.closedAtCounter:
      return l10n.timelineSubtitleClosedAtCounter;
    case TimelineSubtitleKey.manualWalkIn:
      return l10n.timelineSubtitleManualWalkIn;
    default:
      return null;
  }
}

String? _localizeLegacySubtitle(AppLocalizations l10n, String raw) {
  switch (raw) {
    case 'Created from phone-first order flow.':
      return l10n.timelineSubtitleCreatedOrderFlow;
    case 'Created from phone-first order flow (sale).':
      return l10n.timelineSubtitleCreatedOrderFlowSale;
    case 'Created from phone-first order flow (job).':
      return l10n.timelineSubtitleCreatedOrderFlowJob;
    case 'Created from phone-first order flow (mixed).':
      return l10n.timelineSubtitleCreatedOrderFlowMixed;
    case 'All lines returned by staff.':
      return l10n.timelineSubtitleAllLinesReturned;
    case 'All lines returned. Late fee applied.':
      return l10n.timelineSubtitleAllLinesReturnedLate;
    case 'All job lines marked complete.':
      return l10n.timelineSubtitleAllJobsComplete;
    case 'Auto reminder generated.':
      return l10n.timelineSubtitleAutoReminder;
    case '1 item checked out by staff.':
      return l10n.timelineSubtitleCheckedOutByStaff;
    case 'Closed at counter.':
      return l10n.timelineSubtitleClosedAtCounter;
    case 'Manual walk-in checkout.':
      return l10n.timelineSubtitleManualWalkIn;
  }

  final Match? replacement = RegExp(
    r'^Replacement for (.+)\.$',
  ).firstMatch(raw);
  if (replacement != null) {
    return l10n.timelineSubtitleReplacementFor(replacement.group(1)!);
  }

  final Match? partial = RegExp(
    r'^Returned (\d+) of (\d+) lines\.$',
  ).firstMatch(raw);
  if (partial != null) {
    return l10n.timelineSubtitlePartialReturnLines(
      int.parse(partial.group(1)!),
      int.parse(partial.group(2)!),
    );
  }

  final Match? jobsCount = RegExp(
    r'^Completed (\d+) job line\(s\)\.$',
  ).firstMatch(raw);
  if (jobsCount != null) {
    return l10n.timelineSubtitleJobsCompletedCount(
      int.parse(jobsCount.group(1)!),
    );
  }

  // Legacy cancel / return with optional discount + note tails.
  String remainder = raw;
  String? discount;
  String? note;
  final Match? discountMatch = RegExp(
    r' Discount (.+)\.$',
  ).firstMatch(remainder);
  if (discountMatch != null) {
    discount = discountMatch.group(1);
    remainder = remainder.replaceFirst(discountMatch.group(0)!, '');
  }
  final Match? noteMatch = RegExp(r' Note: (.+)$').firstMatch(remainder);
  if (noteMatch != null) {
    note = noteMatch.group(1);
    remainder = remainder.replaceFirst(noteMatch.group(0)!, '').trimRight();
  }

  String? base;
  switch (remainder) {
    case 'All lines returned by staff.':
      base = l10n.timelineSubtitleAllLinesReturned;
    case 'All lines returned. Late fee applied.':
      base = l10n.timelineSubtitleAllLinesReturnedLate;
    default:
      final Match? partialRem = RegExp(
        r'^Returned (\d+) of (\d+) lines\.$',
      ).firstMatch(remainder);
      if (partialRem != null) {
        base = l10n.timelineSubtitlePartialReturnLines(
          int.parse(partialRem.group(1)!),
          int.parse(partialRem.group(2)!),
        );
      } else {
        final Match? cancel = RegExp(
          r'^Kept (.+); returned (.+)\.$',
        ).firstMatch(remainder);
        if (cancel != null) {
          base = l10n.timelineSubtitleCancelSettlement(
            cancel.group(1)!,
            cancel.group(2)!,
          );
        }
      }
  }

  if (base == null) {
    return null;
  }
  final StringBuffer out = StringBuffer(base);
  if (discount != null) {
    out.write(' ');
    out.write(l10n.timelineSubtitleDiscountBit(discount));
  }
  if (note != null) {
    out.write(' ');
    out.write(l10n.timelineSubtitleNoteBit(note));
  }
  return out.toString();
}
