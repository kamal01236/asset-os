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
