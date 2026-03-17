import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionHeader(title: 'Today'),
            SizedBox(height: 10),
            _NotificationCard(
              items: [
                _NotificationItemData(
                  initials: 'BA',
                  avatarColor: Color(0xFFEC4899),
                  title: 'New Expense Added',
                  subtitle: 'Badar added  "Electricity Bill"  expense',
                  metaLeft: '2 hours ago',
                  metaMid: 'Badar',
                  metaRight: r'$450',
                ),
                _NotificationItemData(
                  initials: 'SA',
                  avatarColor: Color(0xFF8B5CF6),
                  title: 'Expense Updated',
                  subtitle: 'Saeed added  "Office Supplies"  expense',
                  metaLeft: '2 hours ago',
                  metaMid: 'Saeed',
                  metaRight: r'$450',
                ),
              ],
            ),
            SizedBox(height: 16),
            _SectionHeader(title: 'Yesterday'),
            SizedBox(height: 10),
            _NotificationCard(
              items: [
                _NotificationItemData(
                  initials: 'SA',
                  avatarColor: Color(0xFF8B5CF6),
                  title: 'New Partner Added',
                  subtitle: 'Saeed joined Logic Worms',
                  metaLeft: '1 day ago',
                  metaMid: 'You',
                  metaRight: '',
                ),
                _NotificationItemData(
                  initials: 'BA',
                  avatarColor: Color(0xFFEC4899),
                  title: 'New Expense Added',
                  subtitle: 'Badar added  "Business Lunch"  expense',
                  metaLeft: '2 hours ago',
                  metaMid: 'Badar',
                  metaRight: r'$450',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final List<_NotificationItemData> items;

  const _NotificationCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _NotificationRow(data: items[i]),
            if (i != items.length - 1)
              Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: AppColors.border.withValues(alpha: 0.9),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final _NotificationItemData data;

  const _NotificationRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: data.avatarColor,
            child: Text(
              data.initials,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(data.metaLeft, style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    _Dot(color: AppColors.border.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Text(data.metaMid, style: AppTextStyles.caption),
                    if (data.metaRight.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _Dot(color: AppColors.border.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          data.metaRight,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _NotificationItemData {
  final String initials;
  final Color avatarColor;
  final String title;
  final String subtitle;
  final String metaLeft;
  final String metaMid;
  final String metaRight;

  const _NotificationItemData({
    required this.initials,
    required this.avatarColor,
    required this.title,
    required this.subtitle,
    required this.metaLeft,
    required this.metaMid,
    required this.metaRight,
  });
}

