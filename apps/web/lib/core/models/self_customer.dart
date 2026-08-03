import 'entities.dart';

/// Fixed sentinel customer for walk-in / informal issues (not a real phone).
const String kSelfCustomerId = 'CUS-SELF';
const String kSelfCustomerPhone = '0000000000';
const String kSelfCustomerName = 'SELF Known';

bool isSelfCustomer(Customer customer) => customer.id == kSelfCustomerId;

bool isSelfCustomerId(String customerId) => customerId == kSelfCustomerId;

bool isSelfCustomerPhone(String phone) => phone.trim() == kSelfCustomerPhone;

/// Display label for a rental's party: nickname when set, else customer name.
String rentalPartyLabel(Customer customer, Rental rental) {
  final String? nick = rental.nickname?.trim();
  if (nick != null && nick.isNotEmpty) {
    return nick;
  }
  return customer.name;
}

Customer buildSelfCustomer() => const Customer(
  id: kSelfCustomerId,
  name: kSelfCustomerName,
  phone: kSelfCustomerPhone,
  isTrusted: true,
  qrCode: 'customer:self',
);
