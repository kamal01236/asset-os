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
  String get navTransactions => 'Transactions';

  @override
  String get navResources => 'Resources';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navMore => 'More';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionNewRental => 'New Order';

  @override
  String get transactionsFilterAll => 'All';

  @override
  String get transactionsFilterOrders => 'Orders';

  @override
  String get transactionsFilterLoans => 'Loans';

  @override
  String get newTransaction => 'New';

  @override
  String get newOrder => 'New order';

  @override
  String get newLoan => 'New loan';

  @override
  String get transactionTypeOrder => 'Order';

  @override
  String get transactionTypeLoan => 'Loan';

  @override
  String get searchTransactionsHint => 'Search orders or loans';

  @override
  String get noTransactionsYetTitle => 'No transactions yet';

  @override
  String get noTransactionsYetSubtitle =>
      'Create an order or loan to get started.';

  @override
  String get customerTransactionsHeading => 'Transactions';

  @override
  String get customerTransactionsEmpty => 'No transactions for this customer.';

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
  String get actionAddResource => 'Add Resource';

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
  String get noRentalsYetTitle => 'No orders yet';

  @override
  String get noRentalsYetSubtitle =>
      'Start a new order to create your first transaction.';

  @override
  String get unknownCustomer => 'Unknown customer';

  @override
  String inventoryAvailableSubtitle(String category, int available, int total) {
    return '$category • $available/$total available';
  }

  @override
  String get customerTrusted => 'Trusted';

  @override
  String get customerStandard => 'Standard';

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
  String get themeTitle => 'Theme';

  @override
  String get themeSubtitle => 'Choose dark or light appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get voiceSearchStubTitle => 'Voice Search (stub)';

  @override
  String get voiceSearchStubSubtitle =>
      'Placeholder for intent-based search commands.';

  @override
  String get businessTemplatesTitle => 'Business Templates';

  @override
  String get businessTemplatesSubtitle =>
      'Switch your active business pack anytime. Existing loans and orders stay in Transactions; New Loan needs Money Lending active.';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageSubtitle => 'You can change this later in More.';

  @override
  String get onboardingModeTitle => 'How do you want to work?';

  @override
  String get onboardingModeSubtitle =>
      'Offline is the default — everything stays on this device.';

  @override
  String get onboardingModeOfflineTitle => 'Offline';

  @override
  String get onboardingModeOfflineSubtitle =>
      'Works without internet. Data stays local-first on this device.';

  @override
  String get onboardingModeOnlineTitle => 'Online';

  @override
  String get onboardingModeOnlineSubtitle =>
      'WhatsApp reports and future sync / OTP ownership proof.';

  @override
  String get onboardingWhatsAppTitle => 'Your WhatsApp number';

  @override
  String get onboardingWhatsAppSubtitle =>
      'Required for online mode so we can verify ownership and share reports to you.';

  @override
  String get onboardingWhatsAppOtpLabel => 'OTP';

  @override
  String get onboardingWhatsAppOtpHint => 'Coming later';

  @override
  String get onboardingWhatsAppOtpLater =>
      'We\'ll verify this number by OTP later. Saving the number is enough for now.';

  @override
  String get onboardingTemplateTitle => 'Choose your business type';

  @override
  String get onboardingTemplateSubtitle =>
      'We\'ll add starter resources for your industry. You can add more later from More → Business Templates.';

  @override
  String get onboardingTemplateConfirm => 'Use this template';

  @override
  String get onboardingTemplateCancel => 'Back';

  @override
  String onboardingTemplateConfirmBody(int count, String name) {
    return 'Add all $count starter items for $name and set the recommended Home layout?';
  }

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
  String get extendDueTitle => 'Extend due date';

  @override
  String get extendDueSuccess => 'Due date extended.';

  @override
  String get extendDueInvalid => 'Pick a date after the current due date.';

  @override
  String get unitCodePrefixLabel => 'Code prefix';

  @override
  String get unitCodePrefixHint => 'e.g. SEAT or CAM';

  @override
  String get unitCodePrefixHelper =>
      'Builds short codes PREFIX-001…N from total units.';

  @override
  String get pickShortCodeLabel => 'Short code';

  @override
  String get pickShortCodeHint => 'Pick an available code';

  @override
  String get noAvailableUnitCodes => 'No available codes in the pool.';

  @override
  String seatPaymentDueLabel(String code) {
    return '$code payment due';
  }

  @override
  String get editResourceTitle => 'Edit resource';

  @override
  String get resourceDetailTitle => 'Resource detail';

  @override
  String get editTooltip => 'Edit';

  @override
  String get itemNameLabel => 'Item name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryOtherLabel => 'Other';

  @override
  String get categoryGeneralLabel => 'General';

  @override
  String get categoryCustomLabel => 'Enter category';

  @override
  String get categoryCustomHint => 'Custom category name';

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
  String get resourceUpdated => 'Resource updated.';

  @override
  String get resourceDeletedSnack => 'Resource deleted.';

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
  String returnedDate(String date) {
    return 'Returned $date';
  }

  @override
  String get searchHint => 'Find customer, order, or resource';

  @override
  String get searchSectionCustomers => 'Customers';

  @override
  String get searchSectionCurrentRentals => 'Current orders';

  @override
  String get searchSectionPreviousRentals => 'Previous orders';

  @override
  String get searchSectionResources => 'Resources';

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
  String existingCustomerSubtitle(String phone) {
    return '$phone • Existing customer';
  }

  @override
  String get customerNameNewLabel => 'Name';

  @override
  String get customerNameNewHint => 'Customer name';

  @override
  String get noPhoneNumberLabel => 'No phone number';

  @override
  String get noPhoneOptionalNameHint => 'Optional display name for this order';

  @override
  String get customerTypeaheadEmpty => 'No matching customers';

  @override
  String get phoneRequiredError =>
      'Enter a 10-digit phone number, or choose No phone number.';

  @override
  String customerSuggestionSubtitle(String name, String phone) {
    return '$name · $phone';
  }

  @override
  String rentalNicknameSubtitle(String customerName, String phone) {
    return '$customerName · $phone';
  }

  @override
  String get instanceNameLabel => 'Unit name';

  @override
  String get instanceNameHint => 'e.g. Harry Potter';

  @override
  String get shortCodeLabel => 'Short code';

  @override
  String get shortCodeHint => 'e.g. NOV-042';

  @override
  String get instanceLabelsRequired =>
      'Enter a unit name and short code for each item.';

  @override
  String duplicateShortCode(String code) {
    return 'Short code $code is already in use on an active order.';
  }

  @override
  String get inventoryInstancesNote =>
      'Individual copies are named with a short code when you generate an order.';

  @override
  String get back => 'Back';

  @override
  String get continueAction => 'Continue';

  @override
  String get confirmRental => 'Generate Order';

  @override
  String get noActiveRentalsTitle => 'No active orders';

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
  String get extraFieldsSectionTitle => 'Extra fields';

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
      'Choose the active industry pack. Switching replaces Home layout and enabled resource types. Existing loans, orders, and inventory stay. New Loan is available when Money Lending is active.';

  @override
  String get activeTemplateLabel => 'Active pack';

  @override
  String get activeTemplateHint => 'Select a business pack';

  @override
  String get switchTemplateTitle => 'Switch business pack?';

  @override
  String switchTemplateBody(String name) {
    return 'Activate $name? Home layout and resource types will match this pack. Existing loans, orders, and inventory are kept.';
  }

  @override
  String get switchTemplateConfirm => 'Switch';

  @override
  String get switchTemplateCancel => 'Cancel';

  @override
  String get switchTemplateDone => 'Business pack updated.';

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
  String get applyTemplateSelection => 'Apply';

  @override
  String get applyingTemplateSelection => 'Applying…';

  @override
  String templateApplyResult(
    int added,
    int reactivated,
    int deactivated,
    int skipped,
  ) {
    return 'Added $added, restored $reactivated, removed $deactivated ($skipped unchanged)';
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
  String get reportTypeResourcesWise => 'Resources-wise';

  @override
  String get reportTypeUnitOccupancy => 'Unit occupancy';

  @override
  String get reportNoUnitPools => 'No resources with a unit code prefix.';

  @override
  String get reportNoOccupiedUnits => 'No units currently out.';

  @override
  String reportUnitOccupancyItemHeading(String name, int out, int total) {
    return '$name · out $out / $total';
  }

  @override
  String reportUnitOccupancyRow(String code, String status, String customer) {
    return '$code · $status · $customer';
  }

  @override
  String get reportUnitStatusOccupied => 'Occupied';

  @override
  String get reportUnitStatusAvailable => 'Available';

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
  String get printReport => 'Print';

  @override
  String reportStillOutAsOf(String date) {
    return 'Still out (as of $date)';
  }

  @override
  String reportIssuedCount(int count) {
    return 'Issued: $count';
  }

  @override
  String reportStillOutCount(int count) {
    return 'Still out: $count';
  }

  @override
  String reportMoreCount(int count) {
    return '+$count more';
  }

  @override
  String get reportKpiIssued => 'Issued';

  @override
  String get reportKpiReturned => 'Returned';

  @override
  String get reportKpiStillOut => 'Still out';

  @override
  String get reportKpiOverdue => 'Overdue';

  @override
  String get reportKpiChargesOpened => 'Charges opened';

  @override
  String get reportKpiChargesReturned => 'Charges returned';

  @override
  String get reportKpiDepositApplied => 'Deposit applied';

  @override
  String get reportKpiSellCollected => 'Sell collected';

  @override
  String get reportKpiBalanceDue => 'Balance due';

  @override
  String get reportKpiPendingLoans => 'Pending loans';

  @override
  String get reportSectionIssued => 'Issued';

  @override
  String get reportSectionReturned => 'Returned';

  @override
  String get reportColParty => 'Party';

  @override
  String get reportColIssued => 'Issued';

  @override
  String get reportColReturned => 'Returned';

  @override
  String get reportColAmount => 'Amount';

  @override
  String get reportColStatus => 'Status';

  @override
  String get reportColItems => 'Items';

  @override
  String get reportColResource => 'Resource';

  @override
  String get reportColOut => 'Out';

  @override
  String get reportColAvail => 'Avail';

  @override
  String get reportColCode => 'Code';

  @override
  String get reportColCustomer => 'Customer';

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
  String get securityDepositLabel => 'Security deposit (₹)';

  @override
  String get securityDepositHint => 'e.g. 500';

  @override
  String get securityDepositHelper =>
      'Suggested advance per unit on rental orders';

  @override
  String securityDepositShort(String amount) {
    return 'Security $amount';
  }

  @override
  String get pricingSectionTitle => 'Rental pricing';

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
  String chargeTotalLabel(String amount) {
    return 'Total: $amount';
  }

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
  String get depositAmountHint => 'e.g. 500';

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
  String get returnSettlementTitle => 'Return settlement';

  @override
  String get confirmReturnAction => 'Confirm return';

  @override
  String get returnFinalAmountLabel => 'Final amount to collect';

  @override
  String get returnFinalAmountHint => '0 or less than computed total';

  @override
  String returnDiscountLabel(String amount) {
    return 'Discount $amount';
  }

  @override
  String get returnNoteLabel => 'Note (optional)';

  @override
  String get returnNoteHint => 'Max 20 characters';

  @override
  String get deleteOrderAction => 'Cancel order';

  @override
  String get deleteOrderTitle => 'Cancel order';

  @override
  String get confirmDeleteOrderAction => 'Cancel order';

  @override
  String get deleteOrderKeptLabel => 'Amount to keep';

  @override
  String get deleteOrderReturnedLabel => 'Amount to return';

  @override
  String get deleteOrderNoteLabel => 'Note (optional)';

  @override
  String get deleteOrderInvalidSettlement =>
      'Kept + returned cannot exceed order deposit.';

  @override
  String get deleteOrderBlockedPartial =>
      'Cannot cancel an order after items were returned.';

  @override
  String get deleteOrderFailed => 'Could not cancel this order.';

  @override
  String deleteOrderSuccessSnack(String balance) {
    return 'Order cancelled. Deposit balance $balance.';
  }

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
  String get returnSelectedAction => 'Return selected';

  @override
  String get returnAllAction => 'Return all';

  @override
  String get returnByQuantityHint => 'Choose how many to return for each item';

  @override
  String skuIssuedReturnedRemaining(int issued, int returned, int remaining) {
    return 'Issued $issued · Returned $returned · Still out $remaining';
  }

  @override
  String get returnQtyLabel => 'Return qty';

  @override
  String get markRemainingLostAction => 'Mark remaining lost';

  @override
  String get markSelectedLostAction => 'Mark selected lost';

  @override
  String get confirmMarkLostTitle => 'Mark units lost?';

  @override
  String confirmMarkLostBody(int count) {
    return 'Close $count unit(s) without restoring stock. Order stays open if anything is still out.';
  }

  @override
  String get confirmMarkLostAction => 'Mark lost';

  @override
  String unitsLostSnack(int count) {
    return 'Marked $count unit(s) lost.';
  }

  @override
  String get lineLostLabel => 'Lost';

  @override
  String get lostLinesHeading => 'Lost';

  @override
  String get pickUnitsToReturn => 'Pick units to return';

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
  String get needsAttentionEmptySubtitle =>
      'Due today and overdue orders will show up here.';

  @override
  String get recentActivityTitle => 'Recent activity';

  @override
  String get recentActivityEmpty => 'No recent orders or returns yet.';

  @override
  String get homeFilterEmptyTitle => 'No matches';

  @override
  String homeFilterEmptyRentalsSubtitle(String label) {
    return 'No orders match $label right now.';
  }

  @override
  String get homeFilterEmptyResourcesSubtitle =>
      'No resources with remaining units right now.';

  @override
  String get customizeHomeTitle => 'Customize Home';

  @override
  String get customizeHomeSubtitle => 'Show or hide Home modules.';

  @override
  String get customizeHomeIntro =>
      'Search stays on. Toggle other modules to keep Home focused.';

  @override
  String get enabledResourceTypesTitle => 'Enabled resource types';

  @override
  String get enabledResourceTypesSubtitle =>
      'Choose which types appear under New Order → More options.';

  @override
  String get enabledResourceTypesIntro =>
      'Toggle types for New Order fulfillment (Rent / Sell / Job). Importing template items merges types into this list. Applying a template’s Home layout replaces this list with the template’s set.';

  @override
  String get enabledResourceTypesKeepOne => 'Keep at least one type enabled.';

  @override
  String get moduleSearch => 'Search';

  @override
  String get moduleSearchLocked => 'Always on';

  @override
  String get moduleKpis => 'Status chips';

  @override
  String get moduleKpisSubtitle =>
      'Compact chips; tap opens Orders or Resources filtered';

  @override
  String get moduleFilterResults => 'Filter results';

  @override
  String get moduleFilterResultsSubtitle =>
      'Optional in-place list under chips when a Home filter is set';

  @override
  String get moduleNeedsAttention => 'Needs attention';

  @override
  String get moduleNeedsAttentionSubtitle => 'Due today and overdue orders';

  @override
  String get modulePendingJobs => 'Pending jobs';

  @override
  String get modulePendingJobsSubtitle =>
      'Open orders with unfinished job lines';

  @override
  String get pendingJobsTitle => 'Pending jobs';

  @override
  String get pendingJobsEmptySubtitle => 'No open job lines right now.';

  @override
  String get moduleQuickActions => 'Quick actions';

  @override
  String get moduleQuickActionsSubtitle => 'New Order, Return, Add Resource';

  @override
  String get moduleRecentActivity => 'Recent activity';

  @override
  String get moduleRecentActivitySubtitle => 'Latest orders and returns';

  @override
  String get moduleSuggestions => 'AI suggestions';

  @override
  String get moduleSuggestionsSubtitle => 'Optional beta tips';

  @override
  String minMeaningfulTextError(int min) {
    return 'Enter at least $min characters.';
  }

  @override
  String get searchCustomersHint => 'Search by name or phone';

  @override
  String get searchNoResults => 'No matches';

  @override
  String get dueDateOptionalLabel => 'Due date optional';

  @override
  String get dueDateOptionalSubtitle =>
      'Allow issuing without a fixed return date (charge accrues until return).';

  @override
  String get allowsDynamicPricingLabel => 'Allow dynamic pricing';

  @override
  String get allowsDynamicPricingSubtitle =>
      'Staff can change the rate on New Order for this item. Catalog changes only affect new orders.';

  @override
  String get orderLineRateLabel => 'Rate for this order (₹)';

  @override
  String get orderLineRateHint =>
      'Catalog default can be changed for this rental';

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
  String get balanceCreditLabel => 'Credit';

  @override
  String get balanceNetLabel => 'Net';

  @override
  String get balancesAsOfTodayHeading => 'Balances as of today';

  @override
  String balanceOpenItemsCount(int count) {
    return '$count item(s) out';
  }

  @override
  String get orderStatusOpen => 'Open';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get requiresUnitIdentityLabel => 'Requires unit name/id';

  @override
  String get requiresUnitIdentitySubtitle =>
      'On for parent categories (e.g. Novels). Off for individual items that share one catalog name.';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String labelUnitHeading(String name, int index) {
    return '$name #$index';
  }

  @override
  String get labelsAutoAssignedHint =>
      'Individual items get catalog name and an auto short code.';

  @override
  String get workflowStatusHeading => 'Workflow status';

  @override
  String get workflowAdvanceAction => 'Advance';

  @override
  String get workflowPickStatusAction => 'Pick status';

  @override
  String get workflowStatusTerminalHint => 'Order completed for this pipeline.';

  @override
  String get addOrderLineAction => 'Add line';

  @override
  String get removeOrderLineAction => 'Remove line';

  @override
  String get selectResourceItemLabel => 'Resource';

  @override
  String orderLineHeading(int number) {
    return 'Line $number';
  }

  @override
  String orderTotalLabel(String amount) {
    return 'Order total: $amount';
  }

  @override
  String get orderSummaryHeading => 'Order summary';

  @override
  String orderSummaryQuantity(int quantity) {
    return 'Qty $quantity';
  }

  @override
  String orderSummaryUnitCharge(String amount) {
    return 'Unit $amount';
  }

  @override
  String get moreOptions => 'More options';

  @override
  String get addUnitLabelsAction => 'Add unit labels';

  @override
  String get itemKindRentalLabel => 'Rental';

  @override
  String get itemKindSaleLabel => 'Sale';

  @override
  String get itemKindServiceLabel => 'Service';

  @override
  String get itemKindJobLabel => 'Job';

  @override
  String get itemKindSubscriptionLabel => 'Subscription';

  @override
  String get itemKindMembershipLabel => 'Membership';

  @override
  String get itemKindLoanLabel => 'Loan';

  @override
  String get itemKindFinancialLabel => 'Financial';

  @override
  String get itemKindCustomLabel => 'Custom';

  @override
  String get itemKindSaleBadge => 'Sale';

  @override
  String get itemKindServiceBadge => 'Service';

  @override
  String get itemKindJobBadge => 'Job';

  @override
  String get itemKindSubscriptionBadge => 'Subscription';

  @override
  String get itemKindMembershipBadge => 'Membership';

  @override
  String get itemKindLoanBadge => 'Loan';

  @override
  String get itemKindFinancialBadge => 'Financial';

  @override
  String get itemKindCustomBadge => 'Custom';

  @override
  String get lineFulfillmentRent => 'Rent';

  @override
  String get lineFulfillmentSell => 'Sell';

  @override
  String get lineFulfillmentJob => 'Job';

  @override
  String get saleAmountLabel => 'Sale amount';

  @override
  String get saleAmountHint => 'Amount in rupees';

  @override
  String get jobAmountLabel => 'Job charge';

  @override
  String get jobAmountHint => 'Amount in rupees';

  @override
  String get soldLineBadge => 'Sold';

  @override
  String get completedJobLineBadge => 'Completed';

  @override
  String get selectLinesToComplete => 'Select job lines to mark complete';

  @override
  String get markCompleteAllAction => 'Mark all complete';

  @override
  String get markCompleteSelectedAction => 'Mark complete';

  @override
  String get confirmCompleteJobsTitle => 'Mark jobs complete?';

  @override
  String confirmCompleteJobsBody(int count) {
    return 'Close $count job line(s). Stock is not restored.';
  }

  @override
  String get jobsCompletedSnack => 'Jobs marked complete';

  @override
  String get orderNotesHeading => 'Notes';

  @override
  String get addOrderNoteAction => 'Add note';

  @override
  String get orderNoteBodyLabel => 'Note';

  @override
  String get orderNoteBodyHint => 'Terms, measurements, or other details';

  @override
  String get orderNoteKindLabel => 'Kind';

  @override
  String get orderNoteKindGeneral => 'General';

  @override
  String get orderNoteKindTerms => 'Terms';

  @override
  String get orderNoteKindMeasurement => 'Measurement';

  @override
  String get orderNoteLineLabel => 'Link to line';

  @override
  String get orderNoteWholeOrder => 'Whole order';

  @override
  String get orderNotesEmpty => 'No notes yet.';

  @override
  String get orderNoteAddedSnack => 'Note added';

  @override
  String get orderBillAmountLabel => 'Bill';

  @override
  String get orderDepositShortLabel => 'Advance';

  @override
  String get ordersFilterAll => 'All';

  @override
  String get ordersFilterOpen => 'Open';

  @override
  String get ordersFilterCompleted => 'Completed';

  @override
  String get ordersFilterPendingJobs => 'Pending jobs';

  @override
  String get searchOrdersHint => 'Search by party, id, or item';

  @override
  String inventoryStockMeta(String category, int available, int total) {
    return '$category · $available/$total';
  }

  @override
  String get moneyLabelBase => 'Base';

  @override
  String get moneyLabelLate => 'Late fee';

  @override
  String get moneyLabelTotal => 'Total';

  @override
  String get moneyLabelDeposit => 'Advance';

  @override
  String get moneyLabelWillApply => 'Will apply';

  @override
  String get moneyLabelRemainingDue => 'Remaining due';

  @override
  String get moneyLabelLeftover => 'Leftover advance';

  @override
  String get moneyLabelNetDue => 'Net due';

  @override
  String get reportWhatsAppGateBanner =>
      'Set your WhatsApp number in More to share reports.';

  @override
  String get reportConfigureWhatsAppAction => 'Set WhatsApp';

  @override
  String get timelineEmpty => 'No rental events yet.';

  @override
  String get timelineTitleOrderOpened => 'Order opened';

  @override
  String get timelineTitleReplacementOpened => 'Replacement opened';

  @override
  String get timelineTitleSaleCompleted => 'Sale completed';

  @override
  String get timelineTitleJobOpened => 'Job opened';

  @override
  String get timelineTitleReturned => 'Returned';

  @override
  String get timelineTitlePartialReturn => 'Partial return';

  @override
  String get timelineTitleUnitsLost => 'Units lost';

  @override
  String get timelineTitleJobsCompleted => 'Jobs completed';

  @override
  String get timelineTitleJobCompleted => 'Job completed';

  @override
  String get timelineTitleOrderCancelled => 'Order cancelled';

  @override
  String get timelineTitleNoteAdded => 'Note added';

  @override
  String get timelineTitleDueToday => 'Due today';

  @override
  String get timelineTitleRentalOpened => 'Rental opened';

  @override
  String get timelineTitleStatusChanged => 'Status changed';

  @override
  String get timelineTitleDueExtended => 'Due extended';

  @override
  String get timelineTitleAutoVacated => 'Auto vacated';

  @override
  String get timelineTitlePaymentReceived => 'Payment received';

  @override
  String get timelineSubtitleCreatedOrderFlow =>
      'Created from phone-first order flow.';

  @override
  String get timelineSubtitleCreatedOrderFlowSale =>
      'Created from phone-first order flow (sale).';

  @override
  String get timelineSubtitleCreatedOrderFlowJob =>
      'Created from phone-first order flow (job).';

  @override
  String get timelineSubtitleCreatedOrderFlowMixed =>
      'Created from phone-first order flow (mixed).';

  @override
  String timelineSubtitleReplacementFor(String orderId) {
    return 'Replacement for $orderId.';
  }

  @override
  String timelineSubtitlePaymentReceived(
    String received,
    String sell,
    String advance,
  ) {
    return 'Received $received · sell $sell · advance $advance';
  }

  @override
  String get commercialStepHeading => 'Payment & security';

  @override
  String get commercialStepSubtitle =>
      'Collect only what this cart requires. Optional fields can be skipped and paid later from order detail.';

  @override
  String get commercialStepPay => 'Pay';

  @override
  String get commercialStepAdvance => 'Advance';

  @override
  String get commercialStepSecurity => 'Security';

  @override
  String get commercialStepMembershipRequired => 'Membership required';

  @override
  String get commercialMinPayLabel => 'Minimum due now';

  @override
  String get commercialSecurityRequiredHelper =>
      'Required before this order can be issued';

  @override
  String get commercialSubscriptionHint =>
      'Add a covering subscription on this order, or collect security when allowed.';

  @override
  String get commercialSubscriptionSatisfied =>
      'Membership is active for this customer.';

  @override
  String get subscriptionTierNone => 'None';

  @override
  String get subscriptionTierBasic => 'Basic';

  @override
  String get subscriptionTierStandard => 'Standard';

  @override
  String get subscriptionTierPro => 'Pro';

  @override
  String get subscriptionTierPremium => 'Premium';

  @override
  String get subscriptionPeriodDay => 'Day';

  @override
  String get subscriptionPeriodWeek => 'Week';

  @override
  String get subscriptionPeriodMonth => 'Month';

  @override
  String get subscriptionPeriodYear => 'Year';

  @override
  String get subscriptionSkuTierLabel => 'Subscription tier';

  @override
  String get subscriptionPeriodUnitLabel => 'Period unit';

  @override
  String get subscriptionPeriodCountLabel => 'Period count';

  @override
  String get minSubscriptionTierLabel => 'Requires subscription';

  @override
  String get minSubscriptionTierHelper =>
      'Minimum customer tier to issue this resource. None = ungated.';

  @override
  String get catalogResourceTypeLabel => 'Resource type';

  @override
  String subscriptionChipOk(String tier, String date) {
    return '$tier until $date — OK to issue';
  }

  @override
  String subscriptionChipUncovered(String tier) {
    return 'Customer needs $tier (or higher) to issue these items.';
  }

  @override
  String get subscriptionUpsellLabel => 'Add subscription to this order';

  @override
  String get subscriptionNamedCustomerRequired =>
      'A named customer with a phone is required for subscription access.';

  @override
  String get subscriptionHistoryHeading => 'Subscriptions';

  @override
  String get subscriptionNoneActive => 'No active subscription';

  @override
  String get subscriptionStatusCancelled => 'Cancelled';

  @override
  String get subscriptionStatusExpired => 'Expired';

  @override
  String customerSubscriptionMeta(String tier, String date) {
    return '$tier · $date';
  }

  @override
  String subscriptionUntilLabel(String tier, String date) {
    return '$tier until $date';
  }

  @override
  String get orderPaymentTitle => 'Payment';

  @override
  String get orderPaymentHeading => 'Collect payment';

  @override
  String get orderPaymentSubtitle =>
      'Sold items are due now. Security is held as order advance and applied on return.';

  @override
  String get paymentMinSoldLabel => 'Minimum payment (sold items)';

  @override
  String get paymentSellPaidLabel => 'Sell paid';

  @override
  String get paymentSellDiscountLabel => 'Sell discount';

  @override
  String get paymentSellOutstandingLabel => 'Sell still due';

  @override
  String get paymentSecurityLabel => 'Rental security / advance (₹)';

  @override
  String get paymentSecurityHint => 'Suggested from catalog; edit as needed';

  @override
  String get paymentSecurityHelper => 'Held on this order until return';

  @override
  String get paymentAmountReceivedLabel => 'Amount received (₹)';

  @override
  String get paymentAmountReceivedHint => 'Cash collected now';

  @override
  String get paymentTreatExcessAsDiscount => 'Treat excess as discount';

  @override
  String get paymentTreatExcessAsDiscountHint =>
      'Cap advance at the security amount above; do not hold extra';

  @override
  String get paymentAllocationPreview => 'Allocation preview';

  @override
  String get paymentPreviewSellCovered => 'Toward sold items';

  @override
  String get paymentPreviewSellDiscount => 'Sell discount';

  @override
  String get paymentPreviewAdvance => 'Advance to hold';

  @override
  String get paymentPreviewRemainingSell => 'Sell remaining after this payment';

  @override
  String get paymentConfirmAction => 'Confirm payment';

  @override
  String get paymentReferenceLabel => 'Note (optional)';

  @override
  String get paymentReferenceHint => 'Receipt or UPI id';

  @override
  String get paymentReferenceRequired => 'Note must be at most 20 characters';

  @override
  String timelinePaymentRef(String ref) {
    return 'Ref $ref';
  }

  @override
  String get paymentPayAction => 'Pay';

  @override
  String get paymentAddAdvanceAction => 'Add advance';

  @override
  String get unpaidSellBadge => 'Unpaid';

  @override
  String get timelineSubtitleAllLinesReturned => 'All lines returned by staff.';

  @override
  String get timelineSubtitleAllLinesReturnedLate =>
      'All lines returned. Late fee applied.';

  @override
  String timelineSubtitlePartialReturnLines(int returned, int total) {
    return 'Returned $returned of $total lines.';
  }

  @override
  String timelineSubtitlePartialReturnQty(
    String summary,
    int returned,
    int total,
  ) {
    return 'Returned $summary ($returned of $total lines).';
  }

  @override
  String timelineSubtitleUnitsLostQty(String summary, int count) {
    return 'Marked lost: $summary ($count units).';
  }

  @override
  String get timelineSubtitleAllJobsComplete =>
      'All job lines marked complete.';

  @override
  String timelineSubtitleJobsCompletedCount(int count) {
    return 'Completed $count job line(s).';
  }

  @override
  String timelineSubtitleCancelSettlement(String kept, String returned) {
    return 'Kept $kept; returned $returned.';
  }

  @override
  String timelineSubtitleNoteBody(String kind, String body) {
    return '$kind: $body';
  }

  @override
  String get timelineSubtitleAutoReminder => 'Auto reminder generated.';

  @override
  String get timelineSubtitleCheckedOutByStaff =>
      '1 item checked out by staff.';

  @override
  String get timelineSubtitleClosedAtCounter => 'Closed at counter.';

  @override
  String get timelineSubtitleManualWalkIn => 'Manual walk-in checkout.';

  @override
  String timelineSubtitleStatusChanged(String from, String to) {
    return '$from → $to';
  }

  @override
  String timelineSubtitleDueExtended(String from, String to) {
    return 'Due moved $from → $to.';
  }

  @override
  String timelineSubtitleDueExtendedSet(String to) {
    return 'Due set to $to.';
  }

  @override
  String get timelineSubtitleDueExtendedGeneric => 'Due date extended.';

  @override
  String timelineSubtitleAutoVacated(String summary, int count) {
    return 'Auto-vacated $summary ($count units).';
  }

  @override
  String get timelineSubtitleAutoVacatedGeneric =>
      'Overdue open units auto-vacated.';

  @override
  String timelineSubtitleDiscountBit(String amount) {
    return 'Discount $amount.';
  }

  @override
  String timelineSubtitleNoteBit(String note) {
    return 'Note: $note';
  }

  @override
  String reportHeader(String appName) {
    return '$appName report';
  }

  @override
  String reportActiveCount(int count) {
    return 'Active: $count';
  }

  @override
  String reportOpenedCount(int count) {
    return 'Opened: $count';
  }

  @override
  String reportReturnedCount(int count) {
    return 'Returned: $count';
  }

  @override
  String reportOverdueCount(int count) {
    return 'Overdue: $count';
  }

  @override
  String reportChargesOpened(String amount) {
    return 'Charges (opened in range): $amount';
  }

  @override
  String reportChargesReturned(String amount) {
    return 'Charges (returned in range): $amount';
  }

  @override
  String reportDepositAppliedRange(String amount) {
    return 'Deposit applied (returned in range): $amount';
  }

  @override
  String reportBalanceDueReturned(String amount) {
    return 'Balance due after deposit (returned): $amount';
  }

  @override
  String get reportNoRentalsInRange => '(no rentals in range)';

  @override
  String get reportNoResources => '(no resources)';

  @override
  String reportCustomerWithDeposit(String header, String amount) {
    return '$header | deposit $amount';
  }

  @override
  String get reportStatusReturnedBit => '[returned]';

  @override
  String get reportStatusSoldBit => '[sold]';

  @override
  String get reportStatusCompletedBit => '[completed]';

  @override
  String reportLinesPartialBit(int open, int returned) {
    return ' | lines $open open/$returned returned';
  }

  @override
  String reportDepositDueBit(String deposit, String due) {
    return ' | deposit $deposit | due $due';
  }

  @override
  String get reportOpenEnded => 'open-ended';

  @override
  String reportDueDateBit(String date) {
    return 'due $date';
  }

  @override
  String reportCustomerRentalLine(
    String prefix,
    String rentalId,
    String items,
    String dueBit,
    String status,
    String amount,
    String partialBit,
    String depositBit,
  ) {
    return '  • $prefix$rentalId: $items | $dueBit | $status | $amount$partialBit$depositBit';
  }

  @override
  String reportInventoryItemLine(
    String name,
    int rented,
    int out,
    int available,
    int total,
    String billing,
    String rate,
  ) {
    return '• $name: rented $rented× | out $out | avail $available/$total | $billing $rate';
  }

  @override
  String reportTruncatedSuffix(String appName) {
    return '\n…(truncated — open $appName for full)';
  }

  @override
  String get loansTitle => 'Loans';

  @override
  String get loanCreateTitle => 'New loan';

  @override
  String get loanCreateAction => 'New loan';

  @override
  String get loanDetailTitle => 'Loan calculator';

  @override
  String get loanNotFound => 'Loan not found';

  @override
  String get loanStatusPending => 'Pending';

  @override
  String get loanStatusClosed => 'Closed';

  @override
  String get loanStatusCancelled => 'Cancelled';

  @override
  String get loansPendingEmpty => 'No pending loans.';

  @override
  String get loansClosedEmpty => 'No closed loans yet.';

  @override
  String get loanDirectionLabel => 'Direction';

  @override
  String get loanDirectionGiven => 'Given (lent out)';

  @override
  String get loanDirectionTaken => 'Taken (borrowed)';

  @override
  String get loanCustomerLabel => 'Customer';

  @override
  String get loanPrincipalLabel => 'Principal';

  @override
  String get loanOriginalPrincipalLabel => 'Original principal';

  @override
  String get loanTotalPrincipalLabel => 'Total principal';

  @override
  String get loanPendingPrincipalLabel => 'Pending principal';

  @override
  String get loanPrincipalRequired => 'Enter a principal amount';

  @override
  String get loanMoneyGivenOnLabel => 'Money given on';

  @override
  String get loanDueOptionalLabel => 'Due / end (optional)';

  @override
  String get loanDueNone => 'No due date';

  @override
  String get loanCalculationFrequencyLabel => 'Interest calculation';

  @override
  String get loanRateDaily => 'Daily';

  @override
  String get loanInterestAccrualLabel => 'Interest accrual';

  @override
  String get loanInterestAccrualCalendar => 'Calendar period';

  @override
  String get loanCapitalizationPolicyLabel => 'Capitalization';

  @override
  String get loanCapPolicyNever => 'Never';

  @override
  String get loanCapPolicyOnPayment => 'On payment';

  @override
  String get loanCapPolicyOnScheduledCycle => 'On schedule';

  @override
  String get loanCapPolicyOnBalanceDirectionChange => 'On direction change';

  @override
  String get loanCapPolicyOnLoanClosure => 'On closure';

  @override
  String get loanCapPolicyManual => 'Manual';

  @override
  String get loanCapitalizationCycleLabel => 'Capitalization cycle';

  @override
  String get loanCapCycleMonthly => 'Monthly';

  @override
  String get loanCapCycleQuarterly => 'Quarterly';

  @override
  String get loanCapCycleHalfYearly => 'Half-yearly';

  @override
  String get loanCapCycleYearly => 'Yearly';

  @override
  String get loanCapitalizeInterestAction => 'Capitalize interest';

  @override
  String get loanCapitalizeInterestSnack =>
      'Interest capitalized into principal';

  @override
  String get loanCapitalizeNothingSnack => 'No unpaid interest to capitalize';

  @override
  String get loanUnpaidInterestLabel => 'Unpaid interest';

  @override
  String get loanPendingInterestLabel => 'Pending interest';

  @override
  String get loanPrepaymentAllocationLabel => 'Repayment applies to';

  @override
  String get loanPrepaymentInterestFirst => 'Interest first';

  @override
  String get loanPrepaymentPrincipalOnly => 'Principal only';

  @override
  String get loanPrepaymentAllocationHint =>
      'Interest first clears unpaid interest, then principal. Principal only reduces principal; unpaid interest stays until paid separately.';

  @override
  String get loanRatePercentLabel => 'Rate';

  @override
  String get loanRatePeriodLabel => 'Period';

  @override
  String get loanRateMonthly => 'Monthly';

  @override
  String get loanRateQuarterly => 'Quarterly';

  @override
  String get loanRateHalfYearly => 'Half-yearly';

  @override
  String get loanRateYearly => 'Yearly';

  @override
  String get loanCapPolicyHintNever =>
      'Principal stays fixed; unpaid interest grows separately. Outstanding = principal + unpaid.';

  @override
  String get loanCapPolicyHintOnPayment =>
      'Unpaid interest is added to principal immediately before each repayment.';

  @override
  String get loanCapPolicyHintOnScheduledCycle =>
      'Unpaid interest is added to principal on each capitalization cycle anniversary.';

  @override
  String get loanCapPolicyHintOnBalanceDirectionChange =>
      'Unpaid interest is added to principal before a cash move that would flip outstanding from due to credit (or reverse).';

  @override
  String get loanCapPolicyHintOnLoanClosure =>
      'Unpaid interest is added to principal when the loan is closed.';

  @override
  String get loanCapPolicyHintManual =>
      'Unpaid interest is added to principal only when you tap Capitalize interest.';

  @override
  String get loanRateInvalid => 'Enter a valid rate';

  @override
  String get loanNoteOptionalLabel => 'Note (optional)';

  @override
  String get loanPaymentReferenceLabel => 'Note (optional)';

  @override
  String get loanSaving => 'Saving…';

  @override
  String get loanPendingNowLabel => 'Pending now';

  @override
  String get loanOverpaidNowLabel => 'Overpaid now';

  @override
  String get loanInterestToDateLabel => 'Interest to date';

  @override
  String get loanTotalInterestLabel => 'Total interest';

  @override
  String get loanReverseInterestToDateLabel => 'Reverse interest to date';

  @override
  String get loanReversePendingInterestLabel => 'Reverse pending interest';

  @override
  String get loanPaidLabel => 'Paid';

  @override
  String get loanAdjustmentsLabel => 'Adjustments';

  @override
  String get loanTimelineHeading => 'Timeline';

  @override
  String get loanLedgerInterest => 'Interest';

  @override
  String get loanLedgerReverseInterest => 'Reverse interest';

  @override
  String get loanLedgerPayment => 'Payment';

  @override
  String get loanLedgerPrincipal => 'Principal';

  @override
  String get loanLedgerAdjustment => 'Adjustment';

  @override
  String get loanLedgerCapitalized => 'Capitalized';

  @override
  String loanLedgerBalanceLabel(String amount) {
    return 'Bal $amount';
  }

  @override
  String get loanLedgerHeaderDate => 'Date';

  @override
  String get loanLedgerHeaderParticulars => 'Particulars';

  @override
  String get loanLedgerHeaderAmount => 'Amount';

  @override
  String get loanLedgerHeaderBal => 'Bal';

  @override
  String loanLedgerMetaOnPrincipal(
    String principal,
    String from,
    String to,
    int days,
  ) {
    return 'on $principal · $from–$to · $days days';
  }

  @override
  String loanLedgerMetaToInterestPrincipal(String interest, String principal) {
    return 'to interest $interest · to principal $principal';
  }

  @override
  String get loanShareTimelineTooltip => 'Share timeline';

  @override
  String get loanShareTimelineSuccess => 'Timeline image downloaded';

  @override
  String get loanShareTimelineFailed => 'Could not create timeline image';

  @override
  String get loanAddPayment => 'Add payment';

  @override
  String get loanAddPrincipal => 'Add to principal';

  @override
  String get loanAddAdjustment => 'Add adjustment';

  @override
  String get loanEntryDateLabel => 'Date';

  @override
  String get loanFlowRepayment => 'Repayment';

  @override
  String get loanFlowAddPrincipal => 'Add to principal';

  @override
  String get loanFlowRepaymentGiven => 'Received from party';

  @override
  String get loanFlowRepaymentTaken => 'Paid back';

  @override
  String get loanFlowDisbursementGiven => 'Gave more';

  @override
  String get loanFlowDisbursementTaken => 'Borrowed more';

  @override
  String get loanPaymentAmountLabel => 'Amount';

  @override
  String get loanAdjustmentAmountLabel => 'Adjustment amount';

  @override
  String get loanAdjustmentHint =>
      'Positive forgives remaining; negative increases principal';

  @override
  String get loanSaveEntry => 'Save';

  @override
  String get loanEditPayment => 'Edit payment';

  @override
  String get loanEditDisbursement => 'Edit principal';

  @override
  String get loanEditEntryTooltip => 'Edit entry';

  @override
  String get loanEntryUpdated => 'Entry updated';

  @override
  String get loanDeleteEntry => 'Delete entry';

  @override
  String get loanDeleteEntryConfirm =>
      'Remove this entry from the loan timeline?';

  @override
  String get loanEntryDeleted => 'Entry removed';

  @override
  String get loanCancel => 'Cancel';

  @override
  String get loanKeepPending => 'Keep pending';

  @override
  String get loanKeepPendingHint => 'Loan stays open until you mark it closed.';

  @override
  String get loanMarkClosed => 'Mark closed';

  @override
  String get loanReopen => 'Reopen loan';

  @override
  String get loanClosedSnack => 'Loan marked closed';

  @override
  String get loanCloseWithPendingTitle => 'Close with balance pending?';

  @override
  String loanCloseWithPendingBody(String amount) {
    return 'Still pending $amount. Close anyway, or add an adjustment first?';
  }

  @override
  String get loanEditSetupTooltip => 'Edit loan';

  @override
  String get loanEditSetupTitle => 'Edit loan';

  @override
  String loanSetupSummary(
    String start,
    String due,
    String rate,
    String period,
    String policy,
  ) {
    return 'Start $start · Due $due · $rate $period · $policy';
  }

  @override
  String loanPrepaymentSetupLabel(String mode) {
    return 'Repayments: $mode';
  }

  @override
  String loanTimelineInterestCapitalized(String date, String amount) {
    return '$date — Interest capitalized $amount → principal';
  }

  @override
  String loanTimelineInterestSegment(
    String principal,
    String from,
    String to,
    int days,
    String amount,
  ) {
    return 'Interest on $principal ($from–$to · $days days) → $amount';
  }

  @override
  String loanTimelineReverseInterestSegment(
    String principal,
    String from,
    String to,
    int days,
    String amount,
  ) {
    return 'Reverse interest on credit $principal ($from–$to · $days days) → $amount';
  }

  @override
  String loanTimelinePendingOverpaid(String date, String amount) {
    return '$date — Overpaid $amount';
  }

  @override
  String loanTimelinePayment(String date, String amount, String principal) {
    return '$date — Repayment $amount → principal $principal';
  }

  @override
  String loanTimelinePaymentSplit(
    String date,
    String amount,
    String interest,
    String principal,
  ) {
    return '$date — Repayment $amount → interest $interest, principal $principal';
  }

  @override
  String loanTimelineDisbursement(String date, String amount) {
    return '$date — Added principal $amount';
  }

  @override
  String loanTimelineAdjustment(String date, String amount) {
    return '$date — Adjustment $amount';
  }

  @override
  String loanTimelinePending(String date, String amount) {
    return '$date — Pending $amount';
  }

  @override
  String get modulePendingLoans => 'Pending loans';

  @override
  String get modulePendingLoansSubtitle => 'Open cash loans still outstanding';

  @override
  String get pendingLoansTitle => 'Pending loans';

  @override
  String get pendingLoansEmptySubtitle => 'No pending loans right now.';

  @override
  String get moduleDueLoans => 'Due loans';

  @override
  String get moduleDueLoansSubtitle =>
      'Pending loans at or past their due date';

  @override
  String get dueLoansTitle => 'Due loans';

  @override
  String get dueLoansEmptySubtitle => 'No due loans right now.';

  @override
  String get customerLoansViewAll => 'View all loans';

  @override
  String reportPendingLoansCount(int count) {
    return 'Pending loans: $count';
  }

  @override
  String get reportNoOutstandingLoans => 'No outstanding loans.';

  @override
  String reportOutstandingLoansTotal(String amount, int count) {
    return 'Total $amount across $count loan(s)';
  }

  @override
  String get amountExceedsMaxCrores => 'Maximum is 1 lakh crore';
}
