// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get navHome => 'होम';

  @override
  String get navTransactions => 'लेन-देन';

  @override
  String get navResources => 'संसाधन';

  @override
  String get navCustomers => 'ग्राहक';

  @override
  String get navMore => 'और';

  @override
  String get actionSearch => 'खोजें';

  @override
  String get actionNewRental => 'नया ऑर्डर';

  @override
  String get transactionsFilterAll => 'सभी';

  @override
  String get transactionsFilterOrders => 'ऑर्डर';

  @override
  String get transactionsFilterLoans => 'कर्ज';

  @override
  String get newTransaction => 'नया';

  @override
  String get newOrder => 'नया ऑर्डर';

  @override
  String get newLoan => 'नया कर्ज';

  @override
  String get transactionTypeOrder => 'ऑर्डर';

  @override
  String get transactionTypeLoan => 'कर्ज';

  @override
  String get searchTransactionsHint => 'ऑर्डर या कर्ज खोजें';

  @override
  String get noTransactionsYetTitle => 'अभी कोई लेन-देन नहीं';

  @override
  String get noTransactionsYetSubtitle =>
      'शुरू करने के लिए ऑर्डर या कर्ज बनाएँ।';

  @override
  String get customerTransactionsHeading => 'लेन-देन';

  @override
  String get customerTransactionsEmpty => 'इस ग्राहक के लिए कोई लेन-देन नहीं।';

  @override
  String get issueItemAction => 'जारी करें';

  @override
  String get issueToCustomerAction => 'जारी करें';

  @override
  String get searchInventoryHint => 'नाम या श्रेणी से खोजें';

  @override
  String get actionReturn => 'वापसी';

  @override
  String get actionReturnItem => 'वस्तु वापस लें';

  @override
  String get actionAddResource => 'संसाधन जोड़ें';

  @override
  String get actionScan => 'स्कैन';

  @override
  String get actionActions => 'कार्रवाई';

  @override
  String get searchAnything => 'कुछ भी खोजें';

  @override
  String get todayAtAGlance => 'आज एक नज़र में';

  @override
  String get kpiActive => 'सक्रिय';

  @override
  String get statusAvailable => 'उपलब्ध';

  @override
  String get statusRented => 'किराए पर';

  @override
  String get statusDueToday => 'आज देय';

  @override
  String get statusOverdue => 'अतिदेय';

  @override
  String get statusArchived => 'संग्रहीत';

  @override
  String get quickActions => 'त्वरित कार्रवाई';

  @override
  String get aiSuggestionsTitle => 'AI सुझाव (बीटा)';

  @override
  String get aiSuggestionsBody =>
      '• 1 अतिदेय किराए का फ़ॉलो-अप करें\n• Bosch Drill Kit को प्रीमियम मूल्य पर ले जाएँ\n• विस्तार पुष्टि के लिए Priya Patel को कॉल करें';

  @override
  String get offlineBanner =>
      'ऑफ़लाइन काम कर रहे हैं — बदलाव बाद में सिंक होंगे।';

  @override
  String get noRentalsYetTitle => 'अभी कोई ऑर्डर नहीं';

  @override
  String get noRentalsYetSubtitle =>
      'अपना पहला लेन-देन बनाने के लिए नया ऑर्डर शुरू करें।';

  @override
  String get unknownCustomer => 'अज्ञात ग्राहक';

  @override
  String inventoryAvailableSubtitle(String category, int available, int total) {
    return '$category • $available/$total उपलब्ध';
  }

  @override
  String get customerTrusted => 'विश्वसनीय';

  @override
  String get customerStandard => 'सामान्य';

  @override
  String get offlineSimulationTitle => 'ऑफ़लाइन सिमुलेशन';

  @override
  String get offlineSimulationSubtitle =>
      'केवल डेमो: नॉन-ब्लॉकिंग ऑफ़लाइन UX जाँचें (उत्पाद स्थिति नहीं)।';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSubtitle => 'ऐप की भाषा चुनें';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get themeTitle => 'थीम';

  @override
  String get themeSubtitle => 'डार्क या लाइट रूप चुनें';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeLight => 'लाइट';

  @override
  String get voiceSearchStubTitle => 'वॉइस खोज (स्टब)';

  @override
  String get voiceSearchStubSubtitle =>
      'इंटेंट-आधारित खोज कमांड के लिए प्लेसहोल्डर।';

  @override
  String get businessTemplatesTitle => 'व्यवसाय टेम्पलेट';

  @override
  String get businessTemplatesSubtitle =>
      'किसी भी समय सक्रिय व्यवसाय पैक बदलें। मौजूदा कर्ज और ऑर्डर लेनदेन में रहते हैं; नया कर्ज के लिए मनी लेंडिंग सक्रिय होना चाहिए।';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get onboardingLanguageTitle => 'अपनी भाषा चुनें';

  @override
  String get onboardingLanguageSubtitle => 'बाद में और में बदल सकते हैं।';

  @override
  String get onboardingModeTitle => 'आप कैसे काम करना चाहते हैं?';

  @override
  String get onboardingModeSubtitle =>
      'ऑफ़लाइन डिफ़ॉल्ट है — सब कुछ इसी डिवाइस पर रहता है।';

  @override
  String get onboardingModeOfflineTitle => 'ऑफ़लाइन';

  @override
  String get onboardingModeOfflineSubtitle =>
      'इंटरनेट के बिना चलता है। डेटा लोकल-फर्स्ट इसी डिवाइस पर रहता है।';

  @override
  String get onboardingModeOnlineTitle => 'ऑनलाइन';

  @override
  String get onboardingModeOnlineSubtitle =>
      'WhatsApp रिपोर्ट और भविष्य का सिंक / OTP स्वामित्व प्रमाण।';

  @override
  String get onboardingWhatsAppTitle => 'आपका WhatsApp नंबर';

  @override
  String get onboardingWhatsAppSubtitle =>
      'ऑनलाइन मोड के लिए आवश्यक — स्वामित्व सत्यापन और रिपोर्ट शेयर के लिए।';

  @override
  String get onboardingWhatsAppOtpLabel => 'OTP';

  @override
  String get onboardingWhatsAppOtpHint => 'बाद में आएगा';

  @override
  String get onboardingWhatsAppOtpLater =>
      'हम इस नंबर को बाद में OTP से सत्यापित करेंगे। अभी नंबर सहेजना पर्याप्त है।';

  @override
  String get onboardingTemplateTitle => 'अपना व्यवसाय प्रकार चुनें';

  @override
  String get onboardingTemplateSubtitle =>
      'हम आपके उद्योग के लिए स्टार्टर संसाधन जोड़ेंगे। बाद में और → व्यवसाय टेम्पलेट से और जोड़ सकते हैं।';

  @override
  String get onboardingTemplateConfirm => 'यह टेम्पलेट उपयोग करें';

  @override
  String get onboardingTemplateCancel => 'वापस';

  @override
  String onboardingTemplateConfirmBody(int count, String name) {
    return '$name के सभी $count स्टार्टर आइटम जोड़ें और अनुशंसित होम लेआउट सेट करें?';
  }

  @override
  String phoneLabel(String phone) {
    return 'फ़ोन: $phone';
  }

  @override
  String get itemsHeading => 'वस्तुएँ';

  @override
  String get timelineHeading => 'टाइमलाइन';

  @override
  String get extendAction => 'बढ़ाएँ';

  @override
  String get extendDueTitle => 'देय तिथि बढ़ाएँ';

  @override
  String get extendDueSuccess => 'देय तिथि बढ़ाई गई।';

  @override
  String get extendDueInvalid => 'वर्तमान देय तिथि के बाद की तारीख चुनें।';

  @override
  String get unitCodePrefixLabel => 'कोड उपसर्ग';

  @override
  String get unitCodePrefixHint => 'जैसे SEAT या CAM';

  @override
  String get unitCodePrefixHelper =>
      'कुल इकाइयों से PREFIX-001…N छोटे कोड बनाता है।';

  @override
  String get pickShortCodeLabel => 'छोटा कोड';

  @override
  String get pickShortCodeHint => 'उपलब्ध कोड चुनें';

  @override
  String get noAvailableUnitCodes => 'पूल में कोई उपलब्ध कोड नहीं।';

  @override
  String seatPaymentDueLabel(String code) {
    return '$code भुगतान देय';
  }

  @override
  String get editResourceTitle => 'संसाधन संपादित करें';

  @override
  String get resourceDetailTitle => 'संसाधन विवरण';

  @override
  String get editTooltip => 'संपादित करें';

  @override
  String get itemNameLabel => 'वस्तु का नाम';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get categoryOtherLabel => 'अन्य';

  @override
  String get categoryGeneralLabel => 'सामान्य';

  @override
  String get categoryCustomLabel => 'श्रेणी दर्ज करें';

  @override
  String get categoryCustomHint => 'कस्टम श्रेणी का नाम';

  @override
  String get totalUnitsLabel => 'कुल इकाइयाँ';

  @override
  String get totalUnitsHelper =>
      'उपलब्ध कुल के साथ समायोजित होता है; कुल से अधिक नहीं हो सकता।';

  @override
  String get notesLabel => 'नोट्स';

  @override
  String get notesHint => 'वारंटी / सीरियल / स्थिति';

  @override
  String get qrCodeLabel => 'QR कोड';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get saving => 'सहेजा जा रहा है…';

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get resourceUpdated => 'संसाधन अपडेट हो गया।';

  @override
  String get resourceDeletedSnack => 'संसाधन हटा दिया गया।';

  @override
  String get customerProfileTitle => 'ग्राहक प्रोफ़ाइल';

  @override
  String get callAction => 'कॉल';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get whatsAppSubtitle => 'प्लेसहोल्डर इंटीग्रेशन हुक';

  @override
  String get callPlaceholder => 'कॉल प्लेसहोल्डर कार्रवाई।';

  @override
  String get whatsAppPlaceholder => 'WhatsApp प्लेसहोल्डर कार्रवाई।';

  @override
  String returnedDate(String date) {
    return 'वापस $date';
  }

  @override
  String get searchHint => 'ग्राहक, ऑर्डर या संसाधन खोजें';

  @override
  String get searchSectionCustomers => 'ग्राहक';

  @override
  String get searchSectionCurrentRentals => 'वर्तमान ऑर्डर';

  @override
  String get searchSectionPreviousRentals => 'पिछले ऑर्डर';

  @override
  String get searchSectionResources => 'संसाधन';

  @override
  String inventoryUnitsSubtitle(String category, int available, int total) {
    return '$category • $available/$total';
  }

  @override
  String stepOf(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get phoneNumberLabel => 'फ़ोन नंबर';

  @override
  String get phoneNumberHint => '10 अंकों का ग्राहक फ़ोन';

  @override
  String existingCustomerSubtitle(String phone) {
    return '$phone • मौजूदा ग्राहक';
  }

  @override
  String get customerNameNewLabel => 'नाम';

  @override
  String get customerNameNewHint => 'ग्राहक का नाम';

  @override
  String get noPhoneNumberLabel => 'फ़ोन नंबर नहीं है';

  @override
  String get noPhoneOptionalNameHint => 'इस ऑर्डर के लिए वैकल्पिक प्रदर्शन नाम';

  @override
  String get customerTypeaheadEmpty => 'कोई मिलता ग्राहक नहीं';

  @override
  String get phoneRequiredError =>
      '10 अंकों का फ़ोन दर्ज करें, या फ़ोन नंबर नहीं है चुनें।';

  @override
  String customerSuggestionSubtitle(String name, String phone) {
    return '$name · $phone';
  }

  @override
  String rentalNicknameSubtitle(String customerName, String phone) {
    return '$customerName · $phone';
  }

  @override
  String get instanceNameLabel => 'इकाई का नाम';

  @override
  String get instanceNameHint => 'जैसे हैरी पॉटर';

  @override
  String get shortCodeLabel => 'छोटा कोड';

  @override
  String get shortCodeHint => 'जैसे NOV-042';

  @override
  String get instanceLabelsRequired =>
      'प्रत्येक वस्तु के लिए इकाई का नाम और छोटा कोड दर्ज करें।';

  @override
  String duplicateShortCode(String code) {
    return 'छोटा कोड $code पहले से किसी सक्रिय ऑर्डर पर उपयोग में है।';
  }

  @override
  String get inventoryInstancesNote =>
      'ऑर्डर बनाते समय व्यक्तिगत प्रतियों का नाम और छोटा कोड दर्ज किया जाता है।';

  @override
  String get back => 'वापस';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get confirmRental => 'ऑर्डर बनाएँ';

  @override
  String get noActiveRentalsTitle => 'कोई सक्रिय ऑर्डर नहीं';

  @override
  String get noActiveRentalsSubtitle => 'सब कुछ पहले ही वापस हो चुका है।';

  @override
  String get backToHome => 'होम पर वापस जाएँ';

  @override
  String rentalReturned(String id) {
    return '$id वापस हो गया';
  }

  @override
  String get quickAdd => 'त्वरित जोड़ें';

  @override
  String get unitsLabel => 'इकाइयाँ';

  @override
  String get advancedFields => 'उन्नत फ़ील्ड';

  @override
  String get advancedFieldsSubtitle => 'MVP में वैकल्पिक';

  @override
  String get extraFieldsSectionTitle => 'अतिरिक्त फ़ील्ड';

  @override
  String get saveItem => 'वस्तु सहेजें';

  @override
  String get scanIntro =>
      'अगले चरण में कैमरा इंटीग्रेशन। अभी QR टेक्स्ट पेस्ट/दर्ज करें।';

  @override
  String get qrContentLabel => 'QR सामग्री';

  @override
  String get qrContentHint => 'customer:1001';

  @override
  String get noEntityMatched => 'इस कोड से कोई रिकॉर्ड नहीं मिला।';

  @override
  String get openLinkedRecord => 'लिंक किया गया रिकॉर्ड खोलें';

  @override
  String get voiceSearchTitle => 'वॉइस खोज';

  @override
  String get voiceSearchBody =>
      'केवल स्टब: वॉइस कमांड चरण 5+ में यूनिवर्सल खोज इंटेंट से जुड़ेंगे।';

  @override
  String get templatesIntro =>
      'सक्रिय उद्योग पैक चुनें। बदलने पर होम लेआउट और सक्षम संसाधन प्रकार अपडेट होते हैं। मौजूदा कर्ज, ऑर्डर और इन्वेंटरी बनी रहती है। नया कर्ज तब उपलब्ध है जब मनी लेंडिंग सक्रिय हो।';

  @override
  String get activeTemplateLabel => 'सक्रिय पैक';

  @override
  String get activeTemplateHint => 'व्यवसाय पैक चुनें';

  @override
  String get switchTemplateTitle => 'व्यवसाय पैक बदलें?';

  @override
  String switchTemplateBody(String name) {
    return '$name सक्रिय करें? होम लेआउट और संसाधन प्रकार इस पैक से मेल खाएँगे। मौजूदा कर्ज, ऑर्डर और इन्वेंटरी बनी रहती है।';
  }

  @override
  String get switchTemplateConfirm => 'बदलें';

  @override
  String get switchTemplateCancel => 'रद्द करें';

  @override
  String get switchTemplateDone => 'व्यवसाय पैक अपडेट हो गया।';

  @override
  String templateCardSubtitle(String description, int count) {
    return '$description\n$count स्टार्टर वस्तुएँ';
  }

  @override
  String get selectAll => 'सभी चुनें';

  @override
  String get clearSelection => 'साफ़ करें';

  @override
  String selectedCount(int count) {
    return '$count चयनित';
  }

  @override
  String unitSingular(int count) {
    return '$count इकाई';
  }

  @override
  String unitPlural(int count) {
    return '$count इकाइयाँ';
  }

  @override
  String templateItemSubtitle(String category, String units) {
    return '$category • $units';
  }

  @override
  String get applyTemplateSelection => 'लागू करें';

  @override
  String get applyingTemplateSelection => 'लागू हो रहा है…';

  @override
  String templateApplyResult(
    int added,
    int reactivated,
    int deactivated,
    int skipped,
  ) {
    return '$added जोड़ीं, $reactivated पुनर्स्थापित, $deactivated हटाईं ($skipped अपरिवर्तित)';
  }

  @override
  String get myWhatsAppTitle => 'मेरा WhatsApp नंबर';

  @override
  String get myWhatsAppSubtitle => 'रिपोर्ट अपने WhatsApp पर भेजने के लिए';

  @override
  String get myWhatsAppHint => '10 अंकों का मोबाइल (डिफ़ॉल्ट +91)';

  @override
  String get myWhatsAppSaved => 'WhatsApp नंबर सहेजा गया।';

  @override
  String get myWhatsAppInvalid =>
      'मान्य 10 अंकों का (या पूरा) मोबाइल नंबर दर्ज करें।';

  @override
  String get shareReportsTitle => 'रिपोर्ट शेयर करें';

  @override
  String get shareReportsSubtitle =>
      'टेक्स्ट रिपोर्ट बनाएँ और अपने WhatsApp पर भेजें';

  @override
  String get reportTypeLabel => 'रिपोर्ट प्रकार';

  @override
  String get reportTypeSummary => 'सारांश';

  @override
  String get reportTypeCustomerWise => 'ग्राहक-वार';

  @override
  String get reportTypeResourcesWise => 'संसाधन-वार';

  @override
  String get reportTypeUnitOccupancy => 'यूनिट अधिभोग';

  @override
  String get reportNoUnitPools => 'कोड उपसर्ग वाले कोई संसाधन नहीं।';

  @override
  String get reportNoOccupiedUnits => 'अभी कोई यूनिट बाहर नहीं।';

  @override
  String reportUnitOccupancyItemHeading(String name, int out, int total) {
    return '$name · बाहर $out / $total';
  }

  @override
  String reportUnitOccupancyRow(String code, String status, String customer) {
    return '$code · $status · $customer';
  }

  @override
  String get reportUnitStatusOccupied => 'अधिग्रहित';

  @override
  String get reportUnitStatusAvailable => 'उपलब्ध';

  @override
  String get reportPeriodLabel => 'अवधि';

  @override
  String get reportPeriodDaily => 'दैनिक';

  @override
  String get reportPeriodWeekly => 'साप्ताहिक';

  @override
  String get reportPeriodMonthly => 'मासिक';

  @override
  String get reportPeriodCustom => 'कस्टम';

  @override
  String get reportStartDate => 'प्रारंभ तिथि';

  @override
  String get reportEndDate => 'समाप्ति तिथि';

  @override
  String get reportPreviewLabel => 'पूर्वावलोकन';

  @override
  String get printReport => 'प्रिंट';

  @override
  String reportStillOutAsOf(String date) {
    return 'अभी बाहर ($date तक)';
  }

  @override
  String reportIssuedCount(int count) {
    return 'जारी: $count';
  }

  @override
  String reportStillOutCount(int count) {
    return 'अभी बाहर: $count';
  }

  @override
  String reportMoreCount(int count) {
    return '+$count और';
  }

  @override
  String get reportKpiIssued => 'जारी';

  @override
  String get reportKpiReturned => 'वापस';

  @override
  String get reportKpiStillOut => 'अभी बाहर';

  @override
  String get reportKpiOverdue => 'अतिदेय';

  @override
  String get reportKpiChargesOpened => 'शुल्क (खोले)';

  @override
  String get reportKpiChargesReturned => 'शुल्क (वापस)';

  @override
  String get reportKpiDepositApplied => 'अग्रिम लागू';

  @override
  String get reportKpiSellCollected => 'बिक्री वसूली';

  @override
  String get reportKpiBalanceDue => 'शेष देय';

  @override
  String get reportKpiPendingLoans => 'लंबित कर्ज';

  @override
  String get reportSectionIssued => 'जारी';

  @override
  String get reportSectionReturned => 'वापस';

  @override
  String get reportColParty => 'पक्ष';

  @override
  String get reportColIssued => 'जारी';

  @override
  String get reportColReturned => 'वापस';

  @override
  String get reportColAmount => 'राशि';

  @override
  String get reportColStatus => 'स्थिति';

  @override
  String get reportColItems => 'वस्तुएँ';

  @override
  String get reportColResource => 'संसाधन';

  @override
  String get reportColOut => 'बाहर';

  @override
  String get reportColAvail => 'उपलब्ध';

  @override
  String get reportColCode => 'कोड';

  @override
  String get reportColCustomer => 'ग्राहक';

  @override
  String get shareToMyWhatsApp => 'मेरे WhatsApp पर शेयर करें';

  @override
  String get copyReportText => 'टेक्स्ट कॉपी करें';

  @override
  String get reportCopied => 'रिपोर्ट क्लिपबोर्ड पर कॉपी हो गई।';

  @override
  String get reportWhatsAppOpened =>
      'WhatsApp खुला — भेजने के लिए Send टैप करें।';

  @override
  String get reportWhatsAppFallback =>
      'WhatsApp नहीं खुल सका। रिपोर्ट कॉपी कर दी गई।';

  @override
  String get reportMissingPhone => 'पहले More में मेरा WhatsApp नंबर सेट करें।';

  @override
  String get setWhatsAppAction => 'नंबर सेट करें';

  @override
  String get saveAction => 'सहेजें';

  @override
  String get billingModeLabel => 'बिलिंग मोड';

  @override
  String get billingModeDaily => 'दैनिक';

  @override
  String get billingModeWeekly => 'साप्ताहिक';

  @override
  String get billingModeMonthly => 'मासिक';

  @override
  String get billingModeFixed => 'निश्चित';

  @override
  String get billingModeCustom => 'कस्टम';

  @override
  String get rateAmountLabel => 'दर (₹)';

  @override
  String get rateAmountHint => 'जैसे 50';

  @override
  String get lateFeePerDayLabel => 'प्रतिदिन विलंब शुल्क (₹)';

  @override
  String get lateFeePerDayHint => 'वैकल्पिक, जैसे 5';

  @override
  String get securityDepositLabel => 'सिक्योरिटी जमा (₹)';

  @override
  String get securityDepositHint => 'जैसे 500';

  @override
  String get securityDepositHelper =>
      'किराया ऑर्डर पर प्रति यूनिट सुझाई गई अग्रिम';

  @override
  String securityDepositShort(String amount) {
    return 'सिक्योरिटी $amount';
  }

  @override
  String get pricingSectionTitle => 'किराया मूल्य';

  @override
  String get durationUnitsLabel => 'अवधि';

  @override
  String get durationUnitsDaily => 'दिनों की संख्या';

  @override
  String get durationUnitsWeekly => 'सप्ताहों की संख्या';

  @override
  String get durationUnitsMonthly => 'महीनों की संख्या';

  @override
  String get durationUnitsFixed => 'देय दिनों में';

  @override
  String get customEndDateLabel => 'वापसी तक';

  @override
  String chargePreviewDue(String date) {
    return 'देय $date';
  }

  @override
  String chargeLineAmount(String item, String amount) {
    return '$item — $amount';
  }

  @override
  String chargeTotalLabel(String amount) {
    return 'कुल: $amount';
  }

  @override
  String reviewDueLabel(String date) {
    return 'देय: $date';
  }

  @override
  String rentalAmountSubtitle(String date, String amount) {
    return 'देय $date · $amount';
  }

  @override
  String inventoryRateSubtitle(String mode, String rate) {
    return '$mode · $rate';
  }

  @override
  String get chargesHeading => 'शुल्क';

  @override
  String get depositAmountHint => 'जैसे 500';

  @override
  String depositAvailableLabel(String amount) {
    return 'उपलब्ध जमा: $amount';
  }

  @override
  String depositWillApplyLabel(String amount) {
    return 'जमा से लागू होगा: $amount';
  }

  @override
  String depositRemainingDueLabel(String amount) {
    return 'शेष देय: $amount';
  }

  @override
  String depositLeftoverLabel(String amount) {
    return 'बचा हुआ जमा: $amount';
  }

  @override
  String depositAppliedLabel(String amount) {
    return 'जमा लागू: $amount';
  }

  @override
  String get returnSettlementTitle => 'वापसी निपटान';

  @override
  String get confirmReturnAction => 'वापसी पुष्टि करें';

  @override
  String get returnFinalAmountLabel => 'अंतिम वसूल राशि';

  @override
  String get returnFinalAmountHint => '0 या गणना कुल से कम';

  @override
  String returnDiscountLabel(String amount) {
    return 'छूट $amount';
  }

  @override
  String get returnNoteLabel => 'नोट (वैकल्पिक)';

  @override
  String get returnNoteHint => 'भरने पर कम से कम 3 अक्षर';

  @override
  String get deleteOrderAction => 'ऑर्डर रद्द करें';

  @override
  String get deleteOrderTitle => 'ऑर्डर रद्द करें';

  @override
  String get confirmDeleteOrderAction => 'ऑर्डर रद्द करें';

  @override
  String get deleteOrderKeptLabel => 'रखने की राशि';

  @override
  String get deleteOrderReturnedLabel => 'वापस करने की राशि';

  @override
  String get deleteOrderNoteLabel => 'नोट (वैकल्पिक)';

  @override
  String get deleteOrderInvalidSettlement =>
      'रखे + वापस का योग ऑर्डर जमा से अधिक नहीं हो सकता।';

  @override
  String get deleteOrderBlockedPartial =>
      'वस्तु वापस होने के बाद ऑर्डर रद्द नहीं किया जा सकता।';

  @override
  String get deleteOrderFailed => 'यह ऑर्डर रद्द नहीं किया जा सका।';

  @override
  String deleteOrderSuccessSnack(String balance) {
    return 'ऑर्डर रद्द किया गया। जमा शेष $balance।';
  }

  @override
  String depositReturnSnackApplied(String applied, String balance) {
    return 'जमा से $applied लागू; शेष अब $balance।';
  }

  @override
  String depositReturnSnackDue(String applied, String due) {
    return 'जमा से $applied लागू; शेष देय $due।';
  }

  @override
  String depositReturnSnackNoDeposit(String total) {
    return 'वापस किया गया। कुल $total नकद देय।';
  }

  @override
  String get returnSelectedAction => 'चयनित वापस करें';

  @override
  String get returnAllAction => 'सभी वापस करें';

  @override
  String get returnByQuantityHint => 'प्रत्येक वस्तु के लिए वापसी संख्या चुनें';

  @override
  String skuIssuedReturnedRemaining(int issued, int returned, int remaining) {
    return 'जारी $issued · वापस $returned · अभी बाहर $remaining';
  }

  @override
  String get returnQtyLabel => 'वापसी संख्या';

  @override
  String get markRemainingLostAction => 'बाकी खोया चिह्नित करें';

  @override
  String get markSelectedLostAction => 'चयनित खोया चिह्नित करें';

  @override
  String get confirmMarkLostTitle => 'इकाइयाँ खोई चिह्नित करें?';

  @override
  String confirmMarkLostBody(int count) {
    return '$count इकाई(याँ) बिना स्टॉक वापस किए बंद करें। अगर कुछ अभी बाहर है तो ऑर्डर खुला रहेगा।';
  }

  @override
  String get confirmMarkLostAction => 'खोया चिह्नित करें';

  @override
  String unitsLostSnack(int count) {
    return '$count इकाई(याँ) खोई चिह्नित।';
  }

  @override
  String get lineLostLabel => 'खोया';

  @override
  String get lostLinesHeading => 'खोया';

  @override
  String get pickUnitsToReturn => 'वापसी के लिए इकाइयाँ चुनें';

  @override
  String get returnedLinesHeading => 'वापस हुए';

  @override
  String get lineReturnedLabel => 'वापस';

  @override
  String get lineOpenLabel => 'बाहर';

  @override
  String partialReturnSnack(int count) {
    return '$count वस्तु वापस। किराया अभी सक्रिय है।';
  }

  @override
  String get noLinesSelected => 'वापसी के लिए कम से कम एक वस्तु चुनें।';

  @override
  String linesOpenCount(int open, int total) {
    return '$total में से $open अभी बाहर';
  }

  @override
  String lineChargePreview(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get clearFilter => 'साफ़ करें';

  @override
  String showingFilter(String label) {
    return 'दिखा रहा है: $label';
  }

  @override
  String get needsAttentionTitle => 'ध्यान दें';

  @override
  String get needsAttentionEmptySubtitle =>
      'आज देय और अतिदेय ऑर्डर यहाँ दिखेंगे।';

  @override
  String get recentActivityTitle => 'हाल की गतिविधि';

  @override
  String get recentActivityEmpty => 'अभी कोई हालिया ऑर्डर या वापसी नहीं।';

  @override
  String get homeFilterEmptyTitle => 'कोई मिलान नहीं';

  @override
  String homeFilterEmptyRentalsSubtitle(String label) {
    return 'अभी कोई ऑर्डर $label से मेल नहीं खाता।';
  }

  @override
  String get homeFilterEmptyResourcesSubtitle =>
      'अभी कोई संसाधन उपलब्ध इकाइयों के साथ नहीं।';

  @override
  String get customizeHomeTitle => 'होम अनुकूलित करें';

  @override
  String get customizeHomeSubtitle => 'होम मॉड्यूल दिखाएँ या छिपाएँ।';

  @override
  String get customizeHomeIntro =>
      'खोज हमेशा चालू रहती है। होम को फोकस्ड रखने के लिए अन्य मॉड्यूल टॉगल करें।';

  @override
  String get enabledResourceTypesTitle => 'सक्षम संसाधन प्रकार';

  @override
  String get enabledResourceTypesSubtitle =>
      'नया ऑर्डर → अधिक विकल्प में दिखने वाले प्रकार चुनें।';

  @override
  String get enabledResourceTypesIntro =>
      'नए ऑर्डर की पूर्ति (किराया / बिक्री / जॉब) के लिए प्रकार टॉगल करें। टेम्पलेट आइटम आयात करने पर प्रकार इस सूची में मर्ज होते हैं। टेम्पलेट का होम लेआउट लागू करने पर यह सूची टेम्पलेट के सेट से बदल जाती है।';

  @override
  String get enabledResourceTypesKeepOne => 'कम से कम एक प्रकार सक्षम रखें।';

  @override
  String get moduleSearch => 'खोज';

  @override
  String get moduleSearchLocked => 'हमेशा चालू';

  @override
  String get moduleKpis => 'स्थिति चिप्स';

  @override
  String get moduleKpisSubtitle =>
      'कॉम्पैक्ट चिप्स; टैप पर फ़िल्टर के साथ ऑर्डर या संसाधन खोलता है';

  @override
  String get moduleFilterResults => 'फ़िल्टर परिणाम';

  @override
  String get moduleFilterResultsSubtitle =>
      'होम फ़िल्टर सेट होने पर चिप्स के नीचे वैकल्पिक सूची';

  @override
  String get moduleNeedsAttention => 'ध्यान दें';

  @override
  String get moduleNeedsAttentionSubtitle => 'आज देय और अतिदेय ऑर्डर';

  @override
  String get modulePendingJobs => 'लंबित जॉब';

  @override
  String get modulePendingJobsSubtitle => 'अधूरे जॉब लाइन वाले खुले ऑर्डर';

  @override
  String get pendingJobsTitle => 'लंबित जॉब';

  @override
  String get pendingJobsEmptySubtitle => 'अभी कोई खुली जॉब लाइन नहीं।';

  @override
  String get moduleQuickActions => 'त्वरित कार्रवाई';

  @override
  String get moduleQuickActionsSubtitle => 'नया ऑर्डर, वापसी, संसाधन जोड़ें';

  @override
  String get moduleRecentActivity => 'हाल की गतिविधि';

  @override
  String get moduleRecentActivitySubtitle => 'नवीनतम ऑर्डर और वापसी';

  @override
  String get moduleSuggestions => 'AI सुझाव';

  @override
  String get moduleSuggestionsSubtitle => 'वैकल्पिक बीटा सुझाव';

  @override
  String minMeaningfulTextError(int min) {
    return 'कम से कम $min अक्षर दर्ज करें।';
  }

  @override
  String get searchCustomersHint => 'नाम या फ़ोन से खोजें';

  @override
  String get searchNoResults => 'कोई मिलान नहीं';

  @override
  String get dueDateOptionalLabel => 'देय तिथि वैकल्पिक';

  @override
  String get dueDateOptionalSubtitle =>
      'निश्चित वापसी तिथि के बिना जारी करने की अनुमति दें (वापसी तक शुल्क बढ़ता रहेगा)।';

  @override
  String get allowsDynamicPricingLabel => 'गतिशील मूल्य अनुमति दें';

  @override
  String get allowsDynamicPricingSubtitle =>
      'नए ऑर्डर पर इस आइटम की दर बदली जा सकती है। कैटलॉग बदलाव केवल नए ऑर्डर पर लागू होते हैं।';

  @override
  String get orderLineRateLabel => 'इस ऑर्डर की दर (₹)';

  @override
  String get orderLineRateHint => 'इस किराए के लिए कैटलॉग दर बदली जा सकती है';

  @override
  String get openEndedDurationHint =>
      'चयनित सभी वस्तुएँ खुली अवधि की अनुमति देती हैं। अवधि दर्ज करें, या देय तिथि के बिना जारी रखें।';

  @override
  String get openEndedLabel => 'खुली अवधि';

  @override
  String get reviewOpenEndedLabel => 'देय: खुली अवधि (वापसी तक बढ़ता रहेगा)';

  @override
  String rentalAmountOpenEnded(String amount) {
    return 'खुली अवधि · $amount';
  }

  @override
  String get accruedAmountHint => 'अब तक अर्जित';

  @override
  String get balanceAdvanceLabel => 'अग्रिम';

  @override
  String get balancePendingLabel => 'लंबित';

  @override
  String get balanceCreditLabel => 'जमा शेष';

  @override
  String get balanceNetLabel => 'नेट';

  @override
  String get balancesAsOfTodayHeading => 'आज तक के शेष';

  @override
  String balanceOpenItemsCount(int count) {
    return '$count वस्तु बाहर';
  }

  @override
  String get orderStatusOpen => 'खुला';

  @override
  String get orderStatusCompleted => 'पूर्ण';

  @override
  String get orderStatusCancelled => 'रद्द';

  @override
  String get requiresUnitIdentityLabel => 'यूनिट नाम/आईडी आवश्यक';

  @override
  String get requiresUnitIdentitySubtitle =>
      'मूल श्रेणी (जैसे उपन्यास) के लिए चालू। व्यक्तिगत वस्तुओं के लिए बंद जिनका एक कैटलॉग नाम साझा है।';

  @override
  String get quantityLabel => 'मात्रा';

  @override
  String labelUnitHeading(String name, int index) {
    return '$name #$index';
  }

  @override
  String get labelsAutoAssignedHint =>
      'व्यक्तिगत वस्तुओं को कैटलॉग नाम और स्वतः छोटा कोड मिलता है।';

  @override
  String get workflowStatusHeading => 'कार्यप्रवाह स्थिति';

  @override
  String get workflowAdvanceAction => 'आगे बढ़ाएँ';

  @override
  String get workflowPickStatusAction => 'स्थिति चुनें';

  @override
  String get workflowStatusTerminalHint => 'इस पाइपलाइन के लिए ऑर्डर पूर्ण।';

  @override
  String get addOrderLineAction => 'पंक्ति जोड़ें';

  @override
  String get removeOrderLineAction => 'पंक्ति हटाएँ';

  @override
  String get selectResourceItemLabel => 'संसाधन';

  @override
  String orderLineHeading(int number) {
    return 'पंक्ति $number';
  }

  @override
  String orderTotalLabel(String amount) {
    return 'ऑर्डर कुल: $amount';
  }

  @override
  String get orderSummaryHeading => 'ऑर्डर सारांश';

  @override
  String orderSummaryQuantity(int quantity) {
    return 'मात्रा $quantity';
  }

  @override
  String orderSummaryUnitCharge(String amount) {
    return 'इकाई $amount';
  }

  @override
  String get moreOptions => 'और विकल्प';

  @override
  String get addUnitLabelsAction => 'यूनिट लेबल जोड़ें';

  @override
  String get itemKindRentalLabel => 'किराया';

  @override
  String get itemKindSaleLabel => 'बिक्री';

  @override
  String get itemKindServiceLabel => 'सेवा';

  @override
  String get itemKindJobLabel => 'जॉब';

  @override
  String get itemKindSubscriptionLabel => 'सदस्यता योजना';

  @override
  String get itemKindMembershipLabel => 'सदस्यता';

  @override
  String get itemKindLoanLabel => 'ऋण';

  @override
  String get itemKindFinancialLabel => 'वित्तीय';

  @override
  String get itemKindCustomLabel => 'कस्टम';

  @override
  String get itemKindSaleBadge => 'बिक्री';

  @override
  String get itemKindServiceBadge => 'सेवा';

  @override
  String get itemKindJobBadge => 'जॉब';

  @override
  String get itemKindSubscriptionBadge => 'सदस्यता योजना';

  @override
  String get itemKindMembershipBadge => 'सदस्यता';

  @override
  String get itemKindLoanBadge => 'ऋण';

  @override
  String get itemKindFinancialBadge => 'वित्तीय';

  @override
  String get itemKindCustomBadge => 'कस्टम';

  @override
  String get lineFulfillmentRent => 'किराया';

  @override
  String get lineFulfillmentSell => 'बेचें';

  @override
  String get lineFulfillmentJob => 'जॉब';

  @override
  String get saleAmountLabel => 'बिक्री राशि';

  @override
  String get saleAmountHint => 'राशि रुपये में';

  @override
  String get jobAmountLabel => 'जॉब शुल्क';

  @override
  String get jobAmountHint => 'राशि रुपये में';

  @override
  String get soldLineBadge => 'बेचा गया';

  @override
  String get completedJobLineBadge => 'पूर्ण';

  @override
  String get selectLinesToComplete => 'पूर्ण करने के लिए जॉब लाइन चुनें';

  @override
  String get markCompleteAllAction => 'सभी पूर्ण करें';

  @override
  String get markCompleteSelectedAction => 'पूर्ण करें';

  @override
  String get confirmCompleteJobsTitle => 'जॉब पूर्ण करें?';

  @override
  String confirmCompleteJobsBody(int count) {
    return '$count जॉब लाइन बंद करें। स्टॉक वापस नहीं होगा।';
  }

  @override
  String get jobsCompletedSnack => 'जॉब पूर्ण चिह्नित';

  @override
  String get orderNotesHeading => 'नोट्स';

  @override
  String get addOrderNoteAction => 'नोट जोड़ें';

  @override
  String get orderNoteBodyLabel => 'नोट';

  @override
  String get orderNoteBodyHint => 'शर्तें, माप, या अन्य विवरण';

  @override
  String get orderNoteKindLabel => 'प्रकार';

  @override
  String get orderNoteKindGeneral => 'सामान्य';

  @override
  String get orderNoteKindTerms => 'शर्तें';

  @override
  String get orderNoteKindMeasurement => 'माप';

  @override
  String get orderNoteLineLabel => 'पंक्ति से जोड़ें';

  @override
  String get orderNoteWholeOrder => 'पूरा ऑर्डर';

  @override
  String get orderNotesEmpty => 'अभी कोई नोट नहीं।';

  @override
  String get orderNoteAddedSnack => 'नोट जोड़ा गया';

  @override
  String get orderBillAmountLabel => 'बिल';

  @override
  String get orderDepositShortLabel => 'अग्रिम';

  @override
  String get ordersFilterAll => 'सभी';

  @override
  String get ordersFilterOpen => 'खुला';

  @override
  String get ordersFilterCompleted => 'पूर्ण';

  @override
  String get ordersFilterPendingJobs => 'लंबित जॉब';

  @override
  String get searchOrdersHint => 'पार्टी, आईडी या आइटम से खोजें';

  @override
  String inventoryStockMeta(String category, int available, int total) {
    return '$category · $available/$total';
  }

  @override
  String get moneyLabelBase => 'आधार';

  @override
  String get moneyLabelLate => 'विलंब शुल्क';

  @override
  String get moneyLabelTotal => 'कुल';

  @override
  String get moneyLabelDeposit => 'अग्रिम';

  @override
  String get moneyLabelWillApply => 'लागू होगा';

  @override
  String get moneyLabelRemainingDue => 'शेष देय';

  @override
  String get moneyLabelLeftover => 'बचा अग्रिम';

  @override
  String get moneyLabelNetDue => 'नेट देय';

  @override
  String get reportWhatsAppGateBanner =>
      'रिपोर्ट शेयर करने के लिए More में अपना WhatsApp नंबर सेट करें।';

  @override
  String get reportConfigureWhatsAppAction => 'WhatsApp सेट करें';

  @override
  String get timelineEmpty => 'अभी कोई किराया इवेंट नहीं।';

  @override
  String get timelineTitleOrderOpened => 'ऑर्डर खोला गया';

  @override
  String get timelineTitleReplacementOpened => 'प्रतिस्थापन खोला गया';

  @override
  String get timelineTitleSaleCompleted => 'बिक्री पूर्ण';

  @override
  String get timelineTitleJobOpened => 'जॉब खोला गया';

  @override
  String get timelineTitleReturned => 'वापस किया';

  @override
  String get timelineTitlePartialReturn => 'आंशिक वापसी';

  @override
  String get timelineTitleUnitsLost => 'इकाइयाँ खोईं';

  @override
  String get timelineTitleJobsCompleted => 'जॉब पूर्ण';

  @override
  String get timelineTitleJobCompleted => 'जॉब पूर्ण हुआ';

  @override
  String get timelineTitleOrderCancelled => 'ऑर्डर रद्द';

  @override
  String get timelineTitleNoteAdded => 'नोट जोड़ा गया';

  @override
  String get timelineTitleDueToday => 'आज देय';

  @override
  String get timelineTitleRentalOpened => 'किराया खोला गया';

  @override
  String get timelineTitleStatusChanged => 'स्थिति बदली';

  @override
  String get timelineTitleDueExtended => 'देय बढ़ाया';

  @override
  String get timelineTitleAutoVacated => 'स्वतः खाली';

  @override
  String get timelineTitlePaymentReceived => 'भुगतान प्राप्त';

  @override
  String get timelineSubtitleCreatedOrderFlow =>
      'फ़ोन-फ़र्स्ट ऑर्डर फ़्लो से बनाया गया।';

  @override
  String get timelineSubtitleCreatedOrderFlowSale =>
      'फ़ोन-फ़र्स्ट ऑर्डर फ़्लो से बनाया गया (बिक्री)।';

  @override
  String get timelineSubtitleCreatedOrderFlowJob =>
      'फ़ोन-फ़र्स्ट ऑर्डर फ़्लो से बनाया गया (जॉब)।';

  @override
  String get timelineSubtitleCreatedOrderFlowMixed =>
      'फ़ोन-फ़र्स्ट ऑर्डर फ़्लो से बनाया गया (मिश्रित)।';

  @override
  String timelineSubtitleReplacementFor(String orderId) {
    return '$orderId का प्रतिस्थापन।';
  }

  @override
  String timelineSubtitlePaymentReceived(
    String received,
    String sell,
    String advance,
  ) {
    return 'प्राप्त $received · बिक्री $sell · अग्रिम $advance';
  }

  @override
  String get commercialStepHeading => 'भुगतान और सिक्योरिटी';

  @override
  String get commercialStepSubtitle =>
      'इस कार्ट के लिए जो ज़रूरी है वही लें। वैकल्पिक फ़ील्ड छोड़ सकते हैं और बाद में ऑर्डर विवरण से भुगतान कर सकते हैं।';

  @override
  String get commercialStepPay => 'भुगतान';

  @override
  String get commercialStepAdvance => 'अग्रिम';

  @override
  String get commercialStepSecurity => 'सिक्योरिटी';

  @override
  String get commercialStepMembershipRequired => 'सदस्यता आवश्यक';

  @override
  String get commercialMinPayLabel => 'अभी न्यूनतम देय';

  @override
  String get commercialSecurityRequiredHelper =>
      'ऑर्डर जारी करने से पहले आवश्यक';

  @override
  String get commercialSubscriptionHint =>
      'इस ऑर्डर पर कवरिंग सदस्यता जोड़ें, या जहाँ अनुमति हो वहाँ सिक्योरिटी लें।';

  @override
  String get commercialSubscriptionSatisfied =>
      'इस ग्राहक की सदस्यता सक्रिय है।';

  @override
  String get subscriptionTierNone => 'कोई नहीं';

  @override
  String get subscriptionTierBasic => 'बेसिक';

  @override
  String get subscriptionTierStandard => 'स्टैंडर्ड';

  @override
  String get subscriptionTierPro => 'प्रो';

  @override
  String get subscriptionTierPremium => 'प्रीमियम';

  @override
  String get subscriptionPeriodDay => 'दिन';

  @override
  String get subscriptionPeriodWeek => 'सप्ताह';

  @override
  String get subscriptionPeriodMonth => 'महीना';

  @override
  String get subscriptionPeriodYear => 'वर्ष';

  @override
  String get subscriptionSkuTierLabel => 'सदस्यता टियर';

  @override
  String get subscriptionPeriodUnitLabel => 'अवधि इकाई';

  @override
  String get subscriptionPeriodCountLabel => 'अवधि संख्या';

  @override
  String get minSubscriptionTierLabel => 'सदस्यता आवश्यक';

  @override
  String get minSubscriptionTierHelper =>
      'यह संसाधन जारी करने के लिए न्यूनतम ग्राहक टियर। कोई नहीं = बिना गेट।';

  @override
  String get catalogResourceTypeLabel => 'संसाधन प्रकार';

  @override
  String subscriptionChipOk(String tier, String date) =>
      '$tier $date तक — जारी कर सकते हैं';

  @override
  String subscriptionChipUncovered(String tier) =>
      'इन वस्तुओं के लिए ग्राहक को $tier (या उससे ऊपर) चाहिए।';

  @override
  String get subscriptionUpsellLabel => 'इस ऑर्डर में सदस्यता जोड़ें';

  @override
  String get subscriptionNamedCustomerRequired =>
      'सदस्यता के लिए फ़ोन वाला नामित ग्राहक आवश्यक है।';

  @override
  String get subscriptionHistoryHeading => 'सदस्यताएँ';

  @override
  String get subscriptionNoneActive => 'कोई सक्रिय सदस्यता नहीं';

  @override
  String get subscriptionStatusCancelled => 'रद्द';

  @override
  String get subscriptionStatusExpired => 'समाप्त';

  @override
  String customerSubscriptionMeta(String tier, String date) => '$tier · $date';

  @override
  String subscriptionUntilLabel(String tier, String date) =>
      '$tier $date तक';

  @override
  String get orderPaymentTitle => 'भुगतान';

  @override
  String get orderPaymentHeading => 'भुगतान लें';

  @override
  String get orderPaymentSubtitle =>
      'बेची गई वस्तुएँ अभी देय हैं। सिक्योरिटी ऑर्डर अग्रिम के रूप में रखी जाती है और वापसी पर लगाई जाती है।';

  @override
  String get paymentMinSoldLabel => 'न्यूनतम भुगतान (बेची वस्तुएँ)';

  @override
  String get paymentSellPaidLabel => 'बिक्री भुगतान';

  @override
  String get paymentSellDiscountLabel => 'बिक्री छूट';

  @override
  String get paymentSellOutstandingLabel => 'बिक्री अभी बाकी';

  @override
  String get paymentSecurityLabel => 'किराया सिक्योरिटी / अग्रिम (₹)';

  @override
  String get paymentSecurityHint => 'कैटलॉग से सुझाव; आवश्यकतानुसार बदलें';

  @override
  String get paymentSecurityHelper => 'वापसी तक इस ऑर्डर पर रखी जाएगी';

  @override
  String get paymentAmountReceivedLabel => 'प्राप्त राशि (₹)';

  @override
  String get paymentAmountReceivedHint => 'अभी नकद प्राप्त';

  @override
  String get paymentTreatExcessAsDiscount => 'अतिरिक्त को छूट मानें';

  @override
  String get paymentTreatExcessAsDiscountHint =>
      'अग्रिम को ऊपर दी सिक्योरिटी तक सीमित रखें; अतिरिक्त न रखें';

  @override
  String get paymentAllocationPreview => 'आवंटन पूर्वावलोकन';

  @override
  String get paymentPreviewSellCovered => 'बेची वस्तुओं की ओर';

  @override
  String get paymentPreviewSellDiscount => 'बिक्री छूट';

  @override
  String get paymentPreviewAdvance => 'रखी जाने वाली अग्रिम';

  @override
  String get paymentPreviewRemainingSell => 'इस भुगतान के बाद बिक्री शेष';

  @override
  String get paymentConfirmAction => 'भुगतान पुष्टि करें';

  @override
  String get paymentReferenceLabel => 'भुगतान ref';

  @override
  String get paymentReferenceHint => 'रसीद या UPI id';

  @override
  String get paymentReferenceRequired => 'भुगतान ref आवश्यक है';

  @override
  String timelinePaymentRef(String ref) {
    return 'Ref $ref';
  }

  @override
  String get paymentPayAction => 'भुगतान करें';

  @override
  String get paymentAddAdvanceAction => 'अग्रिम जोड़ें';

  @override
  String get unpaidSellBadge => 'बकाया';

  @override
  String get timelineSubtitleAllLinesReturned =>
      'सभी पंक्तियाँ स्टाफ़ द्वारा वापस की गईं।';

  @override
  String get timelineSubtitleAllLinesReturnedLate =>
      'सभी पंक्तियाँ वापस। विलंब शुल्क लागू।';

  @override
  String timelineSubtitlePartialReturnLines(int returned, int total) {
    return '$total में से $returned पंक्तियाँ वापस।';
  }

  @override
  String timelineSubtitlePartialReturnQty(
    String summary,
    int returned,
    int total,
  ) {
    return 'वापस: $summary ($total में से $returned पंक्तियाँ)।';
  }

  @override
  String timelineSubtitleUnitsLostQty(String summary, int count) {
    return 'खोया चिह्नित: $summary ($count इकाइयाँ)।';
  }

  @override
  String get timelineSubtitleAllJobsComplete =>
      'सभी जॉब पंक्तियाँ पूर्ण चिह्नित।';

  @override
  String timelineSubtitleJobsCompletedCount(int count) {
    return '$count जॉब पंक्ति(याँ) पूर्ण।';
  }

  @override
  String timelineSubtitleCancelSettlement(String kept, String returned) {
    return 'रखा $kept; वापस $returned।';
  }

  @override
  String timelineSubtitleNoteBody(String kind, String body) {
    return '$kind: $body';
  }

  @override
  String get timelineSubtitleAutoReminder => 'स्वतः रिमाइंडर बनाया गया।';

  @override
  String get timelineSubtitleCheckedOutByStaff => '1 वस्तु स्टाफ़ द्वारा जारी।';

  @override
  String get timelineSubtitleClosedAtCounter => 'काउंटर पर बंद।';

  @override
  String get timelineSubtitleManualWalkIn => 'मैनुअल वॉक-इन चेकआउट।';

  @override
  String timelineSubtitleStatusChanged(String from, String to) {
    return '$from → $to';
  }

  @override
  String timelineSubtitleDueExtended(String from, String to) {
    return 'देय $from → $to किया गया।';
  }

  @override
  String timelineSubtitleDueExtendedSet(String to) {
    return 'देय $to पर सेट।';
  }

  @override
  String get timelineSubtitleDueExtendedGeneric => 'देय तिथि बढ़ाई गई।';

  @override
  String timelineSubtitleAutoVacated(String summary, int count) {
    return 'स्वतः खाली: $summary ($count इकाइयाँ)।';
  }

  @override
  String get timelineSubtitleAutoVacatedGeneric =>
      'अतिदेय खुली इकाइयाँ स्वतः खाली की गईं।';

  @override
  String timelineSubtitleDiscountBit(String amount) {
    return 'छूट $amount।';
  }

  @override
  String timelineSubtitleNoteBit(String note) {
    return 'नोट: $note';
  }

  @override
  String reportHeader(String appName) {
    return '$appName रिपोर्ट';
  }

  @override
  String reportActiveCount(int count) {
    return 'सक्रिय: $count';
  }

  @override
  String reportOpenedCount(int count) {
    return 'खोले: $count';
  }

  @override
  String reportReturnedCount(int count) {
    return 'वापस: $count';
  }

  @override
  String reportOverdueCount(int count) {
    return 'अतिदेय: $count';
  }

  @override
  String reportChargesOpened(String amount) {
    return 'शुल्क (रेंज में खोले): $amount';
  }

  @override
  String reportChargesReturned(String amount) {
    return 'शुल्क (रेंज में वापस): $amount';
  }

  @override
  String reportDepositAppliedRange(String amount) {
    return 'अग्रिम लागू (रेंज में वापस): $amount';
  }

  @override
  String reportBalanceDueReturned(String amount) {
    return 'अग्रिम के बाद शेष देय (वापस): $amount';
  }

  @override
  String get reportNoRentalsInRange => '(रेंज में कोई किराया नहीं)';

  @override
  String get reportNoResources => '(कोई संसाधन नहीं)';

  @override
  String reportCustomerWithDeposit(String header, String amount) {
    return '$header | अग्रिम $amount';
  }

  @override
  String get reportStatusReturnedBit => '[वापस]';

  @override
  String get reportStatusSoldBit => '[बिका]';

  @override
  String get reportStatusCompletedBit => '[पूर्ण]';

  @override
  String reportLinesPartialBit(int open, int returned) {
    return ' | पंक्तियाँ $open खुली/$returned वापस';
  }

  @override
  String reportDepositDueBit(String deposit, String due) {
    return ' | अग्रिम $deposit | देय $due';
  }

  @override
  String get reportOpenEnded => 'खुला-समाप्त';

  @override
  String reportDueDateBit(String date) {
    return 'देय $date';
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
    return '• $name: किराए $rented× | बाहर $out | उपलब्ध $available/$total | $billing $rate';
  }

  @override
  String reportTruncatedSuffix(String appName) {
    return '\n…(काटा गया — पूरी रिपोर्ट के लिए $appName खोलें)';
  }

  @override
  String get loansTitle => 'कर्ज';

  @override
  String get loanCreateTitle => 'नया कर्ज';

  @override
  String get loanCreateAction => 'नया कर्ज';

  @override
  String get loanDetailTitle => 'कर्ज कैलकुलेटर';

  @override
  String get loanNotFound => 'कर्ज नहीं मिला';

  @override
  String get loanStatusPending => 'लंबित';

  @override
  String get loanStatusClosed => 'बंद';

  @override
  String get loanStatusCancelled => 'रद्द';

  @override
  String get loansPendingEmpty => 'कोई लंबित कर्ज नहीं।';

  @override
  String get loansClosedEmpty => 'अभी कोई बंद कर्ज नहीं।';

  @override
  String get loanDirectionLabel => 'दिशा';

  @override
  String get loanDirectionGiven => 'दिया (उधार दिया)';

  @override
  String get loanDirectionTaken => 'लिया (उधार लिया)';

  @override
  String get loanCustomerLabel => 'ग्राहक';

  @override
  String get loanPrincipalLabel => 'मूलधन';

  @override
  String get loanOriginalPrincipalLabel => 'प्रारंभिक मूलधन';

  @override
  String get loanPrincipalRequired => 'मूलधन राशि दर्ज करें';

  @override
  String get loanMoneyGivenOnLabel => 'पैसे दिए गए दिन';

  @override
  String get loanDueOptionalLabel => 'देय / समाप्ति (वैकल्पिक)';

  @override
  String get loanDueNone => 'कोई देय तिथि नहीं';

  @override
  String get loanCalculationFrequencyLabel => 'ब्याज गणना';

  @override
  String get loanRateDaily => 'दैनिक';

  @override
  String get loanInterestAccrualLabel => 'ब्याज संचय';

  @override
  String get loanInterestAccrualCalendar => 'कैलेंडर अवधि';

  @override
  String get loanCapitalizationPolicyLabel => 'पूंजीकरण';

  @override
  String get loanCapPolicyNever => 'कभी नहीं';

  @override
  String get loanCapPolicyOnPayment => 'भुगतान पर';

  @override
  String get loanCapPolicyOnScheduledCycle => 'निर्धारित चक्र पर';

  @override
  String get loanCapPolicyOnBalanceDirectionChange => 'दिशा बदलने पर';

  @override
  String get loanCapPolicyOnLoanClosure => 'बंद होने पर';

  @override
  String get loanCapPolicyManual => 'मैन्युअल';

  @override
  String get loanCapitalizationCycleLabel => 'पूंजीकरण चक्र';

  @override
  String get loanCapCycleMonthly => 'मासिक';

  @override
  String get loanCapCycleQuarterly => 'तिमाही';

  @override
  String get loanCapCycleYearly => 'वार्षिक';

  @override
  String get loanCapitalizeInterestAction => 'ब्याज पूंजीकृत करें';

  @override
  String get loanCapitalizeInterestSnack => 'ब्याज मूलधन में जोड़ा गया';

  @override
  String get loanCapitalizeNothingSnack =>
      'पूंजीकृत करने के लिए अवैतनिक ब्याज नहीं';

  @override
  String get loanUnpaidInterestLabel => 'अवैतनिक ब्याज';

  @override
  String get loanPrepaymentAllocationLabel => 'चुकौती लागू होती है';

  @override
  String get loanPrepaymentInterestFirst => 'पहले ब्याज';

  @override
  String get loanPrepaymentPrincipalOnly => 'केवल मूलधन';

  @override
  String get loanPrepaymentAllocationHint =>
      'पहले ब्याज अवैतनिक ब्याज चुकाता है, फिर मूलधन। केवल मूलधन मूलधन घटाता है; अवैतनिक ब्याज अलग से चुकाने तक बना रहता है।';

  @override
  String get loanRatePercentLabel => 'दर';

  @override
  String get loanRatePeriodLabel => 'अवधि';

  @override
  String get loanRateMonthly => 'मासिक';

  @override
  String get loanRateYearly => 'वार्षिक';

  @override
  String get loanCapPolicyHintNever =>
      'मूलधन स्थिर रहता है; अवैतनिक ब्याज अलग बढ़ता है। बकाया = मूलधन + अवैतनिक।';

  @override
  String get loanCapPolicyHintOnPayment =>
      'प्रत्येक चुकौती से ठीक पहले अवैतनिक ब्याज मूलधन में जुड़ता है।';

  @override
  String get loanCapPolicyHintOnScheduledCycle =>
      'प्रत्येक पूंजीकरण चक्र की वर्षगाँठ पर अवैतनिक ब्याज मूलधन में जुड़ता है।';

  @override
  String get loanCapPolicyHintOnBalanceDirectionChange =>
      'बकाया देय से क्रेडिट (या उल्टा) हो जाने से पहले अवैतनिक ब्याज मूलधन में जुड़ता है।';

  @override
  String get loanCapPolicyHintOnLoanClosure =>
      'कर्ज बंद होने पर अवैतनिक ब्याज मूलधन में जुड़ता है।';

  @override
  String get loanCapPolicyHintManual =>
      'अवैतनिक ब्याज केवल तब मूलधन में जुड़ता है जब आप ब्याज पूंजीकृत करें दबाएँ।';

  @override
  String get loanRateInvalid => 'मान्य दर दर्ज करें';

  @override
  String get loanNoteOptionalLabel => 'नोट (वैकल्पिक)';

  @override
  String get loanPaymentReferenceLabel => 'भुगतान ref';

  @override
  String get loanSaving => 'सहेजा जा रहा है…';

  @override
  String get loanPendingNowLabel => 'अभी लंबित';

  @override
  String get loanOverpaidNowLabel => 'अभी अधिक भुगतान';

  @override
  String get loanInterestToDateLabel => 'अब तक का ब्याज';

  @override
  String get loanReverseInterestToDateLabel => 'अब तक का उल्टा ब्याज';

  @override
  String get loanPaidLabel => 'भुगतान';

  @override
  String get loanAdjustmentsLabel => 'समायोजन';

  @override
  String get loanTimelineHeading => 'समयरेखा';

  @override
  String get loanAddPayment => 'भुगतान जोड़ें';

  @override
  String get loanAddPrincipal => 'मूलधन बढ़ाएँ';

  @override
  String get loanAddAdjustment => 'समायोजन जोड़ें';

  @override
  String get loanEntryDateLabel => 'तारीख';

  @override
  String get loanFlowRepayment => 'चुकौती';

  @override
  String get loanFlowAddPrincipal => 'मूलधन बढ़ाएँ';

  @override
  String get loanFlowRepaymentGiven => 'पार्टी से प्राप्त';

  @override
  String get loanFlowRepaymentTaken => 'वापस चुकाया';

  @override
  String get loanFlowDisbursementGiven => 'और दिया';

  @override
  String get loanFlowDisbursementTaken => 'और लिया';

  @override
  String get loanPaymentAmountLabel => 'राशि';

  @override
  String get loanAdjustmentAmountLabel => 'समायोजन राशि';

  @override
  String get loanAdjustmentHint =>
      'धनात्मक शेष माफ करता है; ऋणात्मक मूलधन बढ़ाता है';

  @override
  String get loanSaveEntry => 'सहेजें';

  @override
  String get loanEditPayment => 'भुगतान संपादित करें';

  @override
  String get loanEditDisbursement => 'मूलधन संपादित करें';

  @override
  String get loanEditEntryTooltip => 'प्रविष्टि संपादित करें';

  @override
  String get loanEntryUpdated => 'प्रविष्टि अपडेट की गई';

  @override
  String get loanDeleteEntry => 'प्रविष्टि हटाएँ';

  @override
  String get loanDeleteEntryConfirm =>
      'इस प्रविष्टि को कर्ज टाइमलाइन से हटाएँ?';

  @override
  String get loanEntryDeleted => 'प्रविष्टि हटाई गई';

  @override
  String get loanCancel => 'रद्द';

  @override
  String get loanKeepPending => 'लंबित रखें';

  @override
  String get loanKeepPendingHint =>
      'कर्ज तब तक खुला रहता है जब तक आप बंद नहीं करते।';

  @override
  String get loanMarkClosed => 'बंद करें';

  @override
  String get loanReopen => 'फिर खोलें';

  @override
  String get loanClosedSnack => 'कर्ज बंद किया गया';

  @override
  String get loanCloseWithPendingTitle => 'शेष के साथ बंद करें?';

  @override
  String loanCloseWithPendingBody(String amount) {
    return 'अभी भी $amount लंबित है। फिर भी बंद करें, या पहले समायोजन जोड़ें?';
  }

  @override
  String get loanEditSetupTooltip => 'कर्ज संपादित करें';

  @override
  String get loanEditSetupTitle => 'कर्ज संपादित करें';

  @override
  String loanSetupSummary(
    String start,
    String due,
    String rate,
    String period,
    String policy,
  ) {
    return 'शुरू $start · देय $due · $rate $period · $policy';
  }

  @override
  String loanPrepaymentSetupLabel(String mode) {
    return 'चुकौती: $mode';
  }

  @override
  String loanTimelineInterestCapitalized(String date, String amount) {
    return '$date — ब्याज पूंजीकृत $amount → मूलधन';
  }

  @override
  String loanTimelineInterestSegment(
    String principal,
    String from,
    String to,
    String amount,
  ) {
    return '$principal पर ब्याज ($from–$to) → $amount';
  }

  @override
  String loanTimelineReverseInterestSegment(
    String principal,
    String from,
    String to,
    String amount,
  ) {
    return 'क्रेडिट $principal पर उल्टा ब्याज ($from–$to) → $amount';
  }

  @override
  String loanTimelinePendingOverpaid(String date, String amount) {
    return '$date — अधिक भुगतान $amount';
  }

  @override
  String loanTimelinePayment(String date, String amount, String principal) {
    return '$date — चुकौती $amount → मूलधन $principal';
  }

  @override
  String loanTimelinePaymentSplit(
    String date,
    String amount,
    String interest,
    String principal,
  ) {
    return '$date — चुकौती $amount → ब्याज $interest, मूलधन $principal';
  }

  @override
  String loanTimelineDisbursement(String date, String amount) {
    return '$date — मूलधन जोड़ा $amount';
  }

  @override
  String loanTimelineAdjustment(String date, String amount) {
    return '$date — समायोजन $amount';
  }

  @override
  String loanTimelinePending(String date, String amount) {
    return '$date — लंबित $amount';
  }

  @override
  String get modulePendingLoans => 'लंबित कर्ज';

  @override
  String get modulePendingLoansSubtitle => 'अभी भी बकाया खुले नकद कर्ज';

  @override
  String get pendingLoansTitle => 'लंबित कर्ज';

  @override
  String get pendingLoansEmptySubtitle => 'अभी कोई लंबित कर्ज नहीं।';

  @override
  String get moduleDueLoans => 'देय कर्ज';

  @override
  String get moduleDueLoansSubtitle => 'देय तिथि पर या उसके बाद के लंबित कर्ज';

  @override
  String get dueLoansTitle => 'देय कर्ज';

  @override
  String get dueLoansEmptySubtitle => 'अभी कोई देय कर्ज नहीं।';

  @override
  String get customerLoansViewAll => 'सभी कर्ज देखें';

  @override
  String reportPendingLoansCount(int count) {
    return 'लंबित कर्ज: $count';
  }

  @override
  String get reportNoOutstandingLoans => 'कोई बकाया कर्ज नहीं।';

  @override
  String reportOutstandingLoansTotal(String amount, int count) {
    return 'कुल $amount — $count कर्ज';
  }
}
