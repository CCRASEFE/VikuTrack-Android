import 'package:flutter/material.dart';

import '../../services/initial_setup_service.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final _bcpSolesController = TextEditingController();
  final _interbankSolesController = TextEditingController();
  final _cashController = TextEditingController();
  final _bcpDollarsController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _bcpSolesController.dispose();
    _interbankSolesController.dispose();
    _cashController.dispose();
    _bcpDollarsController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) {
      return;
    }

    final bcpSoles =
        double.tryParse(_bcpSolesController.text.trim());

    final interbankSoles =
        double.tryParse(_interbankSolesController.text.trim());

    final cash =
        double.tryParse(_cashController.text.trim());

    final bcpDollars =
        double.tryParse(_bcpDollarsController.text.trim());

    if (bcpSoles == null ||
        interbankSoles == null ||
        cash == null ||
        bcpDollars == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un saldo válido en todos los campos.',
          ),
        ),
      );

      return;
    }

    if (bcpSoles < 0 ||
        interbankSoles < 0 ||
        cash < 0 ||
        bcpDollars < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los saldos no pueden ser negativos.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service = InitialSetupService();

      await service.setup(
        bcpSoles: (bcpSoles * 100).round(),
        interbankSoles: (interbankSoles * 100).round(),
        cash: (cash * 100).round(),
        bcpDollars: (bcpDollars * 100).round(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configuración inicial guardada correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo completar la configuración: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _amountField({
    required String label,
    required String prefix,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '$prefix ',
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración inicial'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Comencemos desde cero',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ingresa los saldos con los que comenzarás '
                'a utilizar la aplicación.',
              ),
              const SizedBox(height: 28),
              _amountField(
                label: 'BCP — Soles',
                prefix: 'S/',
                controller: _bcpSolesController,
              ),
              const SizedBox(height: 16),
              _amountField(
                label: 'Interbank — Soles',
                prefix: 'S/',
                controller: _interbankSolesController,
              ),
              const SizedBox(height: 16),
              _amountField(
                label: 'Efectivo',
                prefix: 'S/',
                controller: _cashController,
              ),
              const SizedBox(height: 16),
              _amountField(
                label: 'BCP — Dólares',
                prefix: '\$',
                controller: _bcpDollarsController,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _continue,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('CONTINUAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}