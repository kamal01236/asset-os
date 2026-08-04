import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/entities.dart';
import '../pricing/rental_pricing.dart';
import '../theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.status,
    super.key,
  });

  final AssetStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        localizedStatusLabel(context.l10n, status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({
    required this.status,
    this.urgency,
    super.key,
  });

  final OrderStatus status;
  /// When open, optional due-urgency color/label from [AssetStatus].
  final AssetStatus? urgency;

  @override
  Widget build(BuildContext context) {
    final AssetStatus display = status == OrderStatus.open && urgency != null
        ? urgency!
        : status.billAssetStatus;
    final Color color = AppTheme.colorForStatus(display);
    final String label = status == OrderStatus.open &&
            urgency != null &&
            (urgency == AssetStatus.dueToday || urgency == AssetStatus.overdue)
        ? localizedStatusLabel(context.l10n, urgency!)
        : localizedOrderStatus(context.l10n, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EntityCard extends StatelessWidget {
  const EntityCard({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.status,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final AssetStatus? status;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListEntityRow(
      title: title,
      secondary: subtitle,
      leadingIcon: leadingIcon,
      status: status,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Structured list row: avatar, title, optional meta lines, trailing, pill.
class ListEntityRow extends StatelessWidget {
  const ListEntityRow({
    required this.title,
    required this.leadingIcon,
    this.secondary,
    this.tertiary,
    this.status,
    this.pill,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData leadingIcon;
  final String? secondary;
  final String? tertiary;
  final AssetStatus? status;
  final Widget? pill;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget? resolvedPill = pill ??
        (status != null ? StatusPill(status: status!) : null);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(leadingIcon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (secondary != null && secondary!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        secondary!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (tertiary != null && tertiary!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        tertiary!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (resolvedPill != null) ...<Widget>[
                      const SizedBox(height: 10),
                      resolvedPill,
                    ],
                  ],
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

/// Customer trust tier (not inventory Available/Archived).
class TierPill extends StatelessWidget {
  const TierPill({
    required this.trusted,
    super.key,
  });

  final bool trusted;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color color = trusted ? AppTheme.available : AppTheme.archived;
    final String label =
        trusted ? l10n.customerTrusted : l10n.customerStandard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum MoneyStackEmphasis {
  normal,
  total,
  due,
  muted,
}

/// Label left, amount right — for bill/charges breakdowns.
class MoneyStack extends StatelessWidget {
  const MoneyStack({
    required this.label,
    required this.amount,
    this.emphasis = MoneyStackEmphasis.normal,
    super.key,
  });

  final String label;
  final String amount;
  final MoneyStackEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final FontWeight weight = switch (emphasis) {
      MoneyStackEmphasis.total || MoneyStackEmphasis.due => FontWeight.w800,
      MoneyStackEmphasis.muted => FontWeight.w500,
      MoneyStackEmphasis.normal => FontWeight.w600,
    };
    final Color amountColor = switch (emphasis) {
      MoneyStackEmphasis.due => AppTheme.overdue,
      MoneyStackEmphasis.muted => scheme.onSurfaceVariant,
      MoneyStackEmphasis.total => scheme.onSurface,
      MoneyStackEmphasis.normal => scheme.onSurface,
    };
    final TextStyle? labelStyle = switch (emphasis) {
      MoneyStackEmphasis.muted => textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      MoneyStackEmphasis.total || MoneyStackEmphasis.due =>
        textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      MoneyStackEmphasis.normal => textTheme.bodyMedium,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: labelStyle)),
          Text(
            amount,
            style: (emphasis == MoneyStackEmphasis.total ||
                        emphasis == MoneyStackEmphasis.due
                    ? textTheme.titleSmall
                    : textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: weight,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for [MoneyStack] used on order detail charges.
typedef BillAmountRow = MoneyStack;

/// Short display id: last segment of `REN-…` prefixed with `#`.
String shortOrderId(String rentalId) {
  final int sep = rentalId.lastIndexOf('-');
  final String segment =
      sep >= 0 && sep < rentalId.length - 1 ? rentalId.substring(sep + 1) : rentalId;
  return '#$segment';
}

/// Compact bill-style card for an order on Lists / Customer detail.
class OrderBillCard extends StatelessWidget {
  const OrderBillCard({
    required this.rental,
    required this.partyLabel,
    required this.linesLabel,
    this.onTap,
    super.key,
  });

  final Rental rental;
  final String partyLabel;
  final String linesLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();
    final int billTotal = rental.billChargesAsOf(now);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      partyLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (linesLabel.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        linesLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      shortOrderId(rental.id),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OrderStatusPill(
                      status: rental.orderStatus,
                      urgency: rental.isActive ? rental.statusFor(now) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    l10n.orderBillAmountLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatMoney(billTotal),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (rental.depositAmount > 0) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      l10n.orderDepositShortLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatMoney(rental.depositAmount),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact in-list empty: icon + one line + optional single CTA.
class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.ctaLabel,
    this.onPressed,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool showCta = ctaLabel != null && onPressed != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 28, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (showCta) ...<Widget>[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onPressed,
                child: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStatePane extends StatelessWidget {
  const EmptyStatePane({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.inbox_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onPressed,
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    required this.status,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final String label;
  final int value;
  final AssetStatus status;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.colorForStatus(status);
    final BorderSide border = selected
        ? BorderSide(color: color, width: 2)
        : BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return Card(
      color: selected ? color.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: border,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact content-sized KPI for Home; value + short label in one chip.
class KpiChip extends StatelessWidget {
  const KpiChip({
    required this.label,
    required this.value,
    required this.status,
    this.onTap,
    super.key,
  });

  final String label;
  final int value;
  final AssetStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.colorForStatus(status);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner row: "Showing: {label}" + Clear, used on filtered list tabs.
class ActiveFilterBar extends StatelessWidget {
  const ActiveFilterBar({
    required this.label,
    required this.onClear,
    super.key,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.showingFilter(label),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onClear,
          child: Text(l10n.clearFilter),
        ),
      ],
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.show,
    super.key,
  });

  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        context.l10n.offlineBanner,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
