/// Limits which entity types [LocalRepository.search] matches against.
enum SearchScope {
  /// Customers, rentals, and inventory (app-bar / universal search).
  global,

  /// Inventory name, category, id, and notes only.
  inventory,

  /// Customers by name/phone/id, plus customers whose rentals match nickname.
  customers,
}
