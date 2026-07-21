import 'package:flutter/foundation.dart' show immutable;
import 'package:tally/src/core/models/account.dart';
import 'package:tally/src/core/models/category.dart';
import 'package:tally/src/core/models/txn.dart';

/// The entire app state as one immutable snapshot — serialized to JSON,
/// encrypted, and written as a single file on every mutation (mirrors the
/// Secure Suite storage pattern).
///
/// Compatibility: fields added later must be optional in [fromJson] with a
/// default, so older vaults and backups keep loading.
@immutable
final class AppData {
  const AppData({
    this.currencyCode = 'PKR',
    this.accounts = const <Account>[],
    this.categories = const <Category>[],
    this.txns = const <Txn>[],
  });

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        currencyCode: json['currencyCode'] as String? ?? 'PKR',
        accounts: (json['accounts'] as List<dynamic>? ?? const [])
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList(),
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
        txns: (json['txns'] as List<dynamic>? ?? const [])
            .map((e) => Txn.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static const int schemaVersion = 1;

  final String currencyCode;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Txn> txns;

  List<Account> get activeAccounts =>
      accounts.where((a) => !a.archived).toList();

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Txn? txnById(String id) {
    for (final t in txns) {
      if (t.id == id) return t;
    }
    return null;
  }

  AppData copyWith({
    String? currencyCode,
    List<Account>? accounts,
    List<Category>? categories,
    List<Txn>? txns,
  }) =>
      AppData(
        currencyCode: currencyCode ?? this.currencyCode,
        accounts: accounts ?? this.accounts,
        categories: categories ?? this.categories,
        txns: txns ?? this.txns,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'currencyCode': currencyCode,
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'txns': txns.map((t) => t.toJson()).toList(),
      };
}
