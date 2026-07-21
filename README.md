# Tally

A private, **offline-first personal budget tracker** — part of the Secure Suite.

Tally answers one question well: *where did my money go this month?* It tracks
**cash and digital together** using an accounts model, so moving money around
(ATM withdrawals, transfers) never looks like spending, and per-category monthly
budgets show what's left at a glance.

## Features (Phase 1)

- **Accounts** (cash, bank, wallet, card) with live balances + **transfers**
  between your own accounts (an ATM withdrawal is a transfer, not spending).
- **Fast entry** of expenses, income, and transfers.
- **Categories + monthly budgets** with progress and over-budget warnings.
- **Dashboard**: month spend vs income, total balance, budgets, recent activity.
- **Encrypted & offline**: all data is AES-256-GCM encrypted on-device (a random
  key in the platform keystore); nothing leaves the phone.
- **Backup & restore**: scheduled encrypted backups to a folder or **Google
  Drive** (shared `core_backup`), restorable with your passphrase.

### On the roadmap
- **Phase 2** — split / reimbursable expenses ("I paid, friends owe me back")
  reconciled against incoming payments; recurring transactions.
- **Phase 3** — zero-effort digital capture by parsing bank SMS + wallet
  notifications on-device.

## Stack

Flutter (Riverpod, go_router) + the shared Secure Suite packages
(`core_crypto`, `core_storage`, `core_theme`, `core_ui`, `core_backup`). Money is
stored as integer minor units; the whole dataset is one immutable snapshot
serialized, encrypted, and written atomically on every change.

## Releasing

Signed APKs ship to GitHub Releases on `vX.Y.Z` tags via the `Release`
workflow, using the shared Secure Suite keystore (repo secrets). CI pins
Flutter 3.41.3 to match the rest of the suite.
