class Bank {
  final String id;
  final String name;
  final String? accountNumber;
  final bool isSubmitted;

  const Bank({
    required this.id,
    required this.name,
    this.accountNumber,
    this.isSubmitted = false,
  });
}

