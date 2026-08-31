import 'package:drift/drift.dart';

import '../app_database.dart';

/// Historical upgrades from schema v1 through v23 (frozen at baseline v24).
///
/// Do not edit migration bodies after freeze; add forward steps in
/// [runForwardMigration] instead.
Future<void> migrateLegacyToBaseline(
  AppDatabase db,
  Migrator m,
  int from,
) async {
  if (from < 2) {
    await m.addColumn(db.rentals, db.rentals.nickname);
  }
  if (from < 3) {
    await m.addColumn(db.rentalItems, db.rentalItems.instanceName);
    await m.addColumn(db.rentalItems, db.rentalItems.shortCode);
    // Backfill instance name from catalog; unique legacy short codes.
    await db.customStatement('''
      UPDATE rental_items
      SET instance_name = COALESCE(
        (SELECT name FROM inventory_items
         WHERE inventory_items.id = rental_items.item_id),
        ''
      )
      WHERE instance_name IS NULL OR instance_name = ''
    ''');
    await db.customStatement('''
      UPDATE rental_items
      SET short_code = upper('LEGACY-' || rental_id || '-' || item_id)
      WHERE short_code IS NULL
         OR short_code = ''
         OR upper(short_code) = 'LEGACY'
    ''');
  }
  if (from < 4) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.billingMode);
    await m.addColumn(db.inventoryItems, db.inventoryItems.rateAmount);
    await m.addColumn(db.inventoryItems, db.inventoryItems.lateFeePerDay);
    await m.addColumn(db.inventoryItems, db.inventoryItems.currencyCode);
    await m.addColumn(db.rentals, db.rentals.billingMode);
    await m.addColumn(db.rentals, db.rentals.rateAmount);
    await m.addColumn(db.rentals, db.rentals.lateFeePerDay);
    await m.addColumn(db.rentals, db.rentals.baseAmount);
    await m.addColumn(db.rentals, db.rentals.lateAmount);
    await m.addColumn(db.rentals, db.rentals.totalAmount);
    await m.addColumn(db.rentals, db.rentals.durationUnits);
    await db.customStatement('''
      UPDATE inventory_items
      SET billing_mode = COALESCE(billing_mode, 'weekly'),
          rate_amount = COALESCE(rate_amount, 0),
          late_fee_per_day = COALESCE(late_fee_per_day, 0),
          currency_code = COALESCE(currency_code, 'INR')
    ''');
    await db.customStatement('''
      UPDATE rentals
      SET billing_mode = COALESCE(billing_mode, 'weekly'),
          rate_amount = COALESCE(rate_amount, 0),
          late_fee_per_day = COALESCE(late_fee_per_day, 0),
          base_amount = COALESCE(base_amount, 0),
          late_amount = COALESCE(late_amount, 0),
          total_amount = COALESCE(total_amount, 0),
          duration_units = COALESCE(duration_units, 1)
    ''');
  }
  if (from < 5) {
    await m.addColumn(db.customers, db.customers.depositBalance);
    await m.addColumn(db.rentals, db.rentals.depositApplied);
    await m.createTable(db.depositLedger);
    await db.customStatement('''
      UPDATE customers
      SET deposit_balance = COALESCE(deposit_balance, 0)
    ''');
    await db.customStatement('''
      UPDATE rentals
      SET deposit_applied = COALESCE(deposit_applied, 0)
    ''');
  }
  if (from < 6) {
    await m.addColumn(db.rentals, db.rentals.replacedFromRentalId);
    // Rebuild rental_items: line id PK + returnedAt + per-line amounts.
    await db.customStatement('''
      CREATE TABLE rental_items_new (
        id TEXT NOT NULL PRIMARY KEY,
        rental_id TEXT NOT NULL REFERENCES rentals (id),
        item_id TEXT NOT NULL REFERENCES inventory_items (id),
        instance_name TEXT NOT NULL DEFAULT '',
        short_code TEXT NOT NULL DEFAULT 'LEGACY',
        returned_at INTEGER NULL,
        base_amount INTEGER NOT NULL DEFAULT 0,
        late_amount INTEGER NOT NULL DEFAULT 0,
        deposit_applied INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.customStatement('''
      INSERT INTO rental_items_new (
        id, rental_id, item_id, instance_name, short_code,
        returned_at, base_amount, late_amount, deposit_applied
      )
      SELECT
        'RLI-' || rental_id || '-' || item_id,
        rental_id,
        item_id,
        COALESCE(instance_name, ''),
        COALESCE(short_code, 'LEGACY'),
        (SELECT returned_at FROM rentals WHERE rentals.id = rental_items.rental_id),
        0,
        0,
        0
      FROM rental_items
    ''');
    await db.customStatement('DROP TABLE rental_items');
    await db.customStatement(
      'ALTER TABLE rental_items_new RENAME TO rental_items',
    );
    // Spread parent base across lines when possible (equal share).
    await db.customStatement('''
      UPDATE rental_items
      SET base_amount = CAST(
        (
          SELECT CAST(rentals.base_amount AS REAL) /
            CASE
              WHEN (
                SELECT COUNT(*) FROM rental_items ri2
                WHERE ri2.rental_id = rental_items.rental_id
              ) < 1 THEN 1.0
              ELSE (
                SELECT COUNT(*) FROM rental_items ri2
                WHERE ri2.rental_id = rental_items.rental_id
              )
            END
          FROM rentals WHERE rentals.id = rental_items.rental_id
        ) AS INTEGER
      )
    ''');
    await db.customStatement('''
      UPDATE rental_items
      SET late_amount = CASE
        WHEN returned_at IS NOT NULL THEN CAST(
          (
            SELECT CAST(rentals.late_amount AS REAL) /
              CASE
                WHEN (
                  SELECT COUNT(*) FROM rental_items ri2
                  WHERE ri2.rental_id = rental_items.rental_id
                ) < 1 THEN 1.0
                ELSE (
                  SELECT COUNT(*) FROM rental_items ri2
                  WHERE ri2.rental_id = rental_items.rental_id
                )
              END
            FROM rentals WHERE rentals.id = rental_items.rental_id
          ) AS INTEGER
        )
        ELSE 0
      END,
      deposit_applied = CASE
        WHEN returned_at IS NOT NULL THEN CAST(
          (
            SELECT CAST(rentals.deposit_applied AS REAL) /
              CASE
                WHEN (
                  SELECT COUNT(*) FROM rental_items ri2
                  WHERE ri2.rental_id = rental_items.rental_id
                ) < 1 THEN 1.0
                ELSE (
                  SELECT COUNT(*) FROM rental_items ri2
                  WHERE ri2.rental_id = rental_items.rental_id
                )
              END
            FROM rentals WHERE rentals.id = rental_items.rental_id
          ) AS INTEGER
        )
        ELSE 0
      END
    ''');
  }
  if (from < 7) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.dueDateOptional);
    // Make rentals.dueAt nullable (open-ended rentals) via table rebuild.
    await db.customStatement('''
      CREATE TABLE rentals_new (
        id TEXT NOT NULL PRIMARY KEY,
        customer_id TEXT NOT NULL REFERENCES customers (id),
        started_at INTEGER NOT NULL,
        due_at INTEGER NULL,
        returned_at INTEGER NULL,
        qr_code TEXT NOT NULL,
        nickname TEXT NULL,
        billing_mode TEXT NOT NULL DEFAULT 'weekly',
        rate_amount INTEGER NOT NULL DEFAULT 0,
        late_fee_per_day INTEGER NOT NULL DEFAULT 0,
        base_amount INTEGER NOT NULL DEFAULT 0,
        late_amount INTEGER NOT NULL DEFAULT 0,
        total_amount INTEGER NOT NULL DEFAULT 0,
        deposit_applied INTEGER NOT NULL DEFAULT 0,
        duration_units INTEGER NOT NULL DEFAULT 1,
        replaced_from_rental_id TEXT NULL
      )
    ''');
    await db.customStatement('''
      INSERT INTO rentals_new (
        id, customer_id, started_at, due_at, returned_at, qr_code, nickname,
        billing_mode, rate_amount, late_fee_per_day, base_amount, late_amount,
        total_amount, deposit_applied, duration_units, replaced_from_rental_id
      )
      SELECT
        id, customer_id, started_at, due_at, returned_at, qr_code, nickname,
        billing_mode, rate_amount, late_fee_per_day, base_amount, late_amount,
        total_amount, deposit_applied, duration_units, replaced_from_rental_id
      FROM rentals
    ''');
    await db.customStatement('DROP TABLE rentals');
    await db.customStatement('ALTER TABLE rentals_new RENAME TO rentals');
  }
  if (from < 8) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.requiresUnitIdentity);
    await db.customStatement('''
      UPDATE inventory_items
      SET requires_unit_identity = COALESCE(requires_unit_identity, 1)
    ''');
  }
  if (from < 9) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.defaultItemKind);
    await m.addColumn(db.rentalItems, db.rentalItems.fulfillment);
    await db.customStatement('''
      UPDATE inventory_items
      SET default_item_kind = COALESCE(default_item_kind, 'rental')
    ''');
    await db.customStatement('''
      UPDATE rental_items
      SET fulfillment = COALESCE(fulfillment, 'rent')
    ''');
  }
  if (from < 10) {
    await m.createTable(db.rentalNotes);
    await m.addColumn(db.rentals, db.rentals.depositAmount);
    await m.addColumn(db.rentals, db.rentals.orderStatus);
    await db.customStatement('''
      UPDATE rentals
      SET deposit_amount = COALESCE(deposit_amount, 0),
          order_status = CASE
            WHEN returned_at IS NULL THEN 'open'
            ELSE 'completed'
          END
    ''');
  }
  if (from < 11) {
    // ResourceType: legacy InventoryItemKind.general → sale.
    await db.customStatement('''
      UPDATE inventory_items
      SET default_item_kind = 'sale'
      WHERE default_item_kind = 'general'
    ''');
  }
  if (from < 12) {
    await m.addColumn(db.rentals, db.rentals.workflowStatus);
    // Leave null; readers derive from order_status via active workflow.
  }
  if (from < 13) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.metadata);
  }
  if (from < 14) {
    await m.createTable(db.moneyLoans);
    await m.createTable(db.moneyLoanEntries);
  }
  if (from < 15) {
    await m.addColumn(
      db.moneyLoans,
      db.moneyLoans.prepaymentAllocation,
    );
  }
  if (from < 16) {
    await m.addColumn(
      db.inventoryItems,
      db.inventoryItems.allowsDynamicPricing,
    );
    await m.addColumn(db.rentalItems, db.rentalItems.billingMode);
    await m.addColumn(db.rentalItems, db.rentalItems.rateAmount);
    await m.addColumn(db.rentalItems, db.rentalItems.lateFeePerDay);
    await db.customStatement('''
      UPDATE inventory_items
      SET allows_dynamic_pricing = COALESCE(allows_dynamic_pricing, 0)
    ''');
    // Historical lines had no snapshot; freeze current catalog values.
    await db.customStatement('''
      UPDATE rental_items
      SET
        billing_mode = COALESCE(
          (
            SELECT inventory_items.billing_mode
            FROM inventory_items
            WHERE inventory_items.id = rental_items.item_id
          ),
          'weekly'
        ),
        rate_amount = COALESCE(
          (
            SELECT inventory_items.rate_amount
            FROM inventory_items
            WHERE inventory_items.id = rental_items.item_id
          ),
          0
        ),
        late_fee_per_day = COALESCE(
          (
            SELECT inventory_items.late_fee_per_day
            FROM inventory_items
            WHERE inventory_items.id = rental_items.item_id
          ),
          0
        )
    ''');
  }
  if (from < 17) {
    await m.addColumn(db.moneyLoans, db.moneyLoans.capitalizationPolicy);
    await m.addColumn(db.moneyLoans, db.moneyLoans.capitalizationCycle);
    // simple → never; compound → onScheduledCycle (cycle from ratePeriod).
    await db.customStatement('''
      UPDATE money_loans
      SET
        capitalization_policy = CASE
          WHEN interest_kind = 'compound' THEN 'onScheduledCycle'
          ELSE 'never'
        END,
        capitalization_cycle = CASE
          WHEN rate_period = 'yearly' THEN 'yearly'
          ELSE 'monthly'
        END
    ''');
  }
  if (from < 18) {
    await m.addColumn(db.moneyLoans, db.moneyLoans.interestAccrual);
    // Legacy rate_period=daily → yearly + ACT/365 accrual (same full-year math).
    await db.customStatement('''
      UPDATE money_loans
      SET
        interest_accrual = 'daily365',
        rate_period = 'yearly'
      WHERE rate_period = 'daily'
    ''');
  }
  if (from < 19) {
    await m.addColumn(db.rentalItems, db.rentalItems.returnDisposition);
    // Closed rent lines without disposition were normal returns.
    await db.customStatement('''
      UPDATE rental_items
      SET return_disposition = 'returned'
      WHERE returned_at IS NOT NULL
        AND return_disposition IS NULL
        AND fulfillment = 'rent'
    ''');
  }
  if (from < 20) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.unitCodePrefix);
  }
  if (from < 21) {
    await m.addColumn(db.inventoryItems, db.inventoryItems.catalogActive);
  }
  if (from < 22) {
    await m.addColumn(
      db.inventoryItems,
      db.inventoryItems.securityDepositPaise,
    );
    await m.addColumn(db.rentals, db.rentals.sellPaidPaise);
    await m.addColumn(db.rentals, db.rentals.sellDiscountPaise);
  }
  if (from < 23) {
    await m.createTable(db.customerSubscriptions);
  }
  if (from < 24) {
    await m.addColumn(db.rentalEvents, db.rentalEvents.referenceCode);
  }
}
