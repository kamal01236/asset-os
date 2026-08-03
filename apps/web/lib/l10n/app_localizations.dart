import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRentals.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get navRentals;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionNewRental.
  ///
  /// In en, this message translates to:
  /// **'New Rental'**
  String get actionNewRental;

  /// No description provided for @issueItemAction.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueItemAction;

  /// No description provided for @issueToCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueToCustomerAction;

  /// No description provided for @searchInventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or category'**
  String get searchInventoryHint;

  /// No description provided for @actionReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get actionReturn;

  /// No description provided for @actionReturnItem.
  ///
  /// In en, this message translates to:
  /// **'Return Item'**
  String get actionReturnItem;

  /// No description provided for @actionAddInventory.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory'**
  String get actionAddInventory;

  /// No description provided for @actionScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get actionScan;

  /// No description provided for @actionActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionActions;

  /// No description provided for @searchAnything.
  ///
  /// In en, this message translates to:
  /// **'Search Anything'**
  String get searchAnything;

  /// No description provided for @todayAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Today at a glance'**
  String get todayAtAGlance;

  /// No description provided for @kpiActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get kpiActive;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusRented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get statusRented;

  /// No description provided for @statusDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get statusDueToday;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @aiSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions (beta)'**
  String get aiSuggestionsTitle;

  /// No description provided for @aiSuggestionsBody.
  ///
  /// In en, this message translates to:
  /// **'• Follow up on 1 overdue rental\n• Move Bosch Drill Kit to premium pricing\n• Call Priya Patel for extension confirmation'**
  String get aiSuggestionsBody;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Working offline — changes will sync later.'**
  String get offlineBanner;

  /// No description provided for @noRentalsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No rentals yet'**
  String get noRentalsYetTitle;

  /// No description provided for @noRentalsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new rental to create your first transaction.'**
  String get noRentalsYetSubtitle;

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown customer'**
  String get unknownCustomer;

  /// No description provided for @rentalDueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{customerName} • Due {date}'**
  String rentalDueSubtitle(String customerName, String date);

  /// No description provided for @inventoryAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{category} • {available}/{total} available'**
  String inventoryAvailableSubtitle(String category, int available, int total);

  /// No description provided for @customerTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get customerTrusted;

  /// No description provided for @customerStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get customerStandard;

  /// No description provided for @customerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{phone} • {tier}'**
  String customerSubtitle(String phone, String tier);

  /// No description provided for @offlineSimulationTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline simulation'**
  String get offlineSimulationTitle;

  /// No description provided for @offlineSimulationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Demo only: verify non-blocking offline UX (not product positioning).'**
  String get offlineSimulationSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @voiceSearchStubTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Search (stub)'**
  String get voiceSearchStubTitle;

  /// No description provided for @voiceSearchStubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Placeholder for intent-based search commands.'**
  String get voiceSearchStubSubtitle;

  /// No description provided for @businessTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Templates'**
  String get businessTemplatesTitle;

  /// No description provided for @businessTemplatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import starter inventory by industry (merge).'**
  String get businessTemplatesSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String phoneLabel(String phone);

  /// No description provided for @itemsHeading.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsHeading;

  /// No description provided for @timelineHeading.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineHeading;

  /// No description provided for @extendAction.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get extendAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @extendPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Extend is a placeholder action.'**
  String get extendPlaceholder;

  /// No description provided for @sharePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Share is a placeholder action.'**
  String get sharePlaceholder;

  /// No description provided for @editInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit inventory'**
  String get editInventoryTitle;

  /// No description provided for @inventoryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory detail'**
  String get inventoryDetailTitle;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemNameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @totalUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total units'**
  String get totalUnitsLabel;

  /// No description provided for @totalUnitsHelper.
  ///
  /// In en, this message translates to:
  /// **'Available adjusts with total; cannot exceed total.'**
  String get totalUnitsHelper;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Warranty / serial / condition'**
  String get notesHint;

  /// No description provided for @qrCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCodeLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @nameCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and category are required.'**
  String get nameCategoryRequired;

  /// No description provided for @inventoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Inventory updated.'**
  String get inventoryUpdated;

  /// No description provided for @customerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer profile'**
  String get customerProfileTitle;

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// No description provided for @whatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppAction;

  /// No description provided for @whatsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Placeholder integration hook'**
  String get whatsAppSubtitle;

  /// No description provided for @callPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Call placeholder action.'**
  String get callPlaceholder;

  /// No description provided for @whatsAppPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp placeholder action.'**
  String get whatsAppPlaceholder;

  /// No description provided for @recentRentals.
  ///
  /// In en, this message translates to:
  /// **'Recent rentals'**
  String get recentRentals;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDate(String date);

  /// No description provided for @returnedDate.
  ///
  /// In en, this message translates to:
  /// **'Returned {date}'**
  String returnedDate(String date);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Find customer, rental, or inventory'**
  String get searchHint;

  /// No description provided for @searchSectionCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get searchSectionCustomers;

  /// No description provided for @searchSectionCurrentRentals.
  ///
  /// In en, this message translates to:
  /// **'Current rentals'**
  String get searchSectionCurrentRentals;

  /// No description provided for @searchSectionPreviousRentals.
  ///
  /// In en, this message translates to:
  /// **'Previous rentals'**
  String get searchSectionPreviousRentals;

  /// No description provided for @searchSectionInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get searchSectionInventory;

  /// No description provided for @noMatchingSection.
  ///
  /// In en, this message translates to:
  /// **'No matching {section}'**
  String noMatchingSection(String section);

  /// No description provided for @inventoryUnitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{category} • {available}/{total}'**
  String inventoryUnitsSubtitle(String category, int available, int total);

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit customer phone'**
  String get phoneNumberHint;

  /// No description provided for @existingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Existing customer'**
  String get existingCustomer;

  /// No description provided for @existingCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{phone} • Existing customer'**
  String existingCustomerSubtitle(String phone);

  /// No description provided for @customerNameNewLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer name (new)'**
  String get customerNameNewLabel;

  /// No description provided for @customerNameNewHint.
  ///
  /// In en, this message translates to:
  /// **'Only needed if new customer'**
  String get customerNameNewHint;

  /// No description provided for @selfKnownQuickPick.
  ///
  /// In en, this message translates to:
  /// **'SELF Known'**
  String get selfKnownQuickPick;

  /// No description provided for @rentalNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname for this rental'**
  String get rentalNicknameLabel;

  /// No description provided for @rentalNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Who is taking the items?'**
  String get rentalNicknameHint;

  /// No description provided for @rentalNicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname for SELF Known rentals.'**
  String get rentalNicknameRequired;

  /// No description provided for @reviewNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname: {nickname} · {customerName}'**
  String reviewNickname(String nickname, String customerName);

  /// No description provided for @rentalNicknameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{customerName} · {phone}'**
  String rentalNicknameSubtitle(String customerName, String phone);

  /// No description provided for @rentalNicknameDueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{nickname} • Due {date}'**
  String rentalNicknameDueSubtitle(String nickname, String date);

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select items'**
  String get selectItems;

  /// No description provided for @itemAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{category} • {available} available'**
  String itemAvailableCount(String category, int available);

  /// No description provided for @labelInstancesHeading.
  ///
  /// In en, this message translates to:
  /// **'Name each item'**
  String get labelInstancesHeading;

  /// No description provided for @labelInstancesHint.
  ///
  /// In en, this message translates to:
  /// **'For novels/tools: enter this copy’s name and a short code.'**
  String get labelInstancesHint;

  /// No description provided for @instanceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Instance name'**
  String get instanceNameLabel;

  /// No description provided for @instanceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Harry Potter'**
  String get instanceNameHint;

  /// No description provided for @shortCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Short code'**
  String get shortCodeLabel;

  /// No description provided for @shortCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. NOV-042'**
  String get shortCodeHint;

  /// No description provided for @instanceLabelsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an instance name and short code for each item.'**
  String get instanceLabelsRequired;

  /// No description provided for @duplicateShortCode.
  ///
  /// In en, this message translates to:
  /// **'Short code {code} is already in use on an active rental.'**
  String duplicateShortCode(String code);

  /// No description provided for @inventoryInstancesNote.
  ///
  /// In en, this message translates to:
  /// **'Individual copies are named with a short code when you issue a rental.'**
  String get inventoryInstancesNote;

  /// No description provided for @reviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewHeading;

  /// No description provided for @reviewPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String reviewPhone(String phone);

  /// No description provided for @reviewName.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String reviewName(String name);

  /// No description provided for @reviewItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get reviewItemsLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @confirmRental.
  ///
  /// In en, this message translates to:
  /// **'Confirm rental'**
  String get confirmRental;

  /// No description provided for @noActiveRentalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No active rentals'**
  String get noActiveRentalsTitle;

  /// No description provided for @noActiveRentalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is already returned.'**
  String get noActiveRentalsSubtitle;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @rentalReturned.
  ///
  /// In en, this message translates to:
  /// **'{id} returned'**
  String rentalReturned(String id);

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAdd;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsLabel;

  /// No description provided for @advancedFields.
  ///
  /// In en, this message translates to:
  /// **'Advanced fields'**
  String get advancedFields;

  /// No description provided for @advancedFieldsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional in MVP'**
  String get advancedFieldsSubtitle;

  /// No description provided for @saveItem.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get saveItem;

  /// No description provided for @scanIntro.
  ///
  /// In en, this message translates to:
  /// **'Use camera integration in the next phase. For now, paste/enter QR text.'**
  String get scanIntro;

  /// No description provided for @qrContentLabel.
  ///
  /// In en, this message translates to:
  /// **'QR content'**
  String get qrContentLabel;

  /// No description provided for @qrContentHint.
  ///
  /// In en, this message translates to:
  /// **'customer:1001'**
  String get qrContentHint;

  /// No description provided for @noEntityMatched.
  ///
  /// In en, this message translates to:
  /// **'No entity matched this code.'**
  String get noEntityMatched;

  /// No description provided for @openLinkedRecord.
  ///
  /// In en, this message translates to:
  /// **'Open linked record'**
  String get openLinkedRecord;

  /// No description provided for @voiceSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Search'**
  String get voiceSearchTitle;

  /// No description provided for @voiceSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Stub only: voice commands map to universal search intents in phase 5+.'**
  String get voiceSearchBody;

  /// No description provided for @templatesIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick an industry, then choose which starter items to add. Existing items with the same name are kept (merge).'**
  String get templatesIntro;

  /// No description provided for @starterItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} starter items'**
  String starterItemsCount(int count);

  /// No description provided for @templateCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{description}\n{count} starter items'**
  String templateCardSubtitle(String description, int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @unitSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} unit'**
  String unitSingular(int count);

  /// No description provided for @unitPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String unitPlural(int count);

  /// No description provided for @templateItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{category} • {units}'**
  String templateItemSubtitle(String category, String units);

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get adding;

  /// No description provided for @addSelectedToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add selected to inventory'**
  String get addSelectedToInventory;

  /// No description provided for @templateImportResult.
  ///
  /// In en, this message translates to:
  /// **'Added {added} items ({skipped} already present)'**
  String templateImportResult(int added, int skipped);

  /// No description provided for @myWhatsAppTitle.
  ///
  /// In en, this message translates to:
  /// **'My WhatsApp number'**
  String get myWhatsAppTitle;

  /// No description provided for @myWhatsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to share reports to yourself'**
  String get myWhatsAppSubtitle;

  /// No description provided for @myWhatsAppHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile (default +91)'**
  String get myWhatsAppHint;

  /// No description provided for @myWhatsAppSaved.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number saved.'**
  String get myWhatsAppSaved;

  /// No description provided for @myWhatsAppInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit (or full) mobile number.'**
  String get myWhatsAppInvalid;

  /// No description provided for @shareReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share reports'**
  String get shareReportsTitle;

  /// No description provided for @shareReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate and send a text report to your WhatsApp'**
  String get shareReportsSubtitle;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get reportTypeLabel;

  /// No description provided for @reportTypeSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportTypeSummary;

  /// No description provided for @reportTypeCustomerWise.
  ///
  /// In en, this message translates to:
  /// **'Customer-wise'**
  String get reportTypeCustomerWise;

  /// No description provided for @reportTypeInventoryWise.
  ///
  /// In en, this message translates to:
  /// **'Inventory-wise'**
  String get reportTypeInventoryWise;

  /// No description provided for @reportPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriodLabel;

  /// No description provided for @reportPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reportPeriodDaily;

  /// No description provided for @reportPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportPeriodWeekly;

  /// No description provided for @reportPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportPeriodMonthly;

  /// No description provided for @reportPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportPeriodCustom;

  /// No description provided for @reportStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get reportStartDate;

  /// No description provided for @reportEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get reportEndDate;

  /// No description provided for @reportPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get reportPreviewLabel;

  /// No description provided for @shareToMyWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share to my WhatsApp'**
  String get shareToMyWhatsApp;

  /// No description provided for @copyReportText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyReportText;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied to clipboard.'**
  String get reportCopied;

  /// No description provided for @reportWhatsAppOpened.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp opened — tap Send to deliver.'**
  String get reportWhatsAppOpened;

  /// No description provided for @reportWhatsAppFallback.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Report copied instead.'**
  String get reportWhatsAppFallback;

  /// No description provided for @reportMissingPhone.
  ///
  /// In en, this message translates to:
  /// **'Set My WhatsApp number in More first.'**
  String get reportMissingPhone;

  /// No description provided for @setWhatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'Set number'**
  String get setWhatsAppAction;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @billingModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing mode'**
  String get billingModeLabel;

  /// No description provided for @billingModeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get billingModeDaily;

  /// No description provided for @billingModeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get billingModeWeekly;

  /// No description provided for @billingModeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingModeMonthly;

  /// No description provided for @billingModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get billingModeFixed;

  /// No description provided for @billingModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get billingModeCustom;

  /// No description provided for @rateAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate (₹)'**
  String get rateAmountLabel;

  /// No description provided for @rateAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get rateAmountHint;

  /// No description provided for @lateFeePerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Late fee per day (₹)'**
  String get lateFeePerDayLabel;

  /// No description provided for @lateFeePerDayHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. 5'**
  String get lateFeePerDayHint;

  /// No description provided for @pricingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rental pricing'**
  String get pricingSectionTitle;

  /// No description provided for @durationHeading.
  ///
  /// In en, this message translates to:
  /// **'Rental duration'**
  String get durationHeading;

  /// No description provided for @durationHint.
  ///
  /// In en, this message translates to:
  /// **'Based on the first selected item’s billing mode.'**
  String get durationHint;

  /// No description provided for @durationUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationUnitsLabel;

  /// No description provided for @durationUnitsDaily.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get durationUnitsDaily;

  /// No description provided for @durationUnitsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Number of weeks'**
  String get durationUnitsWeekly;

  /// No description provided for @durationUnitsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Number of months'**
  String get durationUnitsMonthly;

  /// No description provided for @durationUnitsFixed.
  ///
  /// In en, this message translates to:
  /// **'Due in (days)'**
  String get durationUnitsFixed;

  /// No description provided for @customEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Return by'**
  String get customEndDateLabel;

  /// No description provided for @chargePreviewDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String chargePreviewDue(String date);

  /// No description provided for @chargeLineAmount.
  ///
  /// In en, this message translates to:
  /// **'{item} — {amount}'**
  String chargeLineAmount(String item, String amount);

  /// No description provided for @chargeBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base: {amount}'**
  String chargeBaseLabel(String amount);

  /// No description provided for @chargeLateLabel.
  ///
  /// In en, this message translates to:
  /// **'Late fee: {amount}'**
  String chargeLateLabel(String amount);

  /// No description provided for @chargeTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String chargeTotalLabel(String amount);

  /// No description provided for @reviewChargesLabel.
  ///
  /// In en, this message translates to:
  /// **'Charges:'**
  String get reviewChargesLabel;

  /// No description provided for @reviewDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String reviewDueLabel(String date);

  /// No description provided for @rentalAmountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Due {date} · {amount}'**
  String rentalAmountSubtitle(String date, String amount);

  /// No description provided for @inventoryRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{mode} · {rate}'**
  String inventoryRateSubtitle(String mode, String rate);

  /// No description provided for @chargesHeading.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get chargesHeading;

  /// No description provided for @durationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration (at least 1).'**
  String get durationRequired;

  /// No description provided for @customEndRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a return-by date on or after today.'**
  String get customEndRequired;

  /// No description provided for @depositBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit balance'**
  String get depositBalanceLabel;

  /// No description provided for @depositBalanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit: {amount}'**
  String depositBalanceAmount(String amount);

  /// No description provided for @depositAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add deposit'**
  String get depositAddAction;

  /// No description provided for @depositRefundAction.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get depositRefundAction;

  /// No description provided for @depositAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get depositAmountLabel;

  /// No description provided for @depositAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get depositAmountHint;

  /// No description provided for @depositNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get depositNoteLabel;

  /// No description provided for @depositNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Reason or reference'**
  String get depositNoteHint;

  /// No description provided for @depositTopUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Add deposit'**
  String get depositTopUpTitle;

  /// No description provided for @depositRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund deposit'**
  String get depositRefundTitle;

  /// No description provided for @depositConfirmTopUp.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get depositConfirmTopUp;

  /// No description provided for @depositConfirmRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get depositConfirmRefund;

  /// No description provided for @depositInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get depositInvalidAmount;

  /// No description provided for @depositRefundExceeds.
  ///
  /// In en, this message translates to:
  /// **'Refund cannot exceed the current deposit balance.'**
  String get depositRefundExceeds;

  /// No description provided for @depositTopUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deposit updated to {amount}.'**
  String depositTopUpSuccess(String amount);

  /// No description provided for @depositRefundSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refunded. Deposit now {amount}.'**
  String depositRefundSuccess(String amount);

  /// No description provided for @depositLedgerHeading.
  ///
  /// In en, this message translates to:
  /// **'Deposit history'**
  String get depositLedgerHeading;

  /// No description provided for @depositLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deposit activity yet.'**
  String get depositLedgerEmpty;

  /// No description provided for @depositLedgerTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top-up {amount}'**
  String depositLedgerTopUp(String amount);

  /// No description provided for @depositLedgerApply.
  ///
  /// In en, this message translates to:
  /// **'Applied on return {amount}'**
  String depositLedgerApply(String amount);

  /// No description provided for @depositLedgerRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount}'**
  String depositLedgerRefund(String amount);

  /// No description provided for @depositLedgerAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust {amount}'**
  String depositLedgerAdjust(String amount);

  /// No description provided for @depositLedgerBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String depositLedgerBalanceAfter(String amount);

  /// No description provided for @depositAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit available: {amount}'**
  String depositAvailableLabel(String amount);

  /// No description provided for @depositWillApplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Will apply from deposit: {amount}'**
  String depositWillApplyLabel(String amount);

  /// No description provided for @depositRemainingDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining due: {amount}'**
  String depositRemainingDueLabel(String amount);

  /// No description provided for @depositLeftoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Leftover deposit: {amount}'**
  String depositLeftoverLabel(String amount);

  /// No description provided for @depositAppliedLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit applied: {amount}'**
  String depositAppliedLabel(String amount);

  /// No description provided for @depositNetDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Net due: {amount}'**
  String depositNetDueLabel(String amount);

  /// No description provided for @returnSettlementTitle.
  ///
  /// In en, this message translates to:
  /// **'Return settlement'**
  String get returnSettlementTitle;

  /// No description provided for @confirmReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm return'**
  String get confirmReturnAction;

  /// No description provided for @depositReturnSnackApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied {applied} from deposit; balance now {balance}.'**
  String depositReturnSnackApplied(String applied, String balance);

  /// No description provided for @depositReturnSnackDue.
  ///
  /// In en, this message translates to:
  /// **'Applied {applied} from deposit; remaining due {due}.'**
  String depositReturnSnackDue(String applied, String due);

  /// No description provided for @depositReturnSnackNoDeposit.
  ///
  /// In en, this message translates to:
  /// **'Returned. Total {total} due in cash.'**
  String depositReturnSnackNoDeposit(String total);

  /// No description provided for @customerSubtitleWithDeposit.
  ///
  /// In en, this message translates to:
  /// **'{phone} • {tier} • Deposit {amount}'**
  String customerSubtitleWithDeposit(String phone, String tier, String amount);

  /// No description provided for @existingCustomerWithDeposit.
  ///
  /// In en, this message translates to:
  /// **'{phone} • Existing • Deposit {amount}'**
  String existingCustomerWithDeposit(String phone, String amount);

  /// No description provided for @returnSelectedAction.
  ///
  /// In en, this message translates to:
  /// **'Return selected'**
  String get returnSelectedAction;

  /// No description provided for @returnAllAction.
  ///
  /// In en, this message translates to:
  /// **'Return all'**
  String get returnAllAction;

  /// No description provided for @replaceLineAction.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceLineAction;

  /// No description provided for @selectLinesToReturn.
  ///
  /// In en, this message translates to:
  /// **'Select lines to return'**
  String get selectLinesToReturn;

  /// No description provided for @openLinesHeading.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get openLinesHeading;

  /// No description provided for @returnedLinesHeading.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returnedLinesHeading;

  /// No description provided for @lineReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get lineReturnedLabel;

  /// No description provided for @lineOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get lineOpenLabel;

  /// No description provided for @partialReturnSnack.
  ///
  /// In en, this message translates to:
  /// **'Returned {count} item(s). Rental still active.'**
  String partialReturnSnack(int count);

  /// No description provided for @replaceFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace item'**
  String get replaceFlowTitle;

  /// No description provided for @replaceSettlementIntro.
  ///
  /// In en, this message translates to:
  /// **'Settle the old item, then issue a replacement.'**
  String get replaceSettlementIntro;

  /// No description provided for @replaceConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Replace & issue'**
  String get replaceConfirmAction;

  /// No description provided for @replaceSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Settled old line; opened {newId}. Deposit balance {balance}.'**
  String replaceSuccessSnack(String newId, String balance);

  /// No description provided for @noLinesSelected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one item to return.'**
  String get noLinesSelected;

  /// No description provided for @linesOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{open} of {total} still out'**
  String linesOpenCount(int open, int total);

  /// No description provided for @lineChargePreview.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}'**
  String lineChargePreview(String label, String amount);

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilter;

  /// No description provided for @showingFilter.
  ///
  /// In en, this message translates to:
  /// **'Showing: {label}'**
  String showingFilter(String label);

  /// No description provided for @needsAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttentionTitle;

  /// No description provided for @needsAttentionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention'**
  String get needsAttentionEmptyTitle;

  /// No description provided for @needsAttentionEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Due today and overdue rentals will show up here.'**
  String get needsAttentionEmptySubtitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivityTitle;

  /// No description provided for @recentActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent rentals or returns yet.'**
  String get recentActivityEmpty;

  /// No description provided for @homeFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get homeFilterEmptyTitle;

  /// No description provided for @homeFilterEmptyRentalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No rentals match {label} right now.'**
  String homeFilterEmptyRentalsSubtitle(String label);

  /// No description provided for @homeFilterEmptyInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory with remaining units right now.'**
  String get homeFilterEmptyInventorySubtitle;

  /// No description provided for @customizeHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Home'**
  String get customizeHomeTitle;

  /// No description provided for @customizeHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show or hide Home modules.'**
  String get customizeHomeSubtitle;

  /// No description provided for @customizeHomeIntro.
  ///
  /// In en, this message translates to:
  /// **'Search stays on. Toggle other modules to keep Home focused.'**
  String get customizeHomeIntro;

  /// No description provided for @moduleSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get moduleSearch;

  /// No description provided for @moduleSearchLocked.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get moduleSearchLocked;

  /// No description provided for @moduleKpis.
  ///
  /// In en, this message translates to:
  /// **'Status cards'**
  String get moduleKpis;

  /// No description provided for @moduleKpisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active, Due Today, Overdue, Available'**
  String get moduleKpisSubtitle;

  /// No description provided for @moduleFilterResults.
  ///
  /// In en, this message translates to:
  /// **'Filter results'**
  String get moduleFilterResults;

  /// No description provided for @moduleFilterResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List under status cards when a filter is selected'**
  String get moduleFilterResultsSubtitle;

  /// No description provided for @moduleNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get moduleNeedsAttention;

  /// No description provided for @moduleNeedsAttentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Due today and overdue rentals'**
  String get moduleNeedsAttentionSubtitle;

  /// No description provided for @moduleQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get moduleQuickActions;

  /// No description provided for @moduleQuickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New Rental, Return, Add Inventory'**
  String get moduleQuickActionsSubtitle;

  /// No description provided for @moduleRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get moduleRecentActivity;

  /// No description provided for @moduleRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest rentals and returns'**
  String get moduleRecentActivitySubtitle;

  /// No description provided for @moduleSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions'**
  String get moduleSuggestions;

  /// No description provided for @moduleSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional beta tips'**
  String get moduleSuggestionsSubtitle;

  /// No description provided for @applyHomeLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply Home layout?'**
  String get applyHomeLayoutTitle;

  /// No description provided for @applyHomeLayoutBody.
  ///
  /// In en, this message translates to:
  /// **'Use this template’s recommended Home modules.'**
  String get applyHomeLayoutBody;

  /// No description provided for @applyHomeLayoutCustomizedBody.
  ///
  /// In en, this message translates to:
  /// **'You customized Home earlier. Replace it with this template’s layout?'**
  String get applyHomeLayoutCustomizedBody;

  /// No description provided for @applyHomeLayoutSkip.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get applyHomeLayoutSkip;

  /// No description provided for @applyHomeLayoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Apply layout'**
  String get applyHomeLayoutConfirm;

  /// No description provided for @applyHomeLayoutDone.
  ///
  /// In en, this message translates to:
  /// **'Home layout updated.'**
  String get applyHomeLayoutDone;

  /// No description provided for @minMeaningfulTextError.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {min} characters.'**
  String minMeaningfulTextError(int min);

  /// No description provided for @searchTypeMinChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 characters'**
  String get searchTypeMinChars;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, or nickname'**
  String get searchCustomersHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoResults;

  /// No description provided for @dueDateOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date optional'**
  String get dueDateOptionalLabel;

  /// No description provided for @dueDateOptionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow issuing without a fixed return date (charge accrues until return).'**
  String get dueDateOptionalSubtitle;

  /// No description provided for @continueWithoutDueDate.
  ///
  /// In en, this message translates to:
  /// **'Continue without due date'**
  String get continueWithoutDueDate;

  /// No description provided for @openEndedDurationHint.
  ///
  /// In en, this message translates to:
  /// **'All selected items allow open-ended rentals. Enter a duration, or continue without a due date.'**
  String get openEndedDurationHint;

  /// No description provided for @openEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'Open-ended'**
  String get openEndedLabel;

  /// No description provided for @reviewOpenEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: Open-ended (accrues until return)'**
  String get reviewOpenEndedLabel;

  /// No description provided for @rentalAmountOpenEnded.
  ///
  /// In en, this message translates to:
  /// **'Open-ended · {amount}'**
  String rentalAmountOpenEnded(String amount);

  /// No description provided for @accruedAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Accrued so far'**
  String get accruedAmountHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
