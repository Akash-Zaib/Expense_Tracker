import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/firebase/users_directory_data_source.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/store/auth_store.dart';
import '../store/settings_store.dart';
import '../widgets/edit_profile_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsStore _store;
  final UsersDirectoryDataSource _usersDirectory =
      sl<UsersDirectoryDataSource>();
  // Initialize here so hot-reload doesn't break late init.
  final AuthStore _authStore = sl<AuthStore>();

  @override
  void initState() {
    super.initState();
    _store = sl<SettingsStore>();
    _store.load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildProfileCard(context),
              const SizedBox(height: 16),
              _buildSettingsSection(context),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // ── HEADER (same as home) ────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _store.profile?.name ?? 'User',
                      style: AppTextStyles.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '3 Partners',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  // ── PROFILE CARD ─────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context) {
    final profile = _store.profile;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Profile avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: profile == null
                      ? AppColors.primary
                      : Color(profile.signatureColorValue),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.name ?? 'You', style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      profile?.email ?? 'user@alnoortraders.com',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Edit button
              InkWell(
                onTap: profile == null
                    ? null
                    : () async {
                        final unavailableColors =
                            await _loadUnavailableColors();
                        if (!context.mounted) return;
                        final result = await showEditProfileDialog(
                          context: context,
                          initialName: profile.name,
                          initialSignatureColorValue:
                              profile.signatureColorValue,
                          unavailableColorValues: unavailableColors,
                        );
                        if (result == null) return;
                        final ok = await _store.updateProfile(
                          name: result.name,
                          signatureColorValue: result.signatureColorValue,
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          final message =
                              _store.error ??
                              'Could not update profile. Please try again.';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Set<int>> _loadUnavailableColors() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return {};
    final profiles = await _usersDirectory.getAllProfilesByUid();
    final values = <int>{};
    for (final profile in profiles.values) {
      if (profile.uid == currentUid) continue;
      values.add(profile.signatureColorValue);
    }
    return values;
  }

  // ── SETTINGS LIST ────────────────────────────────────────
  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.business_outlined,
            title: 'Business Name',
            subtitle: 'Logic worms',
            onTap: () {},
          ),
          _buildDivider(),
          _buildNotificationsTile(),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Currency',
            subtitle: 'English',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'FAQs and guides',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            subtitle: 'Get help from our team',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: null,
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: null,
            onTap: () {},
          ),
          _buildDivider(),
          _buildLogoutTile(),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  _store.notificationsEnabled ? 'Enabled' : 'Disabled',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: _store.notificationsEnabled,
            onChanged: _store.setNotificationsEnabled,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return InkWell(
      onTap: _confirmLogout,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.redDark, size: 22),
            const SizedBox(width: 16),
            Text(
              'Logout',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.redDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    if (!mounted) return;

    await _authStore.logout();
    if (!mounted) return;

    if (_authStore.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authStore.error!)));
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 20,
      color: AppColors.border.withValues(alpha: 0.9),
    );
  }
}
