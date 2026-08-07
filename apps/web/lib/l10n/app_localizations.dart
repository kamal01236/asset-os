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
  /// **'Transactions'**
  String get navRentals;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get navResources;

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
  /// **'New Order'**
  String get actionNewRental;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsFilterAll;

  /// No description provided for @transactionsFilterOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get transactionsFilterOrders;

  /// No description provided for @transactionsFilterLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get transactionsFilterLoans;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newTransaction;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get newOrder;

  /// No description provided for @newLoan.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get newLoan;

  /// No description provided for @transactionTypeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get transactionTypeOrder;

  /// No description provided for @transactionTypeLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get transactionTypeLoan;

  /// No description provided for @searchTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search orders or loans'**
  String get searchTransactionsHint;

  /// No description provided for @noTransactionsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYetTitle;

  /// No description provided for @noTransactionsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an order or loan to get started.'**
  String get noTransactionsYetSubtitle;

  /// No description provided for @customerTransactionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get customerTransactionsHeading;

  /// No description provided for @customerTransactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this customer.'**
  String get customerTransactionsEmpty;

  /// No description provided for @customerTransactionsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get customerTransactionsViewAll;

  /// No description provided for @transactionsMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders and cash loans'**
  String get transactionsMoreSubtitle;

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

  /// No description provided for @actionAddResource.
  ///
  /// In en, this message translates to:
  /// **'Add Resource'**
  String get actionAddResource;

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
  /// **'No orders yet'**
  String get noRentalsYetTitle;

  /// No description provided for @noRentalsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new order to create your first transaction.'**
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

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose dark or light appearance'**
  String get themeSubtitle;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

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
  /// **'Import starter resources by industry (merge types). Applying Home layout replaces enabled types.'**
  String get businessTemplatesSubtitle;

  /// No description provided for @onboardingStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepProgress(int current, int total);

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in More.'**
  String get onboardingLanguageSubtitle;

  /// No description provided for @onboardingModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to work?'**
  String get onboardingModeTitle;

  /// No description provided for @onboardingModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline is the default — everything stays on this device.'**
  String get onboardingModeSubtitle;

  /// No description provided for @onboardingModeOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get onboardingModeOfflineTitle;

  /// No description provided for @onboardingModeOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Works without internet. Data stays local-first on this device.'**
  String get onboardingModeOfflineSubtitle;

  /// No description provided for @onboardingModeOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onboardingModeOnlineTitle;

  /// No description provided for @onboardingModeOnlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp reports and future sync / OTP ownership proof.'**
  String get onboardingModeOnlineSubtitle;

  /// No description provided for @onboardingWhatsAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Your WhatsApp number'**
  String get onboardingWhatsAppTitle;

  /// No description provided for @onboardingWhatsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for online mode so we can verify ownership and share reports to you.'**
  String get onboardingWhatsAppSubtitle;

  /// No description provided for @onboardingWhatsAppOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get onboardingWhatsAppOtpLabel;

  /// No description provided for @onboardingWhatsAppOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Coming later'**
  String get onboardingWhatsAppOtpHint;

  /// No description provided for @onboardingWhatsAppOtpLater.
  ///
  /// In en, this message translates to:
  /// **'We\'ll verify this number by OTP later. Saving the number is enough for now.'**
  String get onboardingWhatsAppOtpLater;

  /// No description provided for @onboardingTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your business type'**
  String get onboardingTemplateTitle;

  /// No description provided for @onboardingTemplateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll add starter resources for your industry. You can add more later from More → Business Templates.'**
  String get onboardingTemplateSubtitle;

  /// No description provided for @onboardingTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use this template'**
  String get onboardingTemplateConfirm;

  /// No description provided for @onboardingTemplateCancel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingTemplateCancel;

  /// No description provided for @onboardingTemplateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Add all {count} starter items for {name} and set the recommended Home layout?'**
  String onboardingTemplateConfirmBody(int count, String name);

  /// No description provided for @onboardingTemplateBusy.
  ///
  /// In en, this message translates to:
  /// **'Setting up…'**
  String get onboardingTemplateBusy;

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

  /// No description provided for @editResourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit resource'**
  String get editResourceTitle;

  /// No description provided for @resourceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Resource detail'**
  String get resourceDetailTitle;

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

  /// No description provided for @categoryOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherLabel;

  /// No description provided for @categoryGeneralLabel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneralLabel;

  /// No description provided for @categoryCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter category'**
  String get categoryCustomLabel;

  /// No description provided for @categoryCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Custom category name'**
  String get categoryCustomHint;

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

  /// No description provided for @resourceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Resource updated.'**
  String get resourceUpdated;

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
  /// **'Recent orders'**
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
  /// **'Find customer, order, or resource'**
  String get searchHint;

  /// No description provided for @searchSectionCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get searchSectionCustomers;

  /// No description provided for @searchSectionCurrentRentals.
  ///
  /// In en, this message translates to:
  /// **'Current orders'**
  String get searchSectionCurrentRentals;

  /// No description provided for @searchSectionPreviousRentals.
  ///
  /// In en, this message translates to:
  /// **'Previous orders'**
  String get searchSectionPreviousRentals;

  /// No description provided for @searchSectionResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get searchSectionResources;

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
  /// **'Name'**
  String get customerNameNewLabel;

  /// No description provided for @customerNameNewHint.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerNameNewHint;

  /// No description provided for @noPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhoneNumberLabel;

  /// No description provided for @noPhoneOptionalNameHint.
  ///
  /// In en, this message translates to:
  /// **'Optional display name for this order'**
  String get noPhoneOptionalNameHint;

  /// No description provided for @customerTypeaheadEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching customers'**
  String get customerTypeaheadEmpty;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit phone number, or choose No phone number.'**
  String get phoneRequiredError;

  /// No description provided for @phoneAlreadyUsedError.
  ///
  /// In en, this message translates to:
  /// **'This phone is already used by another customer.'**
  String get phoneAlreadyUsedError;

  /// No description provided for @customerSuggestionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} · {phone}'**
  String customerSuggestionSubtitle(String name, String phone);

  /// No description provided for @rentalNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name for this order'**
  String get rentalNicknameLabel;

  /// No description provided for @rentalNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Optional name shown on this order'**
  String get rentalNicknameHint;

  /// No description provided for @reviewNickname.
  ///
  /// In en, this message translates to:
  /// **'Name: {nickname} · {customerName}'**
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
  /// **'Unit name'**
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
  /// **'Enter a unit name and short code for each item.'**
  String get instanceLabelsRequired;

  /// No description provided for @duplicateShortCode.
  ///
  /// In en, this message translates to:
  /// **'Short code {code} is already in use on an active order.'**
  String duplicateShortCode(String code);

  /// No description provided for @inventoryInstancesNote.
  ///
  /// In en, this message translates to:
  /// **'Individual copies are named with a short code when you generate an order.'**
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
  /// **'Generate Order'**
  String get confirmRental;

  /// No description provided for @noActiveRentalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No active orders'**
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

  /// No description provided for @extraFieldsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra fields'**
  String get extraFieldsSectionTitle;

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
  /// **'Pick an industry, then choose which starter items to add. Existing items with the same name are kept. Importing merges enabled resource types; applying the Home layout replaces them with the template’s set.'**
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

  /// No description provided for @addSelectedToResources.
  ///
  /// In en, this message translates to:
  /// **'Add selected to resources'**
  String get addSelectedToResources;

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

  /// No description provided for @reportTypeResourcesWise.
  ///
  /// In en, this message translates to:
  /// **'Resources-wise'**
  String get reportTypeResourcesWise;

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

  /// No description provided for @returnFinalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Final amount to collect'**
  String get returnFinalAmountLabel;

  /// No description provided for @returnFinalAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0 or less than computed total'**
  String get returnFinalAmountHint;

  /// No description provided for @returnDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount {amount}'**
  String returnDiscountLabel(String amount);

  /// No description provided for @returnNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get returnNoteLabel;

  /// No description provided for @returnNoteHint.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters when set'**
  String get returnNoteHint;

  /// No description provided for @deleteOrderAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get deleteOrderAction;

  /// No description provided for @deleteOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get deleteOrderTitle;

  /// No description provided for @confirmDeleteOrderAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get confirmDeleteOrderAction;

  /// No description provided for @deleteOrderKeptLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to keep'**
  String get deleteOrderKeptLabel;

  /// No description provided for @deleteOrderReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to return'**
  String get deleteOrderReturnedLabel;

  /// No description provided for @deleteOrderNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get deleteOrderNoteLabel;

  /// No description provided for @deleteOrderInvalidSettlement.
  ///
  /// In en, this message translates to:
  /// **'Kept + returned cannot exceed order deposit.'**
  String get deleteOrderInvalidSettlement;

  /// No description provided for @deleteOrderBlockedPartial.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel an order after items were returned.'**
  String get deleteOrderBlockedPartial;

  /// No description provided for @deleteOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel this order.'**
  String get deleteOrderFailed;

  /// No description provided for @deleteOrderSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled. Deposit balance {balance}.'**
  String deleteOrderSuccessSnack(String balance);

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
  /// **'Due today and overdue orders will show up here.'**
  String get needsAttentionEmptySubtitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivityTitle;

  /// No description provided for @recentActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent orders or returns yet.'**
  String get recentActivityEmpty;

  /// No description provided for @homeFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get homeFilterEmptyTitle;

  /// No description provided for @homeFilterEmptyRentalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No orders match {label} right now.'**
  String homeFilterEmptyRentalsSubtitle(String label);

  /// No description provided for @homeFilterEmptyResourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No resources with remaining units right now.'**
  String get homeFilterEmptyResourcesSubtitle;

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

  /// No description provided for @enabledResourceTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled resource types'**
  String get enabledResourceTypesTitle;

  /// No description provided for @enabledResourceTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which types appear under New Order → More options.'**
  String get enabledResourceTypesSubtitle;

  /// No description provided for @enabledResourceTypesIntro.
  ///
  /// In en, this message translates to:
  /// **'Toggle types for New Order fulfillment (Rent / Sell / Job). Importing template items merges types into this list. Applying a template’s Home layout replaces this list with the template’s set.'**
  String get enabledResourceTypesIntro;

  /// No description provided for @enabledResourceTypesKeepOne.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one type enabled.'**
  String get enabledResourceTypesKeepOne;

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
  /// **'Status chips'**
  String get moduleKpis;

  /// No description provided for @moduleKpisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compact chips; tap opens Orders or Resources filtered'**
  String get moduleKpisSubtitle;

  /// No description provided for @moduleFilterResults.
  ///
  /// In en, this message translates to:
  /// **'Filter results'**
  String get moduleFilterResults;

  /// No description provided for @moduleFilterResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional in-place list under chips when a Home filter is set'**
  String get moduleFilterResultsSubtitle;

  /// No description provided for @moduleNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get moduleNeedsAttention;

  /// No description provided for @moduleNeedsAttentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Due today and overdue orders'**
  String get moduleNeedsAttentionSubtitle;

  /// No description provided for @modulePendingJobs.
  ///
  /// In en, this message translates to:
  /// **'Pending jobs'**
  String get modulePendingJobs;

  /// No description provided for @modulePendingJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open orders with unfinished job lines'**
  String get modulePendingJobsSubtitle;

  /// No description provided for @pendingJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending jobs'**
  String get pendingJobsTitle;

  /// No description provided for @pendingJobsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No open job lines right now.'**
  String get pendingJobsEmptySubtitle;

  /// No description provided for @moduleQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get moduleQuickActions;

  /// No description provided for @moduleQuickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New Order, Return, Add Resource'**
  String get moduleQuickActionsSubtitle;

  /// No description provided for @moduleRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get moduleRecentActivity;

  /// No description provided for @moduleRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest orders and returns'**
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
  /// **'Replace Home modules and enabled resource types with this template’s recommended set. Importing items alone only merges types.'**
  String get applyHomeLayoutBody;

  /// No description provided for @applyHomeLayoutCustomizedBody.
  ///
  /// In en, this message translates to:
  /// **'You customized Home earlier. Replace Home modules and enabled resource types with this template’s set?'**
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
  /// **'Home layout and resource types updated.'**
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
  /// **'Search by name or phone'**
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

  /// No description provided for @balanceAdvanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get balanceAdvanceLabel;

  /// No description provided for @balancePendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get balancePendingLabel;

  /// No description provided for @balanceDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get balanceDueLabel;

  /// No description provided for @balanceCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get balanceCreditLabel;

  /// No description provided for @balanceNetLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get balanceNetLabel;

  /// No description provided for @balancesAsOfTodayHeading.
  ///
  /// In en, this message translates to:
  /// **'Balances as of today'**
  String get balancesAsOfTodayHeading;

  /// No description provided for @balanceOpenItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) out'**
  String balanceOpenItemsCount(int count);

  /// No description provided for @customerSubtitleWithBalances.
  ///
  /// In en, this message translates to:
  /// **'{phone} • {tier} • Advance {advance} · Pending {pending} · Net {net}'**
  String customerSubtitleWithBalances(
    String phone,
    String tier,
    String advance,
    String pending,
    String net,
  );

  /// No description provided for @orderStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get orderStatusOpen;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderBillDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance {amount}'**
  String orderBillDepositLabel(String amount);

  /// No description provided for @orderBillTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill {amount}'**
  String orderBillTotalLabel(String amount);

  /// No description provided for @orderDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Order advance'**
  String get orderDepositLabel;

  /// No description provided for @customerOrdersHeading.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get customerOrdersHeading;

  /// No description provided for @orderDepositSettlementExceeds.
  ///
  /// In en, this message translates to:
  /// **'Kept + returned cannot exceed order advance.'**
  String get orderDepositSettlementExceeds;

  /// No description provided for @requiresUnitIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Requires unit name/id'**
  String get requiresUnitIdentityLabel;

  /// No description provided for @requiresUnitIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'On for parent categories (e.g. Novels). Off for individual items that share one catalog name.'**
  String get requiresUnitIdentitySubtitle;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @labelUnitHeading.
  ///
  /// In en, this message translates to:
  /// **'{name} #{index}'**
  String labelUnitHeading(String name, int index);

  /// No description provided for @labelsAutoAssignedHint.
  ///
  /// In en, this message translates to:
  /// **'Individual items get catalog name and an auto short code.'**
  String get labelsAutoAssignedHint;

  /// No description provided for @orderStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get orderStatusHeading;

  /// No description provided for @workflowStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Workflow status'**
  String get workflowStatusHeading;

  /// No description provided for @workflowAdvanceAction.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get workflowAdvanceAction;

  /// No description provided for @workflowPickStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Pick status'**
  String get workflowPickStatusAction;

  /// No description provided for @workflowStatusTerminalHint.
  ///
  /// In en, this message translates to:
  /// **'Order completed for this pipeline.'**
  String get workflowStatusTerminalHint;

  /// No description provided for @orderIssuedSummary.
  ///
  /// In en, this message translates to:
  /// **'Originally issued: {count}'**
  String orderIssuedSummary(int count);

  /// No description provided for @orderPendingSummary.
  ///
  /// In en, this message translates to:
  /// **'Still out: {count}'**
  String orderPendingSummary(int count);

  /// No description provided for @orderReturnedSummary.
  ///
  /// In en, this message translates to:
  /// **'Already returned: {count}'**
  String orderReturnedSummary(int count);

  /// No description provided for @rentalOrderStatusChips.
  ///
  /// In en, this message translates to:
  /// **'Issued {issued} · Pending {pending} · Returned {returned}'**
  String rentalOrderStatusChips(int issued, int pending, int returned);

  /// No description provided for @activityTimelineHeading.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTimelineHeading;

  /// No description provided for @activityIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued: {labels}'**
  String activityIssued(String labels);

  /// No description provided for @activityReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned: {label}'**
  String activityReturned(String label);

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get activityEmpty;

  /// No description provided for @changeCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'Change customer'**
  String get changeCustomerAction;

  /// No description provided for @addOrderLineAction.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get addOrderLineAction;

  /// No description provided for @removeOrderLineAction.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get removeOrderLineAction;

  /// No description provided for @selectResourceItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get selectResourceItemLabel;

  /// No description provided for @orderLineHeading.
  ///
  /// In en, this message translates to:
  /// **'Line {number}'**
  String orderLineHeading(int number);

  /// No description provided for @orderTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Order total: {amount}'**
  String orderTotalLabel(String amount);

  /// No description provided for @orderSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummaryHeading;

  /// No description provided for @orderSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock for {name} (need {need}, available {available}). Adjust quantities to continue.'**
  String orderSummaryUnavailable(String name, int need, int available);

  /// No description provided for @orderSummaryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity}'**
  String orderSummaryQuantity(int quantity);

  /// No description provided for @orderSummaryUnitCharge.
  ///
  /// In en, this message translates to:
  /// **'Unit {amount}'**
  String orderSummaryUnitCharge(String amount);

  /// No description provided for @depositTopUpOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance (optional)'**
  String get depositTopUpOptionalLabel;

  /// No description provided for @depositTopUpOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Held on this order, in rupees'**
  String get depositTopUpOptionalHint;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @addUnitLabelsAction.
  ///
  /// In en, this message translates to:
  /// **'Add unit labels'**
  String get addUnitLabelsAction;

  /// No description provided for @itemKindDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default order mode'**
  String get itemKindDefaultLabel;

  /// No description provided for @itemKindRentalLabel.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get itemKindRentalLabel;

  /// No description provided for @itemKindSaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get itemKindSaleLabel;

  /// No description provided for @itemKindServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get itemKindServiceLabel;

  /// No description provided for @itemKindJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get itemKindJobLabel;

  /// No description provided for @itemKindSubscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get itemKindSubscriptionLabel;

  /// No description provided for @itemKindMembershipLabel.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get itemKindMembershipLabel;

  /// No description provided for @itemKindLoanLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get itemKindLoanLabel;

  /// No description provided for @itemKindFinancialLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get itemKindFinancialLabel;

  /// No description provided for @itemKindCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get itemKindCustomLabel;

  /// No description provided for @itemKindSaleBadge.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get itemKindSaleBadge;

  /// No description provided for @itemKindServiceBadge.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get itemKindServiceBadge;

  /// No description provided for @itemKindJobBadge.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get itemKindJobBadge;

  /// No description provided for @itemKindSubscriptionBadge.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get itemKindSubscriptionBadge;

  /// No description provided for @itemKindMembershipBadge.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get itemKindMembershipBadge;

  /// No description provided for @itemKindLoanBadge.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get itemKindLoanBadge;

  /// No description provided for @itemKindFinancialBadge.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get itemKindFinancialBadge;

  /// No description provided for @itemKindCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get itemKindCustomBadge;

  /// No description provided for @lineFulfillmentRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get lineFulfillmentRent;

  /// No description provided for @lineFulfillmentSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get lineFulfillmentSell;

  /// No description provided for @lineFulfillmentJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get lineFulfillmentJob;

  /// No description provided for @saleAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale amount'**
  String get saleAmountLabel;

  /// No description provided for @saleAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount in rupees'**
  String get saleAmountHint;

  /// No description provided for @saleAmountRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter a sale amount greater than zero.'**
  String get saleAmountRequiredError;

  /// No description provided for @jobAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Job charge'**
  String get jobAmountLabel;

  /// No description provided for @jobAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount in rupees'**
  String get jobAmountHint;

  /// No description provided for @jobAmountRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter a job charge greater than zero.'**
  String get jobAmountRequiredError;

  /// No description provided for @soldLineBadge.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldLineBadge;

  /// No description provided for @completedJobLineBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedJobLineBadge;

  /// No description provided for @selectLinesToComplete.
  ///
  /// In en, this message translates to:
  /// **'Select job lines to mark complete'**
  String get selectLinesToComplete;

  /// No description provided for @markCompleteAllAction.
  ///
  /// In en, this message translates to:
  /// **'Mark all complete'**
  String get markCompleteAllAction;

  /// No description provided for @markCompleteSelectedAction.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markCompleteSelectedAction;

  /// No description provided for @confirmCompleteJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark jobs complete?'**
  String get confirmCompleteJobsTitle;

  /// No description provided for @confirmCompleteJobsBody.
  ///
  /// In en, this message translates to:
  /// **'Close {count} job line(s). Stock is not restored.'**
  String confirmCompleteJobsBody(int count);

  /// No description provided for @jobsCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Jobs marked complete'**
  String get jobsCompletedSnack;

  /// No description provided for @orderNotesHeading.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get orderNotesHeading;

  /// No description provided for @addOrderNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addOrderNoteAction;

  /// No description provided for @orderNoteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get orderNoteBodyLabel;

  /// No description provided for @orderNoteBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Terms, measurements, or other details'**
  String get orderNoteBodyHint;

  /// No description provided for @orderNoteKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get orderNoteKindLabel;

  /// No description provided for @orderNoteKindGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get orderNoteKindGeneral;

  /// No description provided for @orderNoteKindTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get orderNoteKindTerms;

  /// No description provided for @orderNoteKindMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get orderNoteKindMeasurement;

  /// No description provided for @orderNoteLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Link to line'**
  String get orderNoteLineLabel;

  /// No description provided for @orderNoteWholeOrder.
  ///
  /// In en, this message translates to:
  /// **'Whole order'**
  String get orderNoteWholeOrder;

  /// No description provided for @orderNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get orderNotesEmpty;

  /// No description provided for @orderNoteAddedSnack.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get orderNoteAddedSnack;

  /// No description provided for @orderBillAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get orderBillAmountLabel;

  /// No description provided for @orderDepositShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get orderDepositShortLabel;

  /// No description provided for @ordersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ordersFilterOpen;

  /// No description provided for @ordersFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersFilterCompleted;

  /// No description provided for @ordersFilterPendingJobs.
  ///
  /// In en, this message translates to:
  /// **'Pending jobs'**
  String get ordersFilterPendingJobs;

  /// No description provided for @searchOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by party, id, or item'**
  String get searchOrdersHint;

  /// No description provided for @inventoryStockMeta.
  ///
  /// In en, this message translates to:
  /// **'{category} · {available}/{total}'**
  String inventoryStockMeta(String category, int available, int total);

  /// No description provided for @moneyLabelBase.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get moneyLabelBase;

  /// No description provided for @moneyLabelLate.
  ///
  /// In en, this message translates to:
  /// **'Late fee'**
  String get moneyLabelLate;

  /// No description provided for @moneyLabelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get moneyLabelTotal;

  /// No description provided for @moneyLabelDeposit.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get moneyLabelDeposit;

  /// No description provided for @moneyLabelWillApply.
  ///
  /// In en, this message translates to:
  /// **'Will apply'**
  String get moneyLabelWillApply;

  /// No description provided for @moneyLabelRemainingDue.
  ///
  /// In en, this message translates to:
  /// **'Remaining due'**
  String get moneyLabelRemainingDue;

  /// No description provided for @moneyLabelLeftover.
  ///
  /// In en, this message translates to:
  /// **'Leftover advance'**
  String get moneyLabelLeftover;

  /// No description provided for @moneyLabelNetDue.
  ///
  /// In en, this message translates to:
  /// **'Net due'**
  String get moneyLabelNetDue;

  /// No description provided for @reportWhatsAppGateBanner.
  ///
  /// In en, this message translates to:
  /// **'Set your WhatsApp number in More to share reports.'**
  String get reportWhatsAppGateBanner;

  /// No description provided for @reportConfigureWhatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'Set WhatsApp'**
  String get reportConfigureWhatsAppAction;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rental events yet.'**
  String get timelineEmpty;

  /// No description provided for @timelineTitleOrderOpened.
  ///
  /// In en, this message translates to:
  /// **'Order opened'**
  String get timelineTitleOrderOpened;

  /// No description provided for @timelineTitleReplacementOpened.
  ///
  /// In en, this message translates to:
  /// **'Replacement opened'**
  String get timelineTitleReplacementOpened;

  /// No description provided for @timelineTitleSaleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale completed'**
  String get timelineTitleSaleCompleted;

  /// No description provided for @timelineTitleJobOpened.
  ///
  /// In en, this message translates to:
  /// **'Job opened'**
  String get timelineTitleJobOpened;

  /// No description provided for @timelineTitleReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get timelineTitleReturned;

  /// No description provided for @timelineTitlePartialReturn.
  ///
  /// In en, this message translates to:
  /// **'Partial return'**
  String get timelineTitlePartialReturn;

  /// No description provided for @timelineTitleJobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jobs completed'**
  String get timelineTitleJobsCompleted;

  /// No description provided for @timelineTitleJobCompleted.
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get timelineTitleJobCompleted;

  /// No description provided for @timelineTitleOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get timelineTitleOrderCancelled;

  /// No description provided for @timelineTitleNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get timelineTitleNoteAdded;

  /// No description provided for @timelineTitleDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get timelineTitleDueToday;

  /// No description provided for @timelineTitleRentalOpened.
  ///
  /// In en, this message translates to:
  /// **'Rental opened'**
  String get timelineTitleRentalOpened;

  /// No description provided for @timelineTitleIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get timelineTitleIssued;

  /// No description provided for @timelineTitleStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get timelineTitleStatusChanged;

  /// No description provided for @timelineSubtitleCreatedOrderFlow.
  ///
  /// In en, this message translates to:
  /// **'Created from phone-first order flow.'**
  String get timelineSubtitleCreatedOrderFlow;

  /// No description provided for @timelineSubtitleCreatedOrderFlowSale.
  ///
  /// In en, this message translates to:
  /// **'Created from phone-first order flow (sale).'**
  String get timelineSubtitleCreatedOrderFlowSale;

  /// No description provided for @timelineSubtitleCreatedOrderFlowJob.
  ///
  /// In en, this message translates to:
  /// **'Created from phone-first order flow (job).'**
  String get timelineSubtitleCreatedOrderFlowJob;

  /// No description provided for @timelineSubtitleCreatedOrderFlowMixed.
  ///
  /// In en, this message translates to:
  /// **'Created from phone-first order flow (mixed).'**
  String get timelineSubtitleCreatedOrderFlowMixed;

  /// No description provided for @timelineSubtitleReplacementFor.
  ///
  /// In en, this message translates to:
  /// **'Replacement for {orderId}.'**
  String timelineSubtitleReplacementFor(String orderId);

  /// No description provided for @timelineSubtitleAllLinesReturned.
  ///
  /// In en, this message translates to:
  /// **'All lines returned by staff.'**
  String get timelineSubtitleAllLinesReturned;

  /// No description provided for @timelineSubtitleAllLinesReturnedLate.
  ///
  /// In en, this message translates to:
  /// **'All lines returned. Late fee applied.'**
  String get timelineSubtitleAllLinesReturnedLate;

  /// No description provided for @timelineSubtitlePartialReturnLines.
  ///
  /// In en, this message translates to:
  /// **'Returned {returned} of {total} lines.'**
  String timelineSubtitlePartialReturnLines(int returned, int total);

  /// No description provided for @timelineSubtitleAllJobsComplete.
  ///
  /// In en, this message translates to:
  /// **'All job lines marked complete.'**
  String get timelineSubtitleAllJobsComplete;

  /// No description provided for @timelineSubtitleJobsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed {count} job line(s).'**
  String timelineSubtitleJobsCompletedCount(int count);

  /// No description provided for @timelineSubtitleCancelSettlement.
  ///
  /// In en, this message translates to:
  /// **'Kept {kept}; returned {returned}.'**
  String timelineSubtitleCancelSettlement(String kept, String returned);

  /// No description provided for @timelineSubtitleNoteBody.
  ///
  /// In en, this message translates to:
  /// **'{kind}: {body}'**
  String timelineSubtitleNoteBody(String kind, String body);

  /// No description provided for @timelineSubtitleAutoReminder.
  ///
  /// In en, this message translates to:
  /// **'Auto reminder generated.'**
  String get timelineSubtitleAutoReminder;

  /// No description provided for @timelineSubtitleCheckedOutByStaff.
  ///
  /// In en, this message translates to:
  /// **'1 item checked out by staff.'**
  String get timelineSubtitleCheckedOutByStaff;

  /// No description provided for @timelineSubtitleClosedAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Closed at counter.'**
  String get timelineSubtitleClosedAtCounter;

  /// No description provided for @timelineSubtitleManualWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Manual walk-in checkout.'**
  String get timelineSubtitleManualWalkIn;

  /// No description provided for @timelineSubtitleStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String timelineSubtitleStatusChanged(String from, String to);

  /// No description provided for @timelineSubtitleDiscountBit.
  ///
  /// In en, this message translates to:
  /// **'Discount {amount}.'**
  String timelineSubtitleDiscountBit(String amount);

  /// No description provided for @timelineSubtitleNoteBit.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String timelineSubtitleNoteBit(String note);

  /// No description provided for @reportHeader.
  ///
  /// In en, this message translates to:
  /// **'{appName} report'**
  String reportHeader(String appName);

  /// No description provided for @reportActiveCount.
  ///
  /// In en, this message translates to:
  /// **'Active: {count}'**
  String reportActiveCount(int count);

  /// No description provided for @reportOpenedCount.
  ///
  /// In en, this message translates to:
  /// **'Opened: {count}'**
  String reportOpenedCount(int count);

  /// No description provided for @reportReturnedCount.
  ///
  /// In en, this message translates to:
  /// **'Returned: {count}'**
  String reportReturnedCount(int count);

  /// No description provided for @reportOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {count}'**
  String reportOverdueCount(int count);

  /// No description provided for @reportChargesOpened.
  ///
  /// In en, this message translates to:
  /// **'Charges (opened in range): {amount}'**
  String reportChargesOpened(String amount);

  /// No description provided for @reportChargesReturned.
  ///
  /// In en, this message translates to:
  /// **'Charges (returned in range): {amount}'**
  String reportChargesReturned(String amount);

  /// No description provided for @reportDepositAppliedRange.
  ///
  /// In en, this message translates to:
  /// **'Deposit applied (returned in range): {amount}'**
  String reportDepositAppliedRange(String amount);

  /// No description provided for @reportBalanceDueReturned.
  ///
  /// In en, this message translates to:
  /// **'Balance due after deposit (returned): {amount}'**
  String reportBalanceDueReturned(String amount);

  /// No description provided for @reportNoRentalsInRange.
  ///
  /// In en, this message translates to:
  /// **'(no rentals in range)'**
  String get reportNoRentalsInRange;

  /// No description provided for @reportNoResources.
  ///
  /// In en, this message translates to:
  /// **'(no resources)'**
  String get reportNoResources;

  /// No description provided for @reportCustomerWithDeposit.
  ///
  /// In en, this message translates to:
  /// **'{header} | deposit {amount}'**
  String reportCustomerWithDeposit(String header, String amount);

  /// No description provided for @reportStatusReturnedBit.
  ///
  /// In en, this message translates to:
  /// **'[returned]'**
  String get reportStatusReturnedBit;

  /// No description provided for @reportLinesPartialBit.
  ///
  /// In en, this message translates to:
  /// **' | lines {open} open/{returned} returned'**
  String reportLinesPartialBit(int open, int returned);

  /// No description provided for @reportDepositDueBit.
  ///
  /// In en, this message translates to:
  /// **' | deposit {deposit} | due {due}'**
  String reportDepositDueBit(String deposit, String due);

  /// No description provided for @reportOpenEnded.
  ///
  /// In en, this message translates to:
  /// **'open-ended'**
  String get reportOpenEnded;

  /// No description provided for @reportDueDateBit.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String reportDueDateBit(String date);

  /// No description provided for @reportCustomerRentalLine.
  ///
  /// In en, this message translates to:
  /// **'  • {prefix}{rentalId}: {items} | {dueBit} | {status} | {amount}{partialBit}{depositBit}'**
  String reportCustomerRentalLine(
    String prefix,
    String rentalId,
    String items,
    String dueBit,
    String status,
    String amount,
    String partialBit,
    String depositBit,
  );

  /// No description provided for @reportInventoryItemLine.
  ///
  /// In en, this message translates to:
  /// **'• {name}: rented {rented}× | out {out} | avail {available}/{total} | {billing} {rate}'**
  String reportInventoryItemLine(
    String name,
    int rented,
    int out,
    int available,
    int total,
    String billing,
    String rate,
  );

  /// No description provided for @reportTruncatedSuffix.
  ///
  /// In en, this message translates to:
  /// **'\n…(truncated — open {appName} for full)'**
  String reportTruncatedSuffix(String appName);

  /// No description provided for @loansTitle.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansTitle;

  /// No description provided for @loansMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cash loans given and taken'**
  String get loansMoreSubtitle;

  /// No description provided for @loanCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get loanCreateTitle;

  /// No description provided for @loanCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get loanCreateAction;

  /// No description provided for @loanDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan calculator'**
  String get loanDetailTitle;

  /// No description provided for @loanNotFound.
  ///
  /// In en, this message translates to:
  /// **'Loan not found'**
  String get loanNotFound;

  /// No description provided for @loanStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get loanStatusPending;

  /// No description provided for @loanStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get loanStatusClosed;

  /// No description provided for @loanStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get loanStatusCancelled;

  /// No description provided for @loansPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending loans.'**
  String get loansPendingEmpty;

  /// No description provided for @loansClosedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No closed loans yet.'**
  String get loansClosedEmpty;

  /// No description provided for @loanDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get loanDirectionLabel;

  /// No description provided for @loanDirectionGiven.
  ///
  /// In en, this message translates to:
  /// **'Given (lent out)'**
  String get loanDirectionGiven;

  /// No description provided for @loanDirectionTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken (borrowed)'**
  String get loanDirectionTaken;

  /// No description provided for @loanCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get loanCustomerLabel;

  /// No description provided for @loanCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get loanCustomerHint;

  /// No description provided for @loanCustomerRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a customer'**
  String get loanCustomerRequired;

  /// No description provided for @loanPrincipalLabel.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get loanPrincipalLabel;

  /// No description provided for @loanOriginalPrincipalLabel.
  ///
  /// In en, this message translates to:
  /// **'Original principal'**
  String get loanOriginalPrincipalLabel;

  /// No description provided for @loanPrincipalRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a principal amount'**
  String get loanPrincipalRequired;

  /// No description provided for @loanMoneyGivenOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Money given on'**
  String get loanMoneyGivenOnLabel;

  /// No description provided for @loanDueOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Due / end (optional)'**
  String get loanDueOptionalLabel;

  /// No description provided for @loanDueNone.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get loanDueNone;

  /// No description provided for @loanInterestKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get loanInterestKindLabel;

  /// No description provided for @loanInterestSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get loanInterestSimple;

  /// No description provided for @loanInterestCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get loanInterestCompound;

  /// No description provided for @loanPrepaymentAllocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayment applies to'**
  String get loanPrepaymentAllocationLabel;

  /// No description provided for @loanPrepaymentInterestFirst.
  ///
  /// In en, this message translates to:
  /// **'Interest first'**
  String get loanPrepaymentInterestFirst;

  /// No description provided for @loanPrepaymentPrincipalOnly.
  ///
  /// In en, this message translates to:
  /// **'Principal only'**
  String get loanPrepaymentPrincipalOnly;

  /// No description provided for @loanPrepaymentAllocationHint.
  ///
  /// In en, this message translates to:
  /// **'Interest first clears unpaid interest, then principal. Principal only reduces principal; unpaid interest stays until paid separately.'**
  String get loanPrepaymentAllocationHint;

  /// No description provided for @loanRatePercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get loanRatePercentLabel;

  /// No description provided for @loanRatePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get loanRatePeriodLabel;

  /// No description provided for @loanRateMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get loanRateMonthly;

  /// No description provided for @loanRateYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get loanRateYearly;

  /// No description provided for @loanPeriodEndInterestHintSimple.
  ///
  /// In en, this message translates to:
  /// **'Mid-period repayments and top-ups accrue pro-rata interest for time outstanding. At each month or year anniversary that interest is due but not added to principal.'**
  String get loanPeriodEndInterestHintSimple;

  /// No description provided for @loanPeriodEndInterestHintCompound.
  ///
  /// In en, this message translates to:
  /// **'Mid-period repayments reduce principal and accrue pro-rata interest for time outstanding. Added principal accrues pro-rata until period end. That interest, plus full-period interest on what was outstanding the whole period, is added to principal at each month or year anniversary.'**
  String get loanPeriodEndInterestHintCompound;

  /// No description provided for @loanRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate'**
  String get loanRateInvalid;

  /// No description provided for @loanNoteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get loanNoteOptionalLabel;

  /// No description provided for @loanSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get loanSaving;

  /// No description provided for @loanPendingNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending now'**
  String get loanPendingNowLabel;

  /// No description provided for @loanInterestToDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest to date'**
  String get loanInterestToDateLabel;

  /// No description provided for @loanPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get loanPaidLabel;

  /// No description provided for @loanAdjustmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get loanAdjustmentsLabel;

  /// No description provided for @loanTimelineHeading.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get loanTimelineHeading;

  /// No description provided for @loanAddPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get loanAddPayment;

  /// No description provided for @loanAddPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Add to principal'**
  String get loanAddPrincipal;

  /// No description provided for @loanAddAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Add adjustment'**
  String get loanAddAdjustment;

  /// No description provided for @loanEntryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get loanEntryDateLabel;

  /// No description provided for @loanFlowRepayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get loanFlowRepayment;

  /// No description provided for @loanFlowAddPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Add to principal'**
  String get loanFlowAddPrincipal;

  /// No description provided for @loanFlowRepaymentGiven.
  ///
  /// In en, this message translates to:
  /// **'Received from party'**
  String get loanFlowRepaymentGiven;

  /// No description provided for @loanFlowRepaymentTaken.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get loanFlowRepaymentTaken;

  /// No description provided for @loanFlowDisbursementGiven.
  ///
  /// In en, this message translates to:
  /// **'Gave more'**
  String get loanFlowDisbursementGiven;

  /// No description provided for @loanFlowDisbursementTaken.
  ///
  /// In en, this message translates to:
  /// **'Borrowed more'**
  String get loanFlowDisbursementTaken;

  /// No description provided for @loanPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get loanPaymentAmountLabel;

  /// No description provided for @loanAdjustmentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustment amount'**
  String get loanAdjustmentAmountLabel;

  /// No description provided for @loanAdjustmentHint.
  ///
  /// In en, this message translates to:
  /// **'Positive forgives remaining; negative increases principal'**
  String get loanAdjustmentHint;

  /// No description provided for @loanSaveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get loanSaveEntry;

  /// No description provided for @loanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get loanCancel;

  /// No description provided for @loanKeepPending.
  ///
  /// In en, this message translates to:
  /// **'Keep pending'**
  String get loanKeepPending;

  /// No description provided for @loanKeepPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Loan stays open until you mark it closed.'**
  String get loanKeepPendingHint;

  /// No description provided for @loanMarkClosed.
  ///
  /// In en, this message translates to:
  /// **'Mark closed'**
  String get loanMarkClosed;

  /// No description provided for @loanReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen loan'**
  String get loanReopen;

  /// No description provided for @loanClosedSnack.
  ///
  /// In en, this message translates to:
  /// **'Loan marked closed'**
  String get loanClosedSnack;

  /// No description provided for @loanCloseWithPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Close with balance pending?'**
  String get loanCloseWithPendingTitle;

  /// No description provided for @loanCloseWithPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Still pending {amount}. Close anyway, or add an adjustment first?'**
  String loanCloseWithPendingBody(String amount);

  /// No description provided for @loanEditSetupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit dates'**
  String get loanEditSetupTooltip;

  /// No description provided for @loanEditSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit loan dates'**
  String get loanEditSetupTitle;

  /// No description provided for @loanSetupSummary.
  ///
  /// In en, this message translates to:
  /// **'Start {start} · Due {due} · {rate} {period} · {kind}'**
  String loanSetupSummary(
    String start,
    String due,
    String rate,
    String period,
    String kind,
  );

  /// No description provided for @loanPrepaymentSetupLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayments: {mode}'**
  String loanPrepaymentSetupLabel(String mode);

  /// No description provided for @loanTimelineStart.
  ///
  /// In en, this message translates to:
  /// **'{date} — Loan started · {amount}'**
  String loanTimelineStart(String date, String amount);

  /// No description provided for @loanTimelineInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest posted {date} on {principal} → {amount} (added to principal)'**
  String loanTimelineInterest(String date, String principal, String amount);

  /// No description provided for @loanTimelineDeferredSlice.
  ///
  /// In en, this message translates to:
  /// **'Interest on repaid {principal} through {date} → {amount} (adds at period end)'**
  String loanTimelineDeferredSlice(
    String principal,
    String date,
    String amount,
  );

  /// No description provided for @loanTimelineDeferredAddSlice.
  ///
  /// In en, this message translates to:
  /// **'Interest on added {principal} from {date} → period end → {amount} (adds at period end)'**
  String loanTimelineDeferredAddSlice(
    String principal,
    String date,
    String amount,
  );

  /// No description provided for @loanTimelinePeriodEndSlice.
  ///
  /// In en, this message translates to:
  /// **'Interest on payment {repaid} ({from}–{to}) → {interest} (added to principal)'**
  String loanTimelinePeriodEndSlice(
    String repaid,
    String from,
    String to,
    String interest,
  );

  /// No description provided for @loanTimelinePeriodEndSliceDue.
  ///
  /// In en, this message translates to:
  /// **'Interest due on payment {repaid} ({from}–{to}) → {interest} (not added to principal)'**
  String loanTimelinePeriodEndSliceDue(
    String repaid,
    String from,
    String to,
    String interest,
  );

  /// No description provided for @loanTimelinePeriodEndAddSlice.
  ///
  /// In en, this message translates to:
  /// **'Interest on added principal {added} ({from}–{to}) → {interest} (added to principal)'**
  String loanTimelinePeriodEndAddSlice(
    String added,
    String from,
    String to,
    String interest,
  );

  /// No description provided for @loanTimelinePeriodEndAddSliceDue.
  ///
  /// In en, this message translates to:
  /// **'Interest due on added principal {added} ({from}–{to}) → {interest} (not added to principal)'**
  String loanTimelinePeriodEndAddSliceDue(
    String added,
    String from,
    String to,
    String interest,
  );

  /// No description provided for @loanTimelineRemainingPeriodInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest on remaining {principal} for full period → {amount} (added to principal)'**
  String loanTimelineRemainingPeriodInterest(String principal, String amount);

  /// No description provided for @loanTimelineRemainingPeriodInterestDue.
  ///
  /// In en, this message translates to:
  /// **'Interest due on remaining {principal} for full period → {amount} (not added to principal)'**
  String loanTimelineRemainingPeriodInterestDue(
    String principal,
    String amount,
  );

  /// No description provided for @loanTimelinePrincipalNow.
  ///
  /// In en, this message translates to:
  /// **'{date} — Principal now {amount}'**
  String loanTimelinePrincipalNow(String date, String amount);

  /// No description provided for @loanTimelinePrincipalRemains.
  ///
  /// In en, this message translates to:
  /// **'{date} — Principal remains {amount}'**
  String loanTimelinePrincipalRemains(String date, String amount);

  /// No description provided for @loanTimelinePayment.
  ///
  /// In en, this message translates to:
  /// **'{date} — Repayment {amount} → principal {principal}'**
  String loanTimelinePayment(String date, String amount, String principal);

  /// No description provided for @loanTimelinePaymentSplit.
  ///
  /// In en, this message translates to:
  /// **'{date} — Repayment {amount} → interest {interest}, principal {principal}'**
  String loanTimelinePaymentSplit(
    String date,
    String amount,
    String interest,
    String principal,
  );

  /// No description provided for @loanTimelineDisbursement.
  ///
  /// In en, this message translates to:
  /// **'{date} — Added principal {amount}'**
  String loanTimelineDisbursement(String date, String amount);

  /// No description provided for @loanTimelineAdjustment.
  ///
  /// In en, this message translates to:
  /// **'{date} — Adjustment {amount}'**
  String loanTimelineAdjustment(String date, String amount);

  /// No description provided for @loanTimelinePending.
  ///
  /// In en, this message translates to:
  /// **'{date} — Pending {amount}'**
  String loanTimelinePending(String date, String amount);

  /// No description provided for @modulePendingLoans.
  ///
  /// In en, this message translates to:
  /// **'Pending loans'**
  String get modulePendingLoans;

  /// No description provided for @modulePendingLoansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open cash loans still outstanding'**
  String get modulePendingLoansSubtitle;

  /// No description provided for @pendingLoansTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending loans'**
  String get pendingLoansTitle;

  /// No description provided for @pendingLoansEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No pending loans right now.'**
  String get pendingLoansEmptySubtitle;

  /// No description provided for @moduleDueLoans.
  ///
  /// In en, this message translates to:
  /// **'Due loans'**
  String get moduleDueLoans;

  /// No description provided for @moduleDueLoansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending loans at or past their due date'**
  String get moduleDueLoansSubtitle;

  /// No description provided for @dueLoansTitle.
  ///
  /// In en, this message translates to:
  /// **'Due loans'**
  String get dueLoansTitle;

  /// No description provided for @dueLoansEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No due loans right now.'**
  String get dueLoansEmptySubtitle;

  /// No description provided for @customerLoansHeading.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get customerLoansHeading;

  /// No description provided for @customerLoansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loans for this customer.'**
  String get customerLoansEmpty;

  /// No description provided for @customerLoansViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all loans'**
  String get customerLoansViewAll;

  /// No description provided for @reportPendingLoansCount.
  ///
  /// In en, this message translates to:
  /// **'Pending loans: {count}'**
  String reportPendingLoansCount(int count);

  /// No description provided for @reportNoOutstandingLoans.
  ///
  /// In en, this message translates to:
  /// **'No outstanding loans.'**
  String get reportNoOutstandingLoans;

  /// No description provided for @reportOutstandingLoansTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {amount} across {count} loan(s)'**
  String reportOutstandingLoansTotal(String amount, int count);
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
