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
  String get navRentals => 'किराए';

  @override
  String get navInventory => 'इन्वेंटरी';

  @override
  String get navCustomers => 'ग्राहक';

  @override
  String get navMore => 'और';

  @override
  String get actionSearch => 'खोजें';

  @override
  String get actionNewRental => 'नया किराया';

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
  String get actionAddInventory => 'इन्वेंटरी जोड़ें';

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
  String get noRentalsYetTitle => 'अभी कोई किराया नहीं';

  @override
  String get noRentalsYetSubtitle =>
      'अपना पहला लेन-देन बनाने के लिए नया किराया शुरू करें।';

  @override
  String get unknownCustomer => 'अज्ञात ग्राहक';

  @override
  String rentalDueSubtitle(String customerName, String date) {
    return '$customerName • देय $date';
  }

  @override
  String inventoryAvailableSubtitle(String category, int available, int total) {
    return '$category • $available/$total उपलब्ध';
  }

  @override
  String get customerTrusted => 'विश्वसनीय';

  @override
  String get customerStandard => 'सामान्य';

  @override
  String customerSubtitle(String phone, String tier) {
    return '$phone • $tier';
  }

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
  String get voiceSearchStubTitle => 'वॉइस खोज (स्टब)';

  @override
  String get voiceSearchStubSubtitle =>
      'इंटेंट-आधारित खोज कमांड के लिए प्लेसहोल्डर।';

  @override
  String get businessTemplatesTitle => 'व्यवसाय टेम्पलेट';

  @override
  String get businessTemplatesSubtitle =>
      'उद्योग के अनुसार स्टार्टर इन्वेंटरी आयात करें (मर्ज)।';

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
  String get shareAction => 'शेयर';

  @override
  String get extendPlaceholder => 'बढ़ाना एक प्लेसहोल्डर कार्रवाई है।';

  @override
  String get sharePlaceholder => 'शेयर एक प्लेसहोल्डर कार्रवाई है।';

  @override
  String get editInventoryTitle => 'इन्वेंटरी संपादित करें';

  @override
  String get inventoryDetailTitle => 'इन्वेंटरी विवरण';

  @override
  String get editTooltip => 'संपादित करें';

  @override
  String get itemNameLabel => 'वस्तु का नाम';

  @override
  String get categoryLabel => 'श्रेणी';

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
  String get nameCategoryRequired => 'नाम और श्रेणी आवश्यक हैं।';

  @override
  String get inventoryUpdated => 'इन्वेंटरी अपडेट हो गई।';

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
  String get recentRentals => 'हाल के किराए';

  @override
  String dueDate(String date) {
    return 'देय $date';
  }

  @override
  String returnedDate(String date) {
    return 'वापस $date';
  }

  @override
  String get searchHint => 'ग्राहक, किराया या इन्वेंटरी खोजें';

  @override
  String get searchSectionCustomers => 'ग्राहक';

  @override
  String get searchSectionCurrentRentals => 'वर्तमान किराए';

  @override
  String get searchSectionPreviousRentals => 'पिछले किराए';

  @override
  String get searchSectionInventory => 'इन्वेंटरी';

  @override
  String noMatchingSection(String section) {
    return 'कोई मिलान नहीं: $section';
  }

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
  String get existingCustomer => 'मौजूदा ग्राहक';

  @override
  String existingCustomerSubtitle(String phone) {
    return '$phone • मौजूदा ग्राहक';
  }

  @override
  String get customerNameNewLabel => 'ग्राहक का नाम (नया)';

  @override
  String get customerNameNewHint => 'केवल नए ग्राहक के लिए आवश्यक';

  @override
  String get selfKnownQuickPick => 'SELF Known';

  @override
  String get rentalNicknameLabel => 'इस किराये का उपनाम';

  @override
  String get rentalNicknameHint => 'वस्तुएँ कौन ले जा रहा है?';

  @override
  String get rentalNicknameRequired =>
      'SELF Known किराये के लिए उपनाम दर्ज करें।';

  @override
  String reviewNickname(String nickname, String customerName) {
    return 'उपनाम: $nickname · $customerName';
  }

  @override
  String rentalNicknameSubtitle(String customerName, String phone) {
    return '$customerName · $phone';
  }

  @override
  String rentalNicknameDueSubtitle(String nickname, String date) {
    return '$nickname • देय $date';
  }

  @override
  String get selectItems => 'वस्तुएँ चुनें';

  @override
  String itemAvailableCount(String category, int available) {
    return '$category • $available उपलब्ध';
  }

  @override
  String get labelInstancesHeading => 'प्रत्येक वस्तु का नाम दें';

  @override
  String get labelInstancesHint =>
      'उपन्यास/उपकरणों के लिए: इस प्रति का नाम और छोटा कोड दर्ज करें।';

  @override
  String get instanceNameLabel => 'उदाहरण नाम';

  @override
  String get instanceNameHint => 'जैसे हैरी पॉटर';

  @override
  String get shortCodeLabel => 'छोटा कोड';

  @override
  String get shortCodeHint => 'जैसे NOV-042';

  @override
  String get instanceLabelsRequired =>
      'प्रत्येक वस्तु के लिए उदाहरण नाम और छोटा कोड दर्ज करें।';

  @override
  String duplicateShortCode(String code) {
    return 'छोटा कोड $code पहले से किसी सक्रिय किराए पर उपयोग में है।';
  }

  @override
  String get inventoryInstancesNote =>
      'किराया जारी करते समय व्यक्तिगत प्रतियों का नाम और छोटा कोड दर्ज किया जाता है।';

  @override
  String get reviewHeading => 'समीक्षा';

  @override
  String reviewPhone(String phone) {
    return 'फ़ोन: $phone';
  }

  @override
  String reviewName(String name) {
    return 'नाम: $name';
  }

  @override
  String get reviewItemsLabel => 'वस्तुएँ:';

  @override
  String get back => 'वापस';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get confirmRental => 'किराया पुष्टि करें';

  @override
  String get noActiveRentalsTitle => 'कोई सक्रिय किराया नहीं';

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
      'एक उद्योग चुनें, फिर जोड़ने वाली स्टार्टर वस्तुएँ चुनें। समान नाम वाली मौजूदा वस्तुएँ बनी रहती हैं (मर्ज)।';

  @override
  String starterItemsCount(int count) {
    return '$count स्टार्टर वस्तुएँ';
  }

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
  String get adding => 'जोड़ा जा रहा है…';

  @override
  String get addSelectedToInventory => 'चयनित को इन्वेंटरी में जोड़ें';

  @override
  String templateImportResult(int added, int skipped) {
    return '$added वस्तुएँ जोड़ी गईं ($skipped पहले से मौजूद)';
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
  String get reportTypeInventoryWise => 'इन्वेंटरी-वार';

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
  String get pricingSectionTitle => 'किराया मूल्य';

  @override
  String get durationHeading => 'किराए की अवधि';

  @override
  String get durationHint => 'पहले चुनी गई वस्तु के बिलिंग मोड पर आधारित।';

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
  String chargeBaseLabel(String amount) {
    return 'आधार: $amount';
  }

  @override
  String chargeLateLabel(String amount) {
    return 'विलंब शुल्क: $amount';
  }

  @override
  String chargeTotalLabel(String amount) {
    return 'कुल: $amount';
  }

  @override
  String get reviewChargesLabel => 'शुल्क:';

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
  String get durationRequired => 'मान्य अवधि दर्ज करें (कम से कम 1)।';

  @override
  String get customEndRequired => 'आज या उसके बाद की वापसी तिथि चुनें।';

  @override
  String get depositBalanceLabel => 'जमा शेष';

  @override
  String depositBalanceAmount(String amount) {
    return 'जमा: $amount';
  }

  @override
  String get depositAddAction => 'जमा जोड़ें';

  @override
  String get depositRefundAction => 'वापसी';

  @override
  String get depositAmountLabel => 'राशि (₹)';

  @override
  String get depositAmountHint => 'जैसे 500';

  @override
  String get depositNoteLabel => 'नोट (वैकल्पिक)';

  @override
  String get depositNoteHint => 'कारण या संदर्भ';

  @override
  String get depositTopUpTitle => 'जमा जोड़ें';

  @override
  String get depositRefundTitle => 'जमा वापसी';

  @override
  String get depositConfirmTopUp => 'जोड़ें';

  @override
  String get depositConfirmRefund => 'वापसी';

  @override
  String get depositInvalidAmount => 'शून्य से अधिक राशि दर्ज करें।';

  @override
  String get depositRefundExceeds =>
      'वापसी वर्तमान जमा शेष से अधिक नहीं हो सकती।';

  @override
  String depositTopUpSuccess(String amount) {
    return 'जमा अपडेट होकर $amount हो गई।';
  }

  @override
  String depositRefundSuccess(String amount) {
    return 'वापसी हो गई। जमा अब $amount है।';
  }

  @override
  String get depositLedgerHeading => 'जमा इतिहास';

  @override
  String get depositLedgerEmpty => 'अभी कोई जमा गतिविधि नहीं।';

  @override
  String depositLedgerTopUp(String amount) {
    return 'टॉप-अप $amount';
  }

  @override
  String depositLedgerApply(String amount) {
    return 'वापसी पर लागू $amount';
  }

  @override
  String depositLedgerRefund(String amount) {
    return 'वापसी $amount';
  }

  @override
  String depositLedgerAdjust(String amount) {
    return 'समायोजन $amount';
  }

  @override
  String depositLedgerBalanceAfter(String amount) {
    return 'शेष $amount';
  }

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
  String depositNetDueLabel(String amount) {
    return 'नेट देय: $amount';
  }

  @override
  String get returnSettlementTitle => 'वापसी निपटान';

  @override
  String get confirmReturnAction => 'वापसी पुष्टि करें';

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
  String customerSubtitleWithDeposit(String phone, String tier, String amount) {
    return '$phone • $tier • जमा $amount';
  }

  @override
  String existingCustomerWithDeposit(String phone, String amount) {
    return '$phone • मौजूदा • जमा $amount';
  }

  @override
  String get returnSelectedAction => 'चयनित वापस करें';

  @override
  String get returnAllAction => 'सभी वापस करें';

  @override
  String get replaceLineAction => 'बदलें';

  @override
  String get selectLinesToReturn => 'वापसी के लिए पंक्तियाँ चुनें';

  @override
  String get openLinesHeading => 'बाहर';

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
  String get replaceFlowTitle => 'वस्तु बदलें';

  @override
  String get replaceSettlementIntro =>
      'पुरानी वस्तु का निपटान करें, फिर नया जारी करें।';

  @override
  String get replaceConfirmAction => 'बदलें और जारी करें';

  @override
  String replaceSuccessSnack(String newId, String balance) {
    return 'पुरानी पंक्ति निपटाई; नया $newId। जमा शेष $balance।';
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
  String get needsAttentionEmptyTitle => 'कुछ ध्यान देने योग्य नहीं';

  @override
  String get needsAttentionEmptySubtitle =>
      'आज देय और अतिदेय किराए यहाँ दिखेंगे।';

  @override
  String get recentActivityTitle => 'हाल की गतिविधि';

  @override
  String get recentActivityEmpty => 'अभी कोई हालिया किराया या वापसी नहीं।';

  @override
  String get homeFilterEmptyTitle => 'कोई मिलान नहीं';

  @override
  String homeFilterEmptyRentalsSubtitle(String label) {
    return 'अभी कोई किराया $label से मेल नहीं खाता।';
  }

  @override
  String get homeFilterEmptyInventorySubtitle =>
      'अभी कोई इन्वेंटरी उपलब्ध इकाइयों के साथ नहीं।';

  @override
  String get customizeHomeTitle => 'होम अनुकूलित करें';

  @override
  String get customizeHomeSubtitle => 'होम मॉड्यूल दिखाएँ या छिपाएँ।';

  @override
  String get customizeHomeIntro =>
      'खोज हमेशा चालू रहती है। होम को फोकस्ड रखने के लिए अन्य मॉड्यूल टॉगल करें।';

  @override
  String get moduleSearch => 'खोज';

  @override
  String get moduleSearchLocked => 'हमेशा चालू';

  @override
  String get moduleKpis => 'स्थिति कार्ड';

  @override
  String get moduleKpisSubtitle => 'सक्रिय, आज देय, अतिदेय, उपलब्ध';

  @override
  String get moduleFilterResults => 'फ़िल्टर परिणाम';

  @override
  String get moduleFilterResultsSubtitle =>
      'फ़िल्टर चुनने पर स्थिति कार्ड के नीचे सूची';

  @override
  String get moduleNeedsAttention => 'ध्यान दें';

  @override
  String get moduleNeedsAttentionSubtitle => 'आज देय और अतिदेय किराए';

  @override
  String get moduleQuickActions => 'त्वरित कार्रवाई';

  @override
  String get moduleQuickActionsSubtitle =>
      'नया किराया, वापसी, इन्वेंटरी जोड़ें';

  @override
  String get moduleRecentActivity => 'हाल की गतिविधि';

  @override
  String get moduleRecentActivitySubtitle => 'नवीनतम किराए और वापसी';

  @override
  String get moduleSuggestions => 'AI सुझाव';

  @override
  String get moduleSuggestionsSubtitle => 'वैकल्पिक बीटा सुझाव';

  @override
  String get applyHomeLayoutTitle => 'होम लेआउट लागू करें?';

  @override
  String get applyHomeLayoutBody =>
      'इस टेम्पलेट के अनुशंसित होम मॉड्यूल उपयोग करें।';

  @override
  String get applyHomeLayoutCustomizedBody =>
      'आपने होम पहले अनुकूलित किया है। इसे इस टेम्पलेट के लेआउट से बदलें?';

  @override
  String get applyHomeLayoutSkip => 'वर्तमान रखें';

  @override
  String get applyHomeLayoutConfirm => 'लेआउट लागू करें';

  @override
  String get applyHomeLayoutDone => 'होम लेआउट अपडेट हो गया।';

  @override
  String minMeaningfulTextError(int min) {
    return 'कम से कम $min अक्षर दर्ज करें।';
  }

  @override
  String get searchTypeMinChars => 'कम से कम 3 अक्षर लिखें';

  @override
  String get searchCustomersHint => 'नाम, फ़ोन या उपनाम से खोजें';

  @override
  String get searchNoResults => 'कोई मिलान नहीं';

  @override
  String get dueDateOptionalLabel => 'देय तिथि वैकल्पिक';

  @override
  String get dueDateOptionalSubtitle =>
      'निश्चित वापसी तिथि के बिना जारी करने की अनुमति दें (वापसी तक शुल्क बढ़ता रहेगा)।';

  @override
  String get continueWithoutDueDate => 'देय तिथि के बिना जारी रखें';

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
}
