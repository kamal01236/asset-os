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
}
