class Bank {
  final String id;
  final String name;
  final String? accountNumber;
  final bool isSubmitted;
  /// Owner of this bank record in Firestore.
  /// Used for filtering UI actions (submit/delete) to the current user only.
  final String ownerUid;
  final String ownerName;

  const Bank({
    required this.id,
    required this.name,
    this.accountNumber,
    this.isSubmitted = false,
    this.ownerUid = '',
    this.ownerName = '',
  });
}

