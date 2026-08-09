import 'entities.dart';

/// Shared system sentinel for orders without a real phone number.
const String kUnknownCustomerId = 'CUS-UNKNOWN';

/// Non-dialable placeholder reserved for [kUnknownCustomerId] only.
const String kUnknownCustomerPhone = '0000000000';

/// Default English display name; UI should prefer l10n `unknownCustomer`.
const String kUnknownCustomerName = 'Unknown customer';

/// Legacy id from SELF Known; migrated to [kUnknownCustomerId] on initialize.
const String kLegacySelfCustomerId = 'CUS-SELF';

bool isUnknownCustomer(Customer customer) => customer.id == kUnknownCustomerId;

bool isUnknownCustomerId(String customerId) => customerId == kUnknownCustomerId;

bool isUnknownCustomerPhone(String phone) =>
    phone.trim() == kUnknownCustomerPhone;

/// Display label for a rental's party: nickname when set, else customer name.
String rentalPartyLabel(Customer customer, Rental rental) {
  final String? nick = rental.nickname?.trim();
  if (nick != null && nick.isNotEmpty) {
    return nick;
  }
  return customer.name;
}

Customer buildUnknownCustomer() => const Customer(
      id: kUnknownCustomerId,
      name: kUnknownCustomerName,
      phone: kUnknownCustomerPhone,
      isTrusted: true,
      qrCode: 'customer:unknown',
    );
