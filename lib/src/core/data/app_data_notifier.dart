import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tally/src/core/data/app_data.dart';
import 'package:tally/src/core/models/account.dart';
import 'package:tally/src/core/models/category.dart';
import 'package:tally/src/core/models/txn.dart';
import 'package:tally/src/core/providers.dart';

/// Holds the decrypted in-memory snapshot and persists (encrypt + write) after
/// every mutation.
final class AppDataNotifier extends AsyncNotifier<AppData> {
  @override
  Future<AppData> build() => ref.watch(tallyStoreProvider).load();

  AppData get _data => state.requireValue;

  Future<void> _commit(AppData next) async {
    state = AsyncData<AppData>(next);
    await ref.read(tallyStoreProvider).save(next);
  }

  // -- Accounts -----------------------------------------------------------

  Future<void> saveAccount(Account account) {
    final exists = _data.accounts.any((a) => a.id == account.id);
    final accounts = exists
        ? [for (final a in _data.accounts) a.id == account.id ? account : a]
        : [..._data.accounts, account];
    return _commit(_data.copyWith(accounts: accounts));
  }

  /// Removes an account and every transaction that touches it (keeping the
  /// data consistent). The UI should prefer archiving when history matters.
  Future<void> deleteAccount(String id) => _commit(
        _data.copyWith(
          accounts: _data.accounts.where((a) => a.id != id).toList(),
          txns: _data.txns
              .where((t) => t.accountId != id && t.toAccountId != id)
              .toList(),
        ),
      );

  // -- Categories ---------------------------------------------------------

  Future<void> saveCategory(Category category) {
    final exists = _data.categories.any((c) => c.id == category.id);
    final categories = exists
        ? [for (final c in _data.categories) c.id == category.id ? category : c]
        : [..._data.categories, category];
    return _commit(_data.copyWith(categories: categories));
  }

  /// Removes a category. Transactions keep their (now dangling) categoryId and
  /// are simply treated as uncategorized in budget roll-ups.
  Future<void> deleteCategory(String id) => _commit(
        _data.copyWith(
          categories: _data.categories.where((c) => c.id != id).toList(),
        ),
      );

  // -- Transactions -------------------------------------------------------

  Future<void> saveTxn(Txn txn) {
    final exists = _data.txns.any((t) => t.id == txn.id);
    final txns = exists
        ? [for (final t in _data.txns) t.id == txn.id ? txn : t]
        : [..._data.txns, txn];
    return _commit(_data.copyWith(txns: txns));
  }

  Future<void> deleteTxn(String id) =>
      _commit(_data.copyWith(txns: _data.txns.where((t) => t.id != id).toList()));

  // -- Backup restore -----------------------------------------------------

  /// Replaces the whole dataset with a decoded backup (Phase 1: replace only).
  Future<void> importBackup(AppData imported) => _commit(imported);
}
