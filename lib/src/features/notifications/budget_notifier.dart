import 'package:budgetly/src/core/data/app_data.dart';
import 'package:budgetly/src/core/logic/budgets.dart';
import 'package:budgetly/src/core/money.dart';
import 'package:core_notify/core_notify.dart';
import 'package:core_storage/core_storage.dart';

/// On-device budget notifications: a heads-up when a category crosses 80% and
/// 100% of its monthly budget, and a once-a-month summary of the month just
/// ended. All computed locally from the vault — nothing leaves the device.
class BudgetNotifier {
  BudgetNotifier({required INotify notify, required ISecureStorage storage})
    : _notify = notify,
      _storage = storage;

  final INotify _notify;
  final ISecureStorage _storage;

  static const List<NotifyChannel> channels = [
    NotifyChannel(
      id: 'budget_alerts',
      name: 'Budget alerts',
      description: 'When a category nears or passes its monthly budget',
      importance: NotifyImportance.high,
    ),
    NotifyChannel(
      id: 'budget_summary',
      name: 'Monthly summary',
      description: 'A recap of last month when a new month starts',
    ),
  ];

  static const String _firedKey = 'budgetly_budget_alerts_fired';
  static const String _summaryMonthKey = 'budgetly_summary_month';

  /// Runs both checks. Call once per app open (fire-and-forget); safe to skip
  /// if notifications aren't permitted.
  Future<void> checkOnOpen(AppData data, DateTime now) async {
    if (!await _notify.isPermitted()) return;
    await _checkBudgets(data, now);
    await _maybeMonthlySummary(data, now);
  }

  Future<void> _checkBudgets(AppData data, DateTime now) async {
    final month = DateTime(now.year, now.month);
    final monthKey = '${now.year}-${now.month}';
    final fired = (await _storage.read(key: _firedKey) ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toSet();
    final code = data.currencyCode;

    for (final c in Budgets.byCategory(data, month)) {
      if (!c.hasBudget) continue;
      final ratio = c.spentMinor / c.budgetMinor;
      final threshold = c.overBudget
          ? 100
          : ratio >= 0.8
          ? 80
          : 0;
      if (threshold == 0) continue;

      final key = '${c.categoryId}:$monthKey:$threshold';
      if (fired.contains(key)) continue;

      await _notify.show(
        NotifyRequest(
          id: c.categoryId.hashCode & 0x7fffffff,
          channelId: 'budget_alerts',
          title: threshold == 100
              ? '${c.name}: over budget'
              : '${c.name}: 80% of budget used',
          body:
              '${Money.format(c.spentMinor, code: code)} of '
              '${Money.format(c.budgetMinor, code: code)} this month.',
          payload: 'budgets',
        ),
      );
      fired.add(key);
    }
    await _storage.write(key: _firedKey, value: fired.join(','));
  }

  Future<void> _maybeMonthlySummary(AppData data, DateTime now) async {
    final thisMonthKey = '${now.year}-${now.month}';
    final last = await _storage.read(key: _summaryMonthKey);
    // First launch just records the month; summaries start next month.
    if (last == null) {
      await _storage.write(key: _summaryMonthKey, value: thisMonthKey);
      return;
    }
    if (last == thisMonthKey) return;

    final prev = DateTime(now.year, now.month - 1);
    final spent = Budgets.totalSpentInMonthMinor(data, prev);
    final income = Budgets.totalIncomeInMonthMinor(data, prev);
    final code = data.currencyCode;
    await _notify.show(
      NotifyRequest(
        id: 900001,
        channelId: 'budget_summary',
        title: 'Last month in review',
        body:
            'Spent ${Money.format(spent, code: code)} · '
            'earned ${Money.format(income, code: code)}.',
        payload: 'dashboard',
      ),
    );
    await _storage.write(key: _summaryMonthKey, value: thisMonthKey);
  }
}
