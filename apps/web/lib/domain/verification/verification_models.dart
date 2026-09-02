/// Handover verification method configured in More → Verification settings.
enum VerificationMethod {
  manual,
  pin,
  otpDisplay,
  photo,
  checklist;

  static VerificationMethod parse(String raw) {
    return VerificationMethod.values.firstWhere(
      (VerificationMethod m) => m.name == raw,
      orElse: () => VerificationMethod.manual,
    );
  }
}

/// Return condition capture depth (basic = disposition only).
enum ConditionMode {
  basic,
  standard,
  advanced;

  static ConditionMode parse(String raw) {
    return ConditionMode.values.firstWhere(
      (ConditionMode m) => m.name == raw,
      orElse: () => ConditionMode.basic,
    );
  }
}

/// Operator-configured handover and return condition settings.
class VerificationSettings {
  const VerificationSettings({
    required this.handoverEnabled,
    required this.handoverMethod,
    this.pin,
    required this.conditionMode,
    required this.checklistItems,
  });

  final bool handoverEnabled;
  final VerificationMethod handoverMethod;
  final String? pin;
  final ConditionMode conditionMode;
  final List<String> checklistItems;

  VerificationSettings copyWith({
    bool? handoverEnabled,
    VerificationMethod? handoverMethod,
    String? pin,
    ConditionMode? conditionMode,
    List<String>? checklistItems,
  }) {
    return VerificationSettings(
      handoverEnabled: handoverEnabled ?? this.handoverEnabled,
      handoverMethod: handoverMethod ?? this.handoverMethod,
      pin: pin ?? this.pin,
      conditionMode: conditionMode ?? this.conditionMode,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }

  static const List<String> defaultChecklistItems = <String>[
    'scratches',
    'missingParts',
    'powersOn',
  ];

  static VerificationSettings defaults = const VerificationSettings(
    handoverEnabled: false,
    handoverMethod: VerificationMethod.manual,
    conditionMode: ConditionMode.basic,
    checklistItems: defaultChecklistItems,
  );
}

/// Immutable snapshot of a completed handover verification step.
class VerificationRecord {
  const VerificationRecord({
    required this.method,
    this.code,
    this.checklistResults,
    required this.verifiedAt,
    this.mediaIds = const <String>[],
  });

  final VerificationMethod method;
  final String? code;
  final Map<String, bool>? checklistResults;
  final DateTime verifiedAt;
  final List<String> mediaIds;
}

/// Media attachment metadata (bytes live outside SQLite).
class MediaAttachment {
  const MediaAttachment({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.filePath,
    required this.mimeType,
    required this.sizeBytes,
    this.caption,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String filePath;
  final String mimeType;
  final int sizeBytes;
  final String? caption;
  final DateTime createdAt;
}
