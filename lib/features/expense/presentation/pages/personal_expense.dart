import 'package:flutter/material.dart';

class PersonalExpensesScreen extends StatelessWidget {
  const PersonalExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      ExpenseActivity(
        title: 'Wholesale Purchase',
        date: '18 Feb 2026',
        addedBy: 'Me',
        paidBy: 'Saeed',
        category: 'Wholesale Purchase',
        bank: 'HBL Bank',
        amount: '450',
      ),
      ExpenseActivity(
        title: 'Wholesale Purchase',
        date: '18 Feb 2026',
        addedBy: 'Badar',
        paidBy: 'Saeed',
        category: 'Wholesale Purchase',
        bank: 'HBL Bank',
        amount: '450',
      ),
      ExpenseActivity(
        title: 'Wholesale Purchase',
        date: '18 Feb 2026',
        addedBy: 'Badar',
        paidBy: 'Saeed',
        category: 'Wholesale Purchase',
        bank: 'HBL Bank',
        amount: '450',
      ),
      ExpenseActivity(
        title: 'Wholesale Purchase',
        date: '18 Feb 2026',
        addedBy: 'Me',
        paidBy: 'Saeed',
        category: 'Wholesale Purchase',
        bank: 'HBL Bank',
        amount: '450',
      ),
      ExpenseActivity(
        title: 'Wholesale Purchase',
        date: '18 Feb 2026',
        addedBy: 'Me',
        paidBy: 'Saeed',
        category: 'Wholesale Purchase',
        bank: 'HBL Bank',
        amount: '450',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF23419C),
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F7),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF5A6270),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Personal Expenses',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2233),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE8E4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Personal Expenses',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF21303A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '1 Feb 2026 - 30 Feb 2026',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64707D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FF),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: Color(0xFF3552B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '12,000',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF182235),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2430),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          itemCount: activities.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = activities[index];

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (_) =>
                                      PaymentDetailsDialog(activity: item),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8FB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF202734),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.date} - Added By ${item.addedBy}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF667085),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.amount,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF202734),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentDetailsDialog extends StatelessWidget {
  final ExpenseActivity activity;

  const PaymentDetailsDialog({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Payment details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9E9E9)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _detailRow(
                    title: 'Category Type',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF4E4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activity.category,
                        style: const TextStyle(
                          color: Color(0xFF1FA34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(title: 'Bank', value: activity.bank),
                  const SizedBox(height: 12),
                  _detailRow(title: 'Date', value: activity.date),
                  const SizedBox(height: 12),
                  _detailRow(title: 'Paid By', value: activity.paidBy),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Amount Paid:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C727F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        activity.amount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({required String title, String? value, Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6C727F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing ??
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
              ),
            ),
      ],
    );
  }
}

class ExpenseActivity {
  final String title;
  final String date;
  final String addedBy;
  final String paidBy;
  final String category;
  final String bank;
  final String amount;

  ExpenseActivity({
    required this.title,
    required this.date,
    required this.addedBy,
    required this.paidBy,
    required this.category,
    required this.bank,
    required this.amount,
  });
}
