import 'package:expense_tracker/features/expense/presentation/pages/personal_expense.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/firebase/current_user_context.dart';
import '../../../../core/firebase/users_directory_data_source.dart';

import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../domain/entities/expense_entry.dart';
import 'add_amount_page.dart';
import 'bank_balances_page.dart';
import '../store/transactions_store.dart';

/// Split / assign is only for expenses the **current user added** (stored under
/// their UID). Rows created by split/assign on another user's subcollection
/// keep [ExpenseEntry.addedBy] as the original creator — those must not show
/// actions for the assignee session.
bool shouldShowExpenseSplitActions(
  ExpenseEntry entry,
  String currentUserName,
  String currentUserUid,
) {
  if (entry.kind != ExpenseEntryKind.expense) return false;
  if (entry.ownerUid != currentUserUid) return false;
  final added = entry.addedBy.trim().toLowerCase();
  final mine = currentUserName.trim().toLowerCase();
  if (added == mine) return true;
  if (added == 'you' || added.isEmpty) {
    return true;
  }
  return false;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TransactionsStore _transactionsStore;
  late final CurrentUserContext _currentUserContext;
  late final UsersDirectoryDataSource _usersDirectory;
  late final ValueNotifier<int> _currentNavIndexNotifier;
  late final ValueNotifier<DateTimeRange> _selectedDateRangeNotifier;
  late final ValueNotifier<String> _currentUserNameNotifier;
  late final ValueNotifier<Map<String, int>> _userColorByNameNotifier;
  late final ValueNotifier<Map<String, int>> _userColorByUidNotifier;
  late final ValueNotifier<List<String>> _userNamesNotifier;
  late final ValueNotifier<Map<String, String>> _uidByNormalizedNameNotifier;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  String _currentUserUid = '';

  // Tab pages for bottom nav
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _transactionsStore = sl<TransactionsStore>();
    _currentUserContext = sl<CurrentUserContext>();
    _usersDirectory = sl<UsersDirectoryDataSource>();
    _currentNavIndexNotifier = ValueNotifier<int>(0);
    _currentUserNameNotifier = ValueNotifier<String>('User');
    _userColorByNameNotifier = ValueNotifier<Map<String, int>>(const {});
    _userColorByUidNotifier = ValueNotifier<Map<String, int>>(const {});
    _userNamesNotifier = ValueNotifier<List<String>>(const []);
    _uidByNormalizedNameNotifier = ValueNotifier<Map<String, String>>(const {});
    _currentUserUid = _currentUserContext.uid;
    // Home cards/sections need a wider snapshot so other users' expenses appear.
    // Use a real-time listener so multi-device updates show instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _transactionsStore.startWatching(limit: 2000);
    });
    _loadIdentityAndColors();
    _listenToUserColorChanges();

    // Default to today and react instantly to date changes.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDateRangeNotifier = ValueNotifier<DateTimeRange>(
      DateTimeRange(start: today, end: today),
    );

    _pages = [
      _buildHomeTab(),
      const AnalyticsPage(), // TODO: Replace with actual analytics page
      const WalletPage(), // TODO: Replace with actual wallet page
      const SettingsPage(), // TODO: Replace with actual settings page
    ];
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _currentNavIndexNotifier.dispose();
    _selectedDateRangeNotifier.dispose();
    _currentUserNameNotifier.dispose();
    _userColorByNameNotifier.dispose();
    _userColorByUidNotifier.dispose();
    _userNamesNotifier.dispose();
    _uidByNormalizedNameNotifier.dispose();
    super.dispose();
  }

  void _listenToUserColorChanges() {
    _usersSubscription?.cancel();
    _usersSubscription = _usersDirectory.firestore
        .collection('users')
        .snapshots()
        .listen((snapshot) {
          final map = <String, int>{};
          final colorByUid = <String, int>{};
          final names = <String>[];
          final uidByName = <String, String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final name = (data['name'] as String?)?.trim();
            final signatureColorValue = (data['signatureColorValue'] as num?)
                ?.toInt();
            if (name == null || name.isEmpty) {
              continue;
            }
            final normalizedName = name.toLowerCase().trim();
            if (signatureColorValue != null) {
              map[normalizedName] = signatureColorValue;
              colorByUid[doc.id] = signatureColorValue;
            }
            uidByName[normalizedName] = doc.id;
            names.add(name);
          }
          _userColorByNameNotifier.value = map;
          _userColorByUidNotifier.value = colorByUid;
          _userNamesNotifier.value = names;
          _uidByNormalizedNameNotifier.value = uidByName;
        });
  }

  Widget _buildHomeTab() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _transactionsStore,
        _selectedDateRangeNotifier,
        _currentUserNameNotifier,
        _userColorByNameNotifier,
        _userColorByUidNotifier,
        _userNamesNotifier,
        _uidByNormalizedNameNotifier,
      ]),
      builder: (context, _) {
        final selectedRange = _selectedDateRangeNotifier.value;
        final rangeStart = DateTime(
          selectedRange.start.year,
          selectedRange.start.month,
          selectedRange.start.day,
        );
        final rangeEnd = DateTime(
          selectedRange.end.year,
          selectedRange.end.month,
          selectedRange.end.day,
        );
        final currentUserName = _currentUserNameNotifier.value;
        final userColorByName = _userColorByNameNotifier.value;
        final userColorByUid = _userColorByUidNotifier.value;
        final allUserNames = _userNamesNotifier.value;
        final uidByNormalizedName = _uidByNormalizedNameNotifier.value;
        final dateFmt = DateFormat('d MMM yyyy');
        final dateRange = rangeStart == rangeEnd
            ? dateFmt.format(rangeStart)
            : '${dateFmt.format(rangeStart)} - ${dateFmt.format(rangeEnd)}';
        final allEntries = _transactionsStore.transactions;

        bool isWithinSelectedRange(ExpenseEntry entry) {
          final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
          return !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
        }

        final entriesForCards =
            allEntries
                .where(isWithinSelectedRange)
                .toList(growable: false)
              ..sort((a, b) {
                final dateCmp = b.date.compareTo(a.date);
                if (dateCmp != 0) return dateCmp;
                final aMinutes = a.time.hour * 60 + a.time.minute;
                final bMinutes = b.time.hour * 60 + b.time.minute;
                return bMinutes.compareTo(aMinutes);
              });

        // Recent Activity: all partners' transactions (not limited to selected date).
        final activityEntries = allEntries.toList(growable: false)
          ..sort((a, b) {
            final dateCmp = b.date.compareTo(a.date);
            if (dateCmp != 0) return dateCmp;
            final aMinutes = a.time.hour * 60 + a.time.minute;
            final bMinutes = b.time.hour * 60 + b.time.minute;
            return bMinutes.compareTo(aMinutes);
          });

        // Available Balance is cumulative up to selected end date (inclusive).
        final availableBalance = allEntries.fold<double>(0, (runningTotal, e) {
          final day = DateTime(e.date.year, e.date.month, e.date.day);
          if (day.isAfter(rangeEnd)) return runningTotal;
          return runningTotal + (e.isCredit ? e.amount : -e.amount);
        });

        // Normalize names to avoid duplicate tabs for the same user
        // (e.g. "Badar Khan" vs "badar khan ").
        final currentNormalized = currentUserName.toLowerCase().trim();
        final canonicalByNormalized = <String, String>{
          currentNormalized: currentUserName,
        };

        void addCanonical(String name) {
          final trimmed = name.trim();
          if (trimmed.isEmpty) return;
          final normalized = trimmed.toLowerCase();
          if (normalized == currentNormalized) {
            canonicalByNormalized[normalized] = currentUserName;
            return;
          }
          canonicalByNormalized.putIfAbsent(normalized, () => trimmed);
        }

        for (final name in allUserNames) {
          addCanonical(name);
        }
        for (final entry in entriesForCards) {
          addCanonical(
            entry.paidTo.trim().isEmpty ? entry.ownerName : entry.paidTo,
          );
        }
        for (final normalized in uidByNormalizedName.keys) {
          addCanonical(normalized);
        }

        // Build a set of known aliases for current user from transaction data.
        // This prevents duplicate cards when same user has name variants.
        final currentUserAliases = <String>{currentNormalized};
        for (final e in allEntries.where(
          (e) => e.ownerUid == _currentUserUid,
        )) {
          final ownerAlias = e.ownerName.trim().toLowerCase();
          if (ownerAlias.isNotEmpty) currentUserAliases.add(ownerAlias);
        }
        // Show one "My Personal Expenses" card for current user,
        // plus other users' cards (excluding current user name).
        // Build "other users" from two sources:
        // 1) Auth directory users (preferred when available).
        // 2) Transaction assigned names (`paidTo`) as fallback when users docs are missing.
        final otherUsers = <String>{};

        for (final entry in canonicalByNormalized.entries) {
          final normalized = entry.key;
          final uid = uidByNormalizedName[normalized];
          if (uid == null || uid.isEmpty) continue;
          if (uid == _currentUserUid) continue;
          if (currentUserAliases.contains(normalized)) continue;
          otherUsers.add(entry.value);
        }

        final paidToFromEntries = entriesForCards
            .where((t) => !t.isCredit && t.kind == ExpenseEntryKind.expense)
            .map((t) => t.paidTo.trim().toLowerCase())
            .where((name) => name.isNotEmpty)
            .toSet();
        for (final normalized in paidToFromEntries) {
          if (normalized.isEmpty) continue;
          if (currentUserAliases.contains(normalized)) continue;
          final candidate = canonicalByNormalized[normalized] ?? normalized;
          otherUsers.add(candidate);
        }

        final authOtherUsers = otherUsers.toList(growable: false)
          ..sort(
            (a, b) => a.toLowerCase().trim().compareTo(b.toLowerCase().trim()),
          );

        final displayUsers = <String>[currentUserName, ...authOtherUsers];

        // "Assign/Split To" reuses the same other-users set so it stays
        // consistent with displayed cards even when Firestore `users` docs
        // are incomplete.
        final paidToTargets = authOtherUsers;

        // Group "expenses shown on the card" by `paidTo` (who the expense is
        // assigned to), not by `ownerUid` (who created the record).
        final expenseByPaidToNormalized = <String, double>{};
        for (final e in entriesForCards.where(
          (t) => !t.isCredit && t.kind == ExpenseEntryKind.expense,
        )) {
          final paidToNormalized = e.paidTo.trim().toLowerCase();
          if (paidToNormalized.isEmpty) continue;
          expenseByPaidToNormalized[paidToNormalized] =
              (expenseByPaidToNormalized[paidToNormalized] ?? 0) + e.amount;
        }
        final cards = displayUsers
            .map((name) {
              final normalized = name.toLowerCase().trim();
              final cardEntries = entriesForCards
                  .where((e) => e.kind == ExpenseEntryKind.expense)
                  .where((e) => e.paidTo.trim().toLowerCase() == normalized)
                  .toList(growable: false);
              return _ExpenseCardData(
                title: normalized == currentUserName.toLowerCase().trim()
                    ? 'Personal Expenses'
                    : "$name's Expenses",
                userName: name,
                amount: expenseByPaidToNormalized[normalized] ?? 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalExpensesScreen(
                        entries: cardEntries,
                        title:
                            normalized == currentUserName.toLowerCase().trim()
                            ? 'My Expenses'
                            : "$name's Expenses",
                        showOnlyExpenses: true,
                      ),
                    ),
                  );
                },
              );
            })
            .toList(growable: false);

        return _HomeContent(
          currentUserName: currentUserName,
          availableBalance: availableBalance,
          dateRange: dateRange,
          expenseCards: cards,
          paidToTargets: paidToTargets,
          currentUserUid: _currentUserUid,
          userColorByName: userColorByName,
          userColorByUid: userColorByUid,
          uidByNormalizedName: uidByNormalizedName,
          entries: entriesForCards,
          activityEntries: activityEntries,
          onOpenAmountAddedBreakdown: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => BankBalancesPage(
                  displayUsers: displayUsers,
                  uidByNormalizedName: uidByNormalizedName,
                ),
              ),
            );
          },
          onAddCash: _navigateToAddAmount,
          onSubmitExpense: _navigateToSubmitExpense,
          onPickDateRange: _showDateSelectionOptions,
          onReassignPaidTo: _reassignPaidTo,
          onSplitAssign: (entry) => _showSplitAssignSheet(
            entry: entry,
            candidates: paidToTargets,
            uidByNormalizedName: uidByNormalizedName,
            currentUserName: currentUserName,
          ),
        );
      },
    );
  }

  Future<void> _showSplitAssignSheet({
    required ExpenseEntry entry,
    required List<String> candidates,
    required Map<String, String> uidByNormalizedName,
    required String currentUserName,
  }) async {
    if (entry.id.isEmpty) return;
    if (candidates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No other users found.')));
      return;
    }

    final selected = await showModalBottomSheet<_SplitAssignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SplitAssignSheet(entry: entry, candidates: candidates),
    );

    if (selected == null) return;
    final normalized = selected.targetName.toLowerCase().trim();
    final targetUid = uidByNormalizedName[normalized];
    if (targetUid == null || targetUid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected user is not authenticated.')),
      );
      return;
    }

    await _transactionsStore.splitAndAssign(
      entry: entry,
      targetUid: targetUid,
      targetName: selected.targetName,
      amount: selected.amount,
      currentUserName: currentUserName,
      currentUserUid: _currentUserUid,
    );

    if (!mounted) return;
    if (_transactionsStore.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to split: ${_transactionsStore.error}')),
      );
    }
  }

  Future<void> _reassignPaidTo(ExpenseEntry entry, String paidTo) async {
    if (entry.id.isEmpty) return;
    // "Assign To" should move the full amount to selected user:
    // decrease current user's expense and increase selected user's expense.
    final normalized = paidTo.toLowerCase().trim();
    final uidByNormalizedName = _uidByNormalizedNameNotifier.value;
    final targetUid = uidByNormalizedName[normalized];
    if (targetUid == null ||
        targetUid.isEmpty ||
        targetUid == _currentUserUid) {
      return;
    }

    await _transactionsStore.moveFullAmountToUser(
      entry: entry,
      targetUid: targetUid,
      targetName: paidTo,
      currentUserName: _currentUserNameNotifier.value,
      currentUserUid: _currentUserUid,
    );
    if (!mounted) return;
    if (_transactionsStore.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign: ${_transactionsStore.error}'),
        ),
      );
    }
  }

  Future<void> _showDateSelectionOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Current date'),
                  subtitle: const Text('Use today automatically'),
                  onTap: () => Navigator.pop(ctx, 'today'),
                ),
                ListTile(
                  leading: const Icon(Icons.today_outlined),
                  title: const Text('Single date'),
                  subtitle: const Text('Pick one specific date'),
                  onTap: () => Navigator.pop(ctx, 'single'),
                ),
                ListTile(
                  leading: const Icon(Icons.date_range_outlined),
                  title: const Text('Date range'),
                  subtitle: const Text('Pick start and end date'),
                  onTap: () => Navigator.pop(ctx, 'range'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null) return;
    if (choice == 'today') {
      _selectCurrentDate();
      return;
    }
    if (choice == 'single') {
      await _pickSingleDate();
      return;
    }
    await _pickDateRange();
  }

  void _selectCurrentDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDateRangeNotifier.value = DateTimeRange(start: today, end: today);
  }

  Future<void> _pickSingleDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentRange = _selectedDateRangeNotifier.value;
    var initial = DateTime(
      currentRange.end.year,
      currentRange.end.month,
      currentRange.end.day,
    );
    if (initial.isAfter(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    _selectedDateRangeNotifier.value = DateTimeRange(start: day, end: day);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentRange = _selectedDateRangeNotifier.value;
    var initialStart = DateTime(
      currentRange.start.year,
      currentRange.start.month,
      currentRange.start.day,
    );
    var initialEnd = DateTime(
      currentRange.end.year,
      currentRange.end.month,
      currentRange.end.day,
    );
    if (initialStart.isAfter(today)) initialStart = today;
    if (initialEnd.isAfter(today)) initialEnd = today;
    if (initialEnd.isBefore(initialStart)) initialEnd = initialStart;

    final startPicked = await showDatePicker(
      context: context,
      initialDate: initialStart,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select start date',
      confirmText: 'Next',
      cancelText: 'Cancel',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (startPicked == null) return;
    if (!mounted) return;

    final startDay = DateTime(
      startPicked.year,
      startPicked.month,
      startPicked.day,
    );
    final endInitial = initialEnd.isBefore(startDay) ? startDay : initialEnd;
    final endPicked = await showDatePicker(
      context: context,
      initialDate: endInitial,
      firstDate: startDay,
      lastDate: today,
      helpText: 'Select end date',
      confirmText: 'Apply',
      cancelText: 'Cancel',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (endPicked == null) return;
    if (!mounted) return;

    final endDay = DateTime(endPicked.year, endPicked.month, endPicked.day);
    _selectedDateRangeNotifier.value = DateTimeRange(
      start: startDay,
      end: endDay,
    );
  }

  Future<void> _navigateToAddAmount() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addAmount);
    if (result != null && result is AddAmountResult) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final entry = ExpenseEntry(
        description: result.description,
        amount: result.amount,
        category: 'Amount Added',
        date: today,
        time: TimeOfDay.fromDateTime(now),
        paidBy: _currentUserNameNotifier.value,
        addedBy: _currentUserNameNotifier.value,
        ownerUid: _currentUserUid,
        ownerName: _currentUserNameNotifier.value,
        paidTo: _currentUserNameNotifier.value,
        bankName: result.bankName,
        kind: ExpenseEntryKind.amountAdded,
        isCredit: true,
      );
      await _transactionsStore.add(entry);
      if (!mounted) return;
      if (_transactionsStore.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save amount: ${_transactionsStore.error}'),
          ),
        );
      }
    }
  }

  Future<void> _navigateToSubmitExpense() async {
    final result = await Navigator.pushNamed(context, AppRoutes.submitExpense);
    if (result != null && result is ExpenseEntry) {
      final normalized = ExpenseEntry(
        id: result.id,
        description: result.description,
        amount: result.amount,
        category: result.category,
        date: result.date,
        time: result.time,
        paidBy: _currentUserNameNotifier.value,
        addedBy: _currentUserNameNotifier.value,
        ownerUid: _currentUserUid,
        ownerName: _currentUserNameNotifier.value,
        paidTo: result.paidTo,
        bankName: result.bankName,
        kind: result.kind,
        isCredit: result.isCredit,
      );
      await _transactionsStore.add(normalized);
      if (!mounted) return;
      if (_transactionsStore.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save expense: ${_transactionsStore.error}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadIdentityAndColors() async {
    try {
      final name = await _currentUserContext.resolvedName();
      final profiles = await _usersDirectory.getAllProfilesByUid();
      final map = <String, int>{};
      for (final profile in profiles.values) {
        map[profile.name.toLowerCase().trim()] = profile.signatureColorValue;
      }
      if (!mounted) return;
      _currentUserNameNotifier.value = name;
      _userColorByNameNotifier.value = map;
    } catch (_) {
      // Keep previous notifiers' values on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentNavIndexNotifier,
      builder: (context, currentNavIndex, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: IndexedStack(index: currentNavIndex, children: _pages),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
          floatingActionButton: currentNavIndex == 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 84, right: 10),
                  child: FloatingActionButton(
                    onPressed: _navigateToSubmitExpense,
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                )
              : null,
          bottomNavigationBar: _buildBottomNav(currentNavIndex),
        );
      },
    );
  }

  // ── BOTTOM NAV (matches Figma) ────────────────────────────
  Widget _buildBottomNav(int currentNavIndex) {
    return Container(
      color: const Color(0xFF1F1F1F),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 0, currentNavIndex),
            _buildNavItem(Icons.bar_chart, 1, currentNavIndex),
            _buildNavItem(Icons.account_balance_wallet, 2, currentNavIndex),
            _buildNavItem(Icons.settings, 3, currentNavIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, int currentNavIndex) {
    final isActive = currentNavIndex == index;
    return GestureDetector(
      onTap: () => _currentNavIndexNotifier.value = index,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 28),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── HOME CONTENT (extracted so it can be used in IndexedStack) ───
class _HomeContent extends StatefulWidget {
  final String currentUserName;
  final String currentUserUid;
  final double availableBalance;
  final String dateRange;
  final List<_ExpenseCardData> expenseCards;
  final List<String> paidToTargets;
  final Future<void> Function(ExpenseEntry entry) onSplitAssign;
  final Map<String, int> userColorByName;
  final Map<String, int> userColorByUid;
  final Map<String, String> uidByNormalizedName;
  final List<ExpenseEntry> entries;

  /// All partners — used only for Recent Activity (not date-scoped).
  final List<ExpenseEntry> activityEntries;
  final VoidCallback onOpenAmountAddedBreakdown;
  final VoidCallback onAddCash;
  final VoidCallback onSubmitExpense;
  final VoidCallback onPickDateRange;
  final Future<void> Function(ExpenseEntry entry, String paidTo)
  onReassignPaidTo;

  const _HomeContent({
    required this.currentUserName,
    required this.currentUserUid,
    required this.availableBalance,
    required this.dateRange,
    required this.expenseCards,
    required this.paidToTargets,
    required this.userColorByName,
    required this.userColorByUid,
    required this.uidByNormalizedName,
    required this.entries,
    required this.activityEntries,
    required this.onOpenAmountAddedBreakdown,
    required this.onAddCash,
    required this.onSubmitExpense,
    required this.onPickDateRange,
    required this.onReassignPaidTo,
    required this.onSplitAssign,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final ValueNotifier<Set<DateTime>> _expandedActivityDaysNotifier =
      ValueNotifier<Set<DateTime>>(<DateTime>{});
  bool _didSetDefaultExpandedDay = false;
  bool _queuedExpansionSync = false;

  @override
  void dispose() {
    _expandedActivityDaysNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildBalanceSection(context),
          const SizedBox(height: 24),
          _buildGridSection(context),
          const SizedBox(height: 24),
          _buildRecentActivitySection(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── HEADER (matches Figma exactly) ────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              // Avatar with badge
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUserName,
                      style: AppTextStyles.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Notification icon hidden for now.
        const SizedBox.shrink(),
      ],
    );
  }

  // ── BALANCE SECTION (overflow-safe) ───────────────────────
  Widget _buildBalanceSection(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
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
          // Top row: title + calendar icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Balance', style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text(widget.dateRange, style: AppTextStyles.caption),
                  ],
                ),
              ),
              InkWell(
                onTap: widget.onPickDateRange,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance amount + Add Cash button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatter.format(widget.availableBalance),
                          style: AppTextStyles.heading1.copyWith(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onOpenAmountAddedBreakdown,
                      child: const Icon(
                        Icons.open_in_new,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: widget.onAddCash,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Cash'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── EXPENSE GRID (overflow-safe) ──────────────────────────
  Widget _buildGridSection(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    if (widget.expenseCards.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < widget.expenseCards.length; i += 2) {
      final left = widget.expenseCards[i];
      final right = i + 1 < widget.expenseCards.length
          ? widget.expenseCards[i + 1]
          : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: _buildExpenseCard(
                title: left.title,
                amount: formatter.format(left.amount),
                baseColor: _colorForUser(left.userName),
                fallbackBgColor: Colors.white,
                onTap: left.onTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _buildExpenseCard(
                      title: right.title,
                      amount: formatter.format(right.amount),
                      baseColor: _colorForUser(right.userName),
                      fallbackBgColor: Colors.white,
                      onTap: right.onTap,
                    ),
            ),
          ],
        ),
      );
      if (i + 2 < widget.expenseCards.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  Color? _colorForUser(String name) {
    final key = name.toLowerCase().trim();
    final uid = widget.uidByNormalizedName[key];
    final value =
        (uid != null ? widget.userColorByUid[uid] : null) ??
        widget.userColorByName[key];
    return value == null ? null : Color(value);
  }

  Widget _buildExpenseCard({
    required String title,
    required String amount,
    required Color fallbackBgColor,
    required Color? baseColor,
    VoidCallback? onTap,
  }) {
    final bgColor = baseColor == null
        ? fallbackBgColor
        : baseColor.withValues(alpha: 0.14);
    final titleColor = baseColor ?? AppColors.textPrimary;
    final border = baseColor == null
        ? (fallbackBgColor == Colors.white
              ? Border.all(color: AppColors.border)
              : null)
        : Border.all(color: baseColor.withValues(alpha: 0.45));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              softWrap: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: AppTextStyles.heading3.copyWith(
                        color: baseColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (onTap != null)
                  Icon(
                    Icons.open_in_new,
                    color: baseColor ?? AppColors.primary,
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── RECENT ACTIVITY (overflow-safe) ───────────────────────
  Widget _buildRecentActivitySection(BuildContext context) {
    final grouped = _groupByDay(widget.activityEntries);
    final groupKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    _syncExpandedDaysAfterBuild(groupKeys);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppTextStyles.title),
          const SizedBox(height: 16),
          if (widget.activityEntries.isEmpty)
            _buildEmptyState()
          else
            ValueListenableBuilder<Set<DateTime>>(
              valueListenable: _expandedActivityDaysNotifier,
              builder: (context, expandedDays, _) {
                return Column(
                  children: [
                    for (
                      int dayIndex = 0;
                      dayIndex < groupKeys.length;
                      dayIndex++
                    ) ...[
                      Builder(
                        builder: (context) {
                          final day = groupKeys[dayIndex];
                          final entriesForDay =
                              grouped[day] ?? const <ExpenseEntry>[];
                          return _buildActivityDayRow(
                            context: context,
                            day: day,
                            entries: entriesForDay,
                            expandedDays: expandedDays,
                          );
                        },
                      ),
                      if (dayIndex < groupKeys.length - 1)
                        SizedBox(
                          height:
                              _isActivityDayExpanded(
                                groupKeys[dayIndex],
                                expandedDays,
                              )
                              ? 16
                              : 12,
                        ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _syncExpandedDaysAfterBuild(List<DateTime> groupKeys) {
    if (_queuedExpansionSync) return;

    Set<DateTime>? next;
    if (widget.activityEntries.isEmpty &&
        _expandedActivityDaysNotifier.value.isNotEmpty) {
      next = <DateTime>{};
    } else if (!_didSetDefaultExpandedDay && groupKeys.isNotEmpty) {
      final today = _asDay(DateTime.now());
      DateTime? todayKey;
      for (final day in groupKeys) {
        if (_isSameDay(day, today)) {
          todayKey = _asDay(day);
          break;
        }
      }
      next = todayKey == null ? <DateTime>{} : <DateTime>{todayKey};
      _didSetDefaultExpandedDay = true;
    }

    if (next == null) return;
    _queuedExpansionSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queuedExpansionSync = false;
      if (!mounted) return;
      _expandedActivityDaysNotifier.value = next!;
    });
  }

  Widget _buildActivityDayRow({
    required BuildContext context,
    required DateTime day,
    required List<ExpenseEntry> entries,
    required Set<DateTime> expandedDays,
  }) {
    final isExpanded = _isActivityDayExpanded(day, expandedDays);
    final isToday = _isSameDay(day, _asDay(DateTime.now()));
    final rowBgColor = isToday
        ? AppColors.primary.withValues(alpha: 0.09)
        : AppColors.background;
    final rowBorderColor = isExpanded
        ? Colors.transparent
        : AppColors.border.withValues(alpha: 0.9);
    final labelColor = isToday ? AppColors.primary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: rowBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rowBorderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatSectionTitle(day),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => _toggleActivityDay(day, expandedDays),
                splashRadius: 18,
                iconSize: 20,
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isExpanded
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          _ActivityCard(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                _buildActivityItem(context, entries[i]),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: AppColors.border.withValues(alpha: 0.9),
          ),
        ],
      ],
    );
  }

  bool _isActivityDayExpanded(DateTime day, Set<DateTime> expandedDays) {
    for (final expandedDay in expandedDays) {
      if (_isSameDay(expandedDay, day)) return true;
    }
    return false;
  }

  void _toggleActivityDay(DateTime day, Set<DateTime> currentExpandedDays) {
    final next = <DateTime>{...currentExpandedDays};
    final existing = next.where((expandedDay) => _isSameDay(expandedDay, day));
    if (existing.isNotEmpty) {
      next.removeWhere((expandedDay) => _isSameDay(expandedDay, day));
    } else {
      next.add(_asDay(day));
    }
    _expandedActivityDaysNotifier.value = next;
  }

  DateTime _asDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isSameDay(DateTime a, DateTime b) => _asDay(a) == _asDay(b);

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No entries yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first expense',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ExpenseEntry entry) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final formatter = NumberFormat('#,##0', 'en_US');
    final paidTo = entry.paidTo.trim().isEmpty
        ? entry.ownerName.trim()
        : entry.paidTo.trim();
    final actorName = entry.kind == ExpenseEntryKind.amountAdded
        ? (entry.addedBy.trim().isNotEmpty ? entry.addedBy : entry.ownerName)
        : (entry.paidBy.trim().isNotEmpty ? entry.paidBy : entry.ownerName);
    final normalizedPaidTo = paidTo.toLowerCase().trim();
    final normalizedActor = actorName.toLowerCase().trim();
    final isAssignedToOther =
        entry.kind == ExpenseEntryKind.expense &&
        normalizedPaidTo.isNotEmpty &&
        normalizedPaidTo != normalizedActor;
    final displayName = entry.kind == ExpenseEntryKind.amountAdded
        ? actorName
        : (isAssignedToOther
              ? 'Paid by $actorName assigned to $paidTo'
              : 'Paid by $actorName');
    final timeLabel = entry.time.format(context);
    // Activity accent color follows the **actor** (who paid / added), not the
    // Firestore subcollection owner — split/assign copies use assignee UID but
    // paidBy/addedBy still identify the initiator.
    final actorUidFromDirectory = widget.uidByNormalizedName[normalizedActor];
    var colorValue = actorUidFromDirectory != null
        ? widget.userColorByUid[actorUidFromDirectory]
        : null;
    colorValue ??= widget.userColorByName[normalizedActor];
    if (colorValue == null &&
        entry.ownerUid.trim().isNotEmpty &&
        entry.ownerName.trim().toLowerCase() == normalizedActor) {
      colorValue = widget.userColorByUid[entry.ownerUid.trim()];
    }
    final baseColor = colorValue == null ? null : Color(colorValue);
    final bgColor = baseColor == null
        ? (entry.isCredit ? AppColors.greenLight : AppColors.redLight)
        : baseColor.withValues(alpha: 0.14);
    final accentColor =
        baseColor ?? (entry.isCredit ? AppColors.greenDark : AppColors.redDark);
    final actionLabel = entry.kind == ExpenseEntryKind.amountAdded
        ? 'Added by'
        : '';

    final showExpenseOverflowMenu = shouldShowExpenseSplitActions(
      entry,
      widget.currentUserName,
      widget.currentUserUid,
    );

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _ActivityDetailsDialog(entry: entry),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              actionLabel.isNotEmpty
                                  ? '$actionLabel $displayName'
                                  : displayName,
                              style: AppTextStyles.caption.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  dateFormat.format(entry.date),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.border.withValues(
                                      alpha: 0.9,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(timeLabel, style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatter.format(entry.amount),
                              style: AppTextStyles.title,
                            ),
                          ),
                          if (showExpenseOverflowMenu) ...[
                            const SizedBox(height: 6),
                            Material(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _showExpenseActions(
                                  context,
                                  entry,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.call_split_rounded,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Split',
                                        style: AppTextStyles.caption.copyWith(
                                          color: accentColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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

  void _showExpenseActions(BuildContext context, ExpenseEntry entry) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_split_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Split & Assign'),
                  subtitle: const Text('Split amount to another user'),
                  onTap: () {
                    Navigator.pop(ctx, 'split_assign');
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Assign To'),
                  subtitle: const Text('Move full amount to another user'),
                  onTap: () {
                    Navigator.pop(ctx, 'assign_to');
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) async {
      if (value == null) return;
      if (value == 'split_assign') {
        await widget.onSplitAssign(entry);
      } else if (value == 'assign_to') {
        await _showReassignPaidToSheet(context, entry);
      }
    });
  }

  Future<void> _showReassignPaidToSheet(
    BuildContext context,
    ExpenseEntry entry,
  ) async {
    if (entry.id.isEmpty) return;
    final current = entry.paidTo.trim().isEmpty
        ? entry.ownerName
        : entry.paidTo;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reassign Paid To',
                    style: AppTextStyles.heading3,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.description,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.paidToTargets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final name = widget.paidToTargets[index];
                        final selected = name == current;
                        return Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.10)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx, name),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.16,
                                            )
                                          : AppColors.background,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary.withValues(
                                            alpha: 0.7,
                                          ),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    await widget.onReassignPaidTo(entry, selected);
  }
}

class _ExpenseCardData {
  final String title;
  final String userName;
  final double amount;
  final VoidCallback? onTap;

  const _ExpenseCardData({
    required this.title,
    required this.userName,
    required this.amount,
    this.onTap,
  });
}

class _SplitAssignResult {
  final String targetName;
  final double amount;

  const _SplitAssignResult({required this.targetName, required this.amount});
}

class _SplitAssignSheet extends StatefulWidget {
  final ExpenseEntry entry;
  final List<String> candidates;

  const _SplitAssignSheet({required this.entry, required this.candidates});

  @override
  State<_SplitAssignSheet> createState() => _SplitAssignSheetState();
}

class _SplitAssignSheetState extends State<_SplitAssignSheet> {
  late String _selectedName;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedName = widget.candidates.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.entry.amount;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Split & Assign', style: AppTextStyles.heading3),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.entry.description,
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assign to',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.candidates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final name = widget.candidates[index];
                        final selected = name == _selectedName;
                        return Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.10)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedName = name),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.16,
                                            )
                                          : AppColors.background,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary.withValues(
                                            alpha: 0.7,
                                          ),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount to assign',
                      helperText:
                          'Must be > 0 and < ${maxAmount.toStringAsFixed(0)}',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final raw = _amountController.text.trim();
                  final amount = double.tryParse(raw) ?? 0;
                  if (amount <= 0 || amount >= maxAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount.')),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    _SplitAssignResult(
                      targetName: _selectedName,
                      amount: amount,
                    ),
                  );
                },
                child: const Text('Split & Assign'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityDetailsDialog extends StatelessWidget {
  final ExpenseEntry entry;

  const _ActivityDetailsDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final amountFmt = NumberFormat('#,##0', 'en_US');
    final isAdded = entry.kind == ExpenseEntryKind.amountAdded;
    final paidTo = entry.paidTo.trim();
    final paidBy = entry.paidBy.trim().isNotEmpty
        ? entry.paidBy.trim()
        : entry.ownerName;
    final shouldShowPaidTo = !isAdded && paidTo.isNotEmpty;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Details',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAdded ? 'Amount Added' : 'Expense Transaction',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.8)),
            const SizedBox(height: 12),
            if (!isAdded) _detailRow('Paid by', paidBy),
            if (shouldShowPaidTo) _detailRow('Paid to', paidTo),
            _detailRow(
              'Date & Time',
              '${dateFmt.format(entry.date)} • ${entry.time.format(context)}',
            ),
            if (entry.category.trim().isNotEmpty)
              _detailRow('Category', entry.category),
            if ((entry.bankName ?? '').trim().isNotEmpty)
              _detailRow('Bank', entry.bankName!),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Description',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                entry.description.trim().isEmpty ? '-' : entry.description,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Amount: ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  amountFmt.format(entry.amount),
                  style: AppTextStyles.heading3.copyWith(
                    color: isAdded
                        ? AppColors.greenDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<Widget> children;

  const _ActivityCard({required this.children});

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
      ),
      child: Column(children: children),
    );
  }
}

Map<DateTime, List<ExpenseEntry>> _groupByDay(List<ExpenseEntry> entries) {
  final map = <DateTime, List<ExpenseEntry>>{};
  for (final e in entries) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    (map[day] ??= []).add(e);
  }
  return map;
}

String _formatSectionTitle(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (day == today) return 'Today';
  if (day == yesterday) return 'Yesterday';

  return DateFormat('dd MMM yyyy').format(day);
}
