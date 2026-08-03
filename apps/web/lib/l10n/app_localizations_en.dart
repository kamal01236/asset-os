// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navRentals => 'Rentals';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navMore => 'More';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionNewRental => 'New Rental';

  @override
  String get issueItemAction => 'Issue';

  @override
  String get issueToCustomerAction => 'Issue';

  @override
  String get searchInventoryHint => 'Search by name or category';

  @override
  String get actionReturn => 'Return';

  @override
  String get actionReturnItem => 'Return Item';

  @override
  String get actionAddInventory => 'Add Inventory';

  @override
  String get actionScan => 'Scan';

  @override
  String get actionActions => 'Actions';

  @override
  String get searchAnything => 'Search Anything';

  @override
  String get todayAtAGlance => 'Today at a glance';

  @override
  String get kpiActive => 'Active';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusRented => 'Rented';

  @override
  String get statusDueToday => 'Due Today';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusArchived => 'Archived';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get aiSuggestionsTitle => 'AI suggestions (beta)';

  @override
  String get aiSuggestionsBody =>
      '• Follow up on 1 overdue rental\n• Move Bosch Drill Kit to premium pricing\n• Call Priya Patel for extension confirmation';

  @override
  String get offlineBanner => 'Working offline — changes will sync later.';

  @override
  String get noRentalsYetTitle => 'No rentals yet';

  @override
  String get noRentalsYetSubtitle =>
      'Start a new rental to create your first transaction.';

  @override
  String get unknownCustomer => 'Unknown customer';

  @override
  String rentalDueSubtitle(String customerName, String date) {
    return '$customerName • Due $date';
  }

  @override
  String inventoryAvailableSubtitle(String category, int available, int total) {
    return '$category • $available/$total available';
  }

  @override
  String get customerTrusted => 'Trusted';

  @override
  String get customerStandard => 'Standard';

  @override
  String customerSubtitle(String phone, String tier) {
    return '$phone • $tier';
  }

  @override
  String get offlineSimulationTitle => 'Offline simulation';

  @override
  String get offlineSimulationSubtitle =>
      'Demo only: verify non-blocking offline UX (not product positioning).';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose app language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get voiceSearchStubTitle => 'Voice Search (stub)';

  @override
  String get voiceSearchStubSubtitle =>
      'Placeholder for intent-based search commands.';

  @override
  String get businessTemplatesTitle => 'Business Templates';

  @override
  String get businessTemplatesSubtitle =>
      'Import starter inventory by industry (merge).';

  @override
  String phoneLabel(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get itemsHeading => 'Items';

  @override
  String get timelineHeading => 'Timeline';

  @override
  String get extendAction => 'Extend';

  @override
  String get shareAction => 'Share';

  @override
  String get extendPlaceholder => 'Extend is a placeholder action.';

  @override
  String get sharePlaceholder => 'Share is a placeholder action.';

  @override
  String get editInventoryTitle => 'Edit inventory';

  @override
  String get inventoryDetailTitle => 'Inventory detail';

  @override
  String get editTooltip => 'Edit';

  @override
  String get itemNameLabel => 'Item name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get totalUnitsLabel => 'Total units';

  @override
  String get totalUnitsHelper =>
      'Available adjusts with total; cannot exceed total.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint => 'Warranty / serial / condition';

  @override
  String get qrCodeLabel => 'QR code';

  @override
  String get cancel => 'Cancel';

  @override
  String get saving => 'Saving…';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get nameCategoryRequired => 'Name and category are required.';

  @override
  String get inventoryUpdated => 'Inventory updated.';

  @override
  String get customerProfileTitle => 'Customer profile';

  @override
  String get callAction => 'Call';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get whatsAppSubtitle => 'Placeholder integration hook';

  @override
  String get callPlaceholder => 'Call placeholder action.';

  @override
  String get whatsAppPlaceholder => 'WhatsApp placeholder action.';

  @override
  String get recentRentals => 'Recent rentals';

  @override
  String dueDate(String date) {
    return 'Due $date';
  }

  @override
  String returnedDate(String date) {
    return 'Returned $date';
  }

  @override
  String get searchHint => 'Find customer, rental, or inventory';

  @override
  String get searchSectionCustomers => 'Customers';

  @override
  String get searchSectionCurrentRentals => 'Current rentals';

  @override
  String get searchSectionPreviousRentals => 'Previous rentals';

  @override
  String get searchSectionInventory => 'Inventory';

  @override
  String noMatchingSection(String section) {
    return 'No matching $section';
  }

  @override
  String inventoryUnitsSubtitle(String category, int available, int total) {
    return '$category • $available/$total';
  }

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => '10-digit customer phone';

  @override
  String get existingCustomer => 'Existing customer';

  @override
  String existingCustomerSubtitle(String phone) {
    return '$phone • Existing customer';
  }

  @override
  String get customerNameNewLabel => 'Customer name (new)';

  @override
  String get customerNameNewHint => 'Only needed if new customer';

  @override
  String get selfKnownQuickPick => 'SELF Known';

  @override
  String get rentalNicknameLabel => 'Nickname for this rental';

  @override
  String get rentalNicknameHint => 'Who is taking the items?';

  @override
  String get rentalNicknameRequired =>
      'Enter a nickname for SELF Known rentals.';

  @override
  String reviewNickname(String nickname, String customerName) {
    return 'Nickname: $nickname · $customerName';
  }

  @override
  String rentalNicknameSubtitle(String customerName, String phone) {
    return '$customerName · $phone';
  }

  @override
  String rentalNicknameDueSubtitle(String nickname, String date) {
    return '$nickname • Due $date';
  }

  @override
  String get selectItems => 'Select items';

  @override
  String itemAvailableCount(String category, int available) {
    return '$category • $available available';
  }

  @override
  String get labelInstancesHeading => 'Name each item';

  @override
  String get labelInstancesHint =>
      'For novels/tools: enter this copy’s name and a short code.';

  @override
  String get instanceNameLabel => 'Instance name';

  @override
  String get instanceNameHint => 'e.g. Harry Potter';

  @override
  String get shortCodeLabel => 'Short code';

  @override
  String get shortCodeHint => 'e.g. NOV-042';

  @override
  String get instanceLabelsRequired =>
      'Enter an instance name and short code for each item.';

  @override
  String duplicateShortCode(String code) {
    return 'Short code $code is already in use on an active rental.';
  }

  @override
  String get inventoryInstancesNote =>
      'Individual copies are named with a short code when you issue a rental.';

  @override
  String get reviewHeading => 'Review';

  @override
  String reviewPhone(String phone) {
    return 'Phone: $phone';
  }

  @override
  String reviewName(String name) {
    return 'Name: $name';
  }

  @override
  String get reviewItemsLabel => 'Items:';

  @override
  String get back => 'Back';

  @override
  String get continueAction => 'Continue';

  @override
  String get confirmRental => 'Confirm rental';

  @override
  String get noActiveRentalsTitle => 'No active rentals';

  @override
  String get noActiveRentalsSubtitle => 'Everything is already returned.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String rentalReturned(String id) {
    return '$id returned';
  }

  @override
  String get quickAdd => 'Quick add';

  @override
  String get unitsLabel => 'Units';

  @override
  String get advancedFields => 'Advanced fields';

  @override
  String get advancedFieldsSubtitle => 'Optional in MVP';

  @override
  String get saveItem => 'Save item';

  @override
  String get scanIntro =>
      'Use camera integration in the next phase. For now, paste/enter QR text.';

  @override
  String get qrContentLabel => 'QR content';

  @override
  String get qrContentHint => 'customer:1001';

  @override
  String get noEntityMatched => 'No entity matched this code.';

  @override
  String get openLinkedRecord => 'Open linked record';

  @override
  String get voiceSearchTitle => 'Voice Search';

  @override
  String get voiceSearchBody =>
      'Stub only: voice commands map to universal search intents in phase 5+.';

  @override
  String get templatesIntro =>
      'Pick an industry, then choose which starter items to add. Existing items with the same name are kept (merge).';

  @override
  String starterItemsCount(int count) {
    return '$count starter items';
  }

  @override
  String templateCardSubtitle(String description, int count) {
    return '$description\n$count starter items';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get clearSelection => 'Clear';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String unitSingular(int count) {
    return '$count unit';
  }

  @override
  String unitPlural(int count) {
    return '$count units';
  }

  @override
  String templateItemSubtitle(String category, String units) {
    return '$category • $units';
  }

  @override
  String get adding => 'Adding…';

  @override
  String get addSelectedToInventory => 'Add selected to inventory';

  @override
  String templateImportResult(int added, int skipped) {
    return 'Added $added items ($skipped already present)';
  }

  @override
  String get myWhatsAppTitle => 'My WhatsApp number';

  @override
  String get myWhatsAppSubtitle => 'Used to share reports to yourself';

  @override
  String get myWhatsAppHint => '10-digit mobile (default +91)';

  @override
  String get myWhatsAppSaved => 'WhatsApp number saved.';

  @override
  String get myWhatsAppInvalid =>
      'Enter a valid 10-digit (or full) mobile number.';

  @override
  String get shareReportsTitle => 'Share reports';

  @override
  String get shareReportsSubtitle =>
      'Generate and send a text report to your WhatsApp';

  @override
  String get reportTypeLabel => 'Report type';

  @override
  String get reportTypeSummary => 'Summary';

  @override
  String get reportTypeCustomerWise => 'Customer-wise';

  @override
  String get reportTypeInventoryWise => 'Inventory-wise';

  @override
  String get reportPeriodLabel => 'Period';

  @override
  String get reportPeriodDaily => 'Daily';

  @override
  String get reportPeriodWeekly => 'Weekly';

  @override
  String get reportPeriodMonthly => 'Monthly';

  @override
  String get reportPeriodCustom => 'Custom';

  @override
  String get reportStartDate => 'Start date';

  @override
  String get reportEndDate => 'End date';

  @override
  String get reportPreviewLabel => 'Preview';

  @override
  String get shareToMyWhatsApp => 'Share to my WhatsApp';

  @override
  String get copyReportText => 'Copy text';

  @override
  String get reportCopied => 'Report copied to clipboard.';

  @override
  String get reportWhatsAppOpened => 'WhatsApp opened — tap Send to deliver.';

  @override
  String get reportWhatsAppFallback =>
      'Could not open WhatsApp. Report copied instead.';

  @override
  String get reportMissingPhone => 'Set My WhatsApp number in More first.';

  @override
  String get setWhatsAppAction => 'Set number';

  @override
  String get saveAction => 'Save';

  @override
  String get billingModeLabel => 'Billing mode';

  @override
  String get billingModeDaily => 'Daily';

  @override
  String get billingModeWeekly => 'Weekly';

  @override
  String get billingModeMonthly => 'Monthly';

  @override
  String get billingModeFixed => 'Fixed';

  @override
  String get billingModeCustom => 'Custom';

  @override
  String get rateAmountLabel => 'Rate (₹)';

  @override
  String get rateAmountHint => 'e.g. 50';

  @override
  String get lateFeePerDayLabel => 'Late fee per day (₹)';

  @override
  String get lateFeePerDayHint => 'Optional, e.g. 5';

  @override
  String get pricingSectionTitle => 'Rental pricing';

  @override
  String get durationHeading => 'Rental duration';

  @override
  String get durationHint => 'Based on the first selected item’s billing mode.';

  @override
  String get durationUnitsLabel => 'Duration';

  @override
  String get durationUnitsDaily => 'Number of days';

  @override
  String get durationUnitsWeekly => 'Number of weeks';

  @override
  String get durationUnitsMonthly => 'Number of months';

  @override
  String get durationUnitsFixed => 'Due in (days)';

  @override
  String get customEndDateLabel => 'Return by';

  @override
  String chargePreviewDue(String date) {
    return 'Due $date';
  }

  @override
  String chargeLineAmount(String item, String amount) {
    return '$item — $amount';
  }

  @override
  String chargeBaseLabel(String amount) {
    return 'Base: $amount';
  }

  @override
  String chargeLateLabel(String amount) {
    return 'Late fee: $amount';
  }

  @override
  String chargeTotalLabel(String amount) {
    return 'Total: $amount';
  }

  @override
  String get reviewChargesLabel => 'Charges:';

  @override
  String reviewDueLabel(String date) {
    return 'Due: $date';
  }

  @override
  String rentalAmountSubtitle(String date, String amount) {
    return 'Due $date · $amount';
  }

  @override
  String inventoryRateSubtitle(String mode, String rate) {
    return '$mode · $rate';
  }

  @override
  String get chargesHeading => 'Charges';

  @override
  String get durationRequired => 'Enter a valid duration (at least 1).';

  @override
  String get customEndRequired => 'Pick a return-by date on or after today.';

  @override
  String get depositBalanceLabel => 'Deposit balance';

  @override
  String depositBalanceAmount(String amount) {
    return 'Deposit: $amount';
  }

  @override
  String get depositAddAction => 'Add deposit';

  @override
  String get depositRefundAction => 'Refund';

  @override
  String get depositAmountLabel => 'Amount (₹)';

  @override
  String get depositAmountHint => 'e.g. 500';

  @override
  String get depositNoteLabel => 'Note (optional)';

  @override
  String get depositNoteHint => 'Reason or reference';

  @override
  String get depositTopUpTitle => 'Add deposit';

  @override
  String get depositRefundTitle => 'Refund deposit';

  @override
  String get depositConfirmTopUp => 'Add';

  @override
  String get depositConfirmRefund => 'Refund';

  @override
  String get depositInvalidAmount => 'Enter an amount greater than zero.';

  @override
  String get depositRefundExceeds =>
      'Refund cannot exceed the current deposit balance.';

  @override
  String depositTopUpSuccess(String amount) {
    return 'Deposit updated to $amount.';
  }

  @override
  String depositRefundSuccess(String amount) {
    return 'Refunded. Deposit now $amount.';
  }

  @override
  String get depositLedgerHeading => 'Deposit history';

  @override
  String get depositLedgerEmpty => 'No deposit activity yet.';

  @override
  String depositLedgerTopUp(String amount) {
    return 'Top-up $amount';
  }

  @override
  String depositLedgerApply(String amount) {
    return 'Applied on return $amount';
  }

  @override
  String depositLedgerRefund(String amount) {
    return 'Refund $amount';
  }

  @override
  String depositLedgerAdjust(String amount) {
    return 'Adjust $amount';
  }

  @override
  String depositLedgerBalanceAfter(String amount) {
    return 'Balance $amount';
  }

  @override
  String depositAvailableLabel(String amount) {
    return 'Deposit available: $amount';
  }

  @override
  String depositWillApplyLabel(String amount) {
    return 'Will apply from deposit: $amount';
  }

  @override
  String depositRemainingDueLabel(String amount) {
    return 'Remaining due: $amount';
  }

  @override
  String depositLeftoverLabel(String amount) {
    return 'Leftover deposit: $amount';
  }

  @override
  String depositAppliedLabel(String amount) {
    return 'Deposit applied: $amount';
  }

  @override
  String depositNetDueLabel(String amount) {
    return 'Net due: $amount';
  }

  @override
  String get returnSettlementTitle => 'Return settlement';

  @override
  String get confirmReturnAction => 'Confirm return';

  @override
  String depositReturnSnackApplied(String applied, String balance) {
    return 'Applied $applied from deposit; balance now $balance.';
  }

  @override
  String depositReturnSnackDue(String applied, String due) {
    return 'Applied $applied from deposit; remaining due $due.';
  }

  @override
  String depositReturnSnackNoDeposit(String total) {
    return 'Returned. Total $total due in cash.';
  }

  @override
  String customerSubtitleWithDeposit(String phone, String tier, String amount) {
    return '$phone • $tier • Deposit $amount';
  }

  @override
  String existingCustomerWithDeposit(String phone, String amount) {
    return '$phone • Existing • Deposit $amount';
  }

  @override
  String get returnSelectedAction => 'Return selected';

  @override
  String get returnAllAction => 'Return all';

  @override
  String get replaceLineAction => 'Replace';

  @override
  String get selectLinesToReturn => 'Select lines to return';

  @override
  String get openLinesHeading => 'Out';

  @override
  String get returnedLinesHeading => 'Returned';

  @override
  String get lineReturnedLabel => 'Returned';

  @override
  String get lineOpenLabel => 'Out';

  @override
  String partialReturnSnack(int count) {
    return 'Returned $count item(s). Rental still active.';
  }

  @override
  String get replaceFlowTitle => 'Replace item';

  @override
  String get replaceSettlementIntro =>
      'Settle the old item, then issue a replacement.';

  @override
  String get replaceConfirmAction => 'Replace & issue';

  @override
  String replaceSuccessSnack(String newId, String balance) {
    return 'Settled old line; opened $newId. Deposit balance $balance.';
  }

  @override
  String get noLinesSelected => 'Select at least one item to return.';

  @override
  String linesOpenCount(int open, int total) {
    return '$open of $total still out';
  }

  @override
  String lineChargePreview(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get clearFilter => 'Clear';

  @override
  String showingFilter(String label) {
    return 'Showing: $label';
  }

  @override
  String get needsAttentionTitle => 'Needs attention';

  @override
  String get needsAttentionEmptyTitle => 'Nothing needs attention';

  @override
  String get needsAttentionEmptySubtitle =>
      'Due today and overdue rentals will show up here.';

  @override
  String get recentActivityTitle => 'Recent activity';

  @override
  String get recentActivityEmpty => 'No recent rentals or returns yet.';

  @override
  String get homeFilterEmptyTitle => 'No matches';

  @override
  String homeFilterEmptyRentalsSubtitle(String label) {
    return 'No rentals match $label right now.';
  }

  @override
  String get homeFilterEmptyInventorySubtitle =>
      'No inventory with remaining units right now.';

  @override
  String get customizeHomeTitle => 'Customize Home';

  @override
  String get customizeHomeSubtitle => 'Show or hide Home modules.';

  @override
  String get customizeHomeIntro =>
      'Search stays on. Toggle other modules to keep Home focused.';

  @override
  String get moduleSearch => 'Search';

  @override
  String get moduleSearchLocked => 'Always on';

  @override
  String get moduleKpis => 'Status chips';

  @override
  String get moduleKpisSubtitle =>
      'Compact chips; tap opens Rentals or Inventory filtered';

  @override
  String get moduleFilterResults => 'Filter results';

  @override
  String get moduleFilterResultsSubtitle =>
      'Optional in-place list under chips when a Home filter is set';

  @override
  String get moduleNeedsAttention => 'Needs attention';

  @override
  String get moduleNeedsAttentionSubtitle => 'Due today and overdue rentals';

  @override
  String get moduleQuickActions => 'Quick actions';

  @override
  String get moduleQuickActionsSubtitle => 'New Rental, Return, Add Inventory';

  @override
  String get moduleRecentActivity => 'Recent activity';

  @override
  String get moduleRecentActivitySubtitle => 'Latest rentals and returns';

  @override
  String get moduleSuggestions => 'AI suggestions';

  @override
  String get moduleSuggestionsSubtitle => 'Optional beta tips';

  @override
  String get applyHomeLayoutTitle => 'Apply Home layout?';

  @override
  String get applyHomeLayoutBody =>
      'Use this template’s recommended Home modules.';

  @override
  String get applyHomeLayoutCustomizedBody =>
      'You customized Home earlier. Replace it with this template’s layout?';

  @override
  String get applyHomeLayoutSkip => 'Keep current';

  @override
  String get applyHomeLayoutConfirm => 'Apply layout';

  @override
  String get applyHomeLayoutDone => 'Home layout updated.';

  @override
  String minMeaningfulTextError(int min) {
    return 'Enter at least $min characters.';
  }

  @override
  String get searchTypeMinChars => 'Type at least 3 characters';

  @override
  String get searchCustomersHint => 'Search by name, phone, or nickname';

  @override
  String get searchNoResults => 'No matches';

  @override
  String get dueDateOptionalLabel => 'Due date optional';

  @override
  String get dueDateOptionalSubtitle =>
      'Allow issuing without a fixed return date (charge accrues until return).';

  @override
  String get continueWithoutDueDate => 'Continue without due date';

  @override
  String get openEndedDurationHint =>
      'All selected items allow open-ended rentals. Enter a duration, or continue without a due date.';

  @override
  String get openEndedLabel => 'Open-ended';

  @override
  String get reviewOpenEndedLabel => 'Due: Open-ended (accrues until return)';

  @override
  String rentalAmountOpenEnded(String amount) {
    return 'Open-ended · $amount';
  }

  @override
  String get accruedAmountHint => 'Accrued so far';

  @override
  String get balanceAdvanceLabel => 'Advance';

  @override
  String get balancePendingLabel => 'Pending';

  @override
  String get balanceDueLabel => 'Due';

  @override
  String get balancesAsOfTodayHeading => 'Balances as of today';

  @override
  String balanceOpenItemsCount(int count) {
    return '$count item(s) out';
  }

  @override
  String customerSubtitleWithBalances(
    String phone,
    String tier,
    String advance,
    String pending,
    String due,
  ) {
    return '$phone • $tier • Advance $advance · Pending $pending · Due $due';
  }
}
