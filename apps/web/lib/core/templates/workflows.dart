import 'package:flutter/widgets.dart';

import '../models/entities.dart';

bool _isHindi(Locale locale) => locale.languageCode == 'hi';

/// One step in a [WorkflowDefinition] pipeline.
class WorkflowStatus {
  const WorkflowStatus({
    required this.id,
    required this.labelEn,
    this.labelHi = '',
    this.isTerminal = false,
  });

  final String id;
  final String labelEn;
  final String labelHi;

  /// Terminal statuses close the order for billing ([OrderStatus.completed]).
  final bool isTerminal;

  String localizedLabel(Locale locale) =>
      _isHindi(locale) && labelHi.isNotEmpty ? labelHi : labelEn;
}

/// Ordered status pipeline for a business (template preset).
class WorkflowDefinition {
  const WorkflowDefinition({
    required this.id,
    required this.statuses,
  });

  final String id;
  final List<WorkflowStatus> statuses;

  WorkflowStatus get initial => statuses.first;

  WorkflowStatus get terminal =>
      statuses.lastWhere((WorkflowStatus s) => s.isTerminal, orElse: () => statuses.last);

  WorkflowStatus? byId(String? statusId) {
    if (statusId == null || statusId.isEmpty) {
      return null;
    }
    for (final WorkflowStatus status in statuses) {
      if (status.id == statusId) {
        return status;
      }
    }
    return null;
  }

  int indexOf(String? statusId) {
    if (statusId == null) {
      return -1;
    }
    return statuses.indexWhere((WorkflowStatus s) => s.id == statusId);
  }

  /// Statuses after [currentId] (forward-only). Empty when terminal or unknown.
  List<WorkflowStatus> nextAllowed(String? currentId) {
    final int i = indexOf(currentId);
    if (i < 0) {
      return statuses.where((WorkflowStatus s) => !s.isTerminal).isEmpty
          ? statuses
          : <WorkflowStatus>[initial];
    }
    if (i >= statuses.length - 1) {
      return const <WorkflowStatus>[];
    }
    return statuses.sublist(i + 1);
  }

  WorkflowStatus? immediateNext(String? currentId) {
    final List<WorkflowStatus> next = nextAllowed(currentId);
    return next.isEmpty ? null : next.first;
  }

  bool isTerminalId(String? statusId) => byId(statusId)?.isTerminal ?? false;
}

/// Prefs key for the business active workflow id.
const String kActiveWorkflowIdPrefsKey = 'asset_os_active_workflow_id';

const String kRentalWorkflowId = 'rental';
const String kBoutiqueWorkflowId = 'boutique';
const String kJobWorkflowId = 'job';
const String kSalonWorkflowId = 'salon';

/// Default when prefs / template omit a workflow.
const String kDefaultWorkflowId = kRentalWorkflowId;

/// Sale-only terminal (not part of rental pipeline steps; display/storage id).
const String kSoldWorkflowStatusId = 'sold';

const WorkflowStatus kSoldWorkflowStatus = WorkflowStatus(
  id: kSoldWorkflowStatusId,
  labelEn: 'Sold',
  labelHi: 'बिक गया',
  isTerminal: true,
);

/// Job-style terminal id used when the active pipeline would say "returned".
const String kDoneWorkflowStatusId = 'done';

/// Rental: booked → issued → returned.
const WorkflowDefinition kRentalWorkflow = WorkflowDefinition(
  id: kRentalWorkflowId,
  statuses: <WorkflowStatus>[
    WorkflowStatus(
      id: 'booked',
      labelEn: 'Booked',
      labelHi: 'बुक',
    ),
    WorkflowStatus(
      id: 'issued',
      labelEn: 'Issued',
      labelHi: 'जारी',
    ),
    WorkflowStatus(
      id: 'returned',
      labelEn: 'Returned',
      labelHi: 'वापस',
      isTerminal: true,
    ),
  ],
);

/// Boutique: pending → in_progress → ready → delivered.
const WorkflowDefinition kBoutiqueWorkflow = WorkflowDefinition(
  id: kBoutiqueWorkflowId,
  statuses: <WorkflowStatus>[
    WorkflowStatus(
      id: 'pending',
      labelEn: 'Pending',
      labelHi: 'लंबित',
    ),
    WorkflowStatus(
      id: 'in_progress',
      labelEn: 'In progress',
      labelHi: 'प्रगति में',
    ),
    WorkflowStatus(
      id: 'ready',
      labelEn: 'Ready',
      labelHi: 'तैयार',
    ),
    WorkflowStatus(
      id: 'delivered',
      labelEn: 'Delivered',
      labelHi: 'डिलीवर',
      isTerminal: true,
    ),
  ],
);

/// Beauty / mechanic job-style: received → in_progress → ready → done.
const WorkflowDefinition kJobWorkflow = WorkflowDefinition(
  id: kJobWorkflowId,
  statuses: <WorkflowStatus>[
    WorkflowStatus(
      id: 'received',
      labelEn: 'Received',
      labelHi: 'प्राप्त',
    ),
    WorkflowStatus(
      id: 'in_progress',
      labelEn: 'In progress',
      labelHi: 'प्रगति में',
    ),
    WorkflowStatus(
      id: 'ready',
      labelEn: 'Ready',
      labelHi: 'तैयार',
    ),
    WorkflowStatus(
      id: 'done',
      labelEn: 'Done',
      labelHi: 'पूर्ण',
      isTerminal: true,
    ),
  ],
);

/// Salon short: waiting → in_service → done.
const WorkflowDefinition kSalonWorkflow = WorkflowDefinition(
  id: kSalonWorkflowId,
  statuses: <WorkflowStatus>[
    WorkflowStatus(
      id: 'waiting',
      labelEn: 'Waiting',
      labelHi: 'प्रतीक्षा',
    ),
    WorkflowStatus(
      id: 'in_service',
      labelEn: 'In service',
      labelHi: 'सेवा में',
    ),
    WorkflowStatus(
      id: 'done',
      labelEn: 'Done',
      labelHi: 'पूर्ण',
      isTerminal: true,
    ),
  ],
);

const List<WorkflowDefinition> kWorkflowDefinitions = <WorkflowDefinition>[
  kRentalWorkflow,
  kBoutiqueWorkflow,
  kJobWorkflow,
  kSalonWorkflow,
];

WorkflowDefinition? workflowById(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final WorkflowDefinition workflow in kWorkflowDefinitions) {
    if (workflow.id == id) {
      return workflow;
    }
  }
  return null;
}

WorkflowDefinition resolveWorkflow({String? prefsId}) {
  return workflowById(prefsId) ?? kRentalWorkflow;
}

/// First matching status across presets (for timeline display of status ids).
WorkflowStatus? workflowStatusById(String? statusId) {
  if (statusId == null || statusId.isEmpty) {
    return null;
  }
  if (statusId == kSoldWorkflowStatusId) {
    return kSoldWorkflowStatus;
  }
  for (final WorkflowDefinition workflow in kWorkflowDefinitions) {
    final WorkflowStatus? found = workflow.byId(statusId);
    if (found != null) {
      return found;
    }
  }
  return null;
}

String localizedWorkflowStatusLabel(Locale locale, String? statusId) {
  final WorkflowStatus? status = workflowStatusById(statusId);
  if (status == null) {
    return statusId ?? '';
  }
  return status.localizedLabel(locale);
}

/// Resolve a status for display: active pipeline first, then global catalog.
WorkflowStatus? resolveWorkflowStatusDisplay({
  required WorkflowDefinition workflow,
  required String? statusId,
}) {
  return workflow.byId(statusId) ?? workflowStatusById(statusId);
}

/// Terminal workflow id for a fully closed order, by fulfillment mix.
///
/// Sale-only must not store rental `returned`. All-job under a rental pipeline
/// prefers `done`. Orders with rent keep the active template terminal.
String terminalWorkflowStatusForOrder({
  required WorkflowDefinition workflow,
  required bool hasRent,
  required bool hasJob,
  required bool hasSell,
}) {
  if (hasSell && !hasRent && !hasJob) {
    return kSoldWorkflowStatusId;
  }
  if (hasJob && !hasRent) {
    if (workflow.terminal.id == kDoneWorkflowStatusId) {
      return workflow.terminal.id;
    }
    return kDoneWorkflowStatusId;
  }
  return workflow.terminal.id;
}

/// Derive a workflow status id when the column is null (legacy rows).
String? deriveWorkflowStatusFromOrderStatus(
  OrderStatus orderStatus,
  WorkflowDefinition workflow,
) {
  switch (orderStatus) {
    case OrderStatus.cancelled:
      return null;
    case OrderStatus.completed:
      return workflow.terminal.id;
    case OrderStatus.open:
      return workflow.initial.id;
  }
}

/// Effective per-order status: stored value, else derived from [OrderStatus].
String? effectiveWorkflowStatusId({
  required String? stored,
  required OrderStatus orderStatus,
  required WorkflowDefinition workflow,
}) {
  if (stored != null && stored.isNotEmpty) {
    // Keep pipeline ids and fulfillment-aware terminals (e.g. sold / done)
    // even when they are not steps on the active workflow.
    if (workflow.byId(stored) != null || workflowStatusById(stored) != null) {
      return stored;
    }
  }
  return deriveWorkflowStatusFromOrderStatus(orderStatus, workflow);
}
