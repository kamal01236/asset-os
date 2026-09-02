enum ReminderKind {
  dueTomorrow,
  dueToday,
  overdue,
  lowStock,
  loanDue,
}

class ReminderCandidate {
  const ReminderCandidate({
    required this.kind,
    required this.entityId,
    required this.title,
    required this.subtitle,
  });

  final ReminderKind kind;
  final String entityId;
  final String title;
  final String subtitle;
}
