import '../models/account.dart';
import '../repositories/account_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/settings_repository.dart';

class InitialSetupService {
  final AccountRepository _accountRepository;
  final PaymentMethodRepository _paymentMethodRepository;
  final SettingsRepository _settingsRepository;

  InitialSetupService({
    AccountRepository? accountRepository,
    PaymentMethodRepository? paymentMethodRepository,
    SettingsRepository? settingsRepository,
  })  : _accountRepository =
            accountRepository ?? AccountRepository(),
        _paymentMethodRepository =
            paymentMethodRepository ??
                PaymentMethodRepository(),
        _settingsRepository =
            settingsRepository ?? SettingsRepository();

  Future<void> setup({
    required int bcpSoles,
    required int interbankSoles,
    required int cash,
    required int bcpDollars,
  }) async {
    final existingAccounts =
        await _accountRepository.getAll();

    if (existingAccounts.isNotEmpty) {
      throw StateError(
        'La configuración inicial ya fue realizada.',
      );
    }

    final bcp = await _accountRepository.insert(
      Account(
        name: 'BCP',
        currency: 'PEN',
        type: 'bank',
        initialBalance: bcpSoles,
      ),
    );

    final interbank =
        await _accountRepository.insert(
      Account(
        name: 'Interbank',
        currency: 'PEN',
        type: 'bank',
        initialBalance: interbankSoles,
      ),
    );

    final efectivo =
        await _accountRepository.insert(
      Account(
        name: 'Efectivo',
        currency: 'PEN',
        type: 'cash',
        initialBalance: cash,
      ),
    );

    final bcpDolares =
        await _accountRepository.insert(
      Account(
        name: 'BCP',
        currency: 'USD',
        type: 'bank',
        initialBalance: bcpDollars,
      ),
    );

    await _paymentMethodRepository.insert(
      accountId: bcp,
      name: 'BCP',
    );

    await _paymentMethodRepository.insert(
      accountId: bcp,
      name: 'Yape',
    );

    await _paymentMethodRepository.insert(
      accountId: interbank,
      name: 'Interbank',
    );

    await _paymentMethodRepository.insert(
      accountId: interbank,
      name: 'Plin',
    );

    await _paymentMethodRepository.insert(
      accountId: efectivo,
      name: 'Efectivo',
    );

    await _paymentMethodRepository.insert(
      accountId: bcpDolares,
      name: 'BCP dólares',
    );

    // Evitamos que el analizador considere que
    // el valor se calcula y no se utiliza.
    await _settingsRepository
        .markInitialSetupCompleted();
  }
}