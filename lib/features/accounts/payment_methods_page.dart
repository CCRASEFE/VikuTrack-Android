// lib/features/accounts/payment_methods_page.dart
import 'package:flutter/material.dart';

import '../../repositories/payment_method_repository.dart';

class PaymentMethodsPage extends StatefulWidget {
  final int accountId;
  final String accountName;

  const PaymentMethodsPage({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final _repository = PaymentMethodRepository();

  bool _loading = true;
  List<Map<String, Object?>> _methods = [];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final methods = await _repository.getByAccount(widget.accountId);

    if (!mounted) return;

    setState(() {
      _methods = methods;
      _loading = false;
    });
  }

  Future<void> _addMethod() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return const _AddPaymentMethodDialog();
      },
    );

    if (name == null || name.trim().isEmpty || !mounted) return;

    await _repository.insert(accountId: widget.accountId, name: name.trim());

    if (!mounted) return;
    await _loadMethods();
  }

  Future<void> _handleDeleteMethod(Map<String, Object?> method) async {
    final id = method['id'] as int;
    final name = method['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar medio de pago'),
          content: Text('¿Quieres eliminar "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final hasMovements = await _repository.hasMovements(id);

    if (hasMovements) {
      // Tiene movimientos -> Desactivar
      await _repository.deactivate(id);

      if (!mounted) return;
      await _loadMethods();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El medio "$name" tiene operaciones registradas. Se ha desactivado para proteger tu historial.'),
        ),
      );
    } else {
      // Sin movimientos -> Eliminar físicamente
      await _repository.delete(id);

      if (!mounted) return;
      await _loadMethods();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medio de pago "$name" eliminado definitivamente.')),
      );
    }
  }

  Future<void> _showInactiveMethods() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InactivePaymentMethodsPage(
          accountId: widget.accountId,
          accountName: widget.accountName,
        ),
      ),
    );

    if (!mounted) return;
    await _loadMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medios de pago — ${widget.accountName}'),
        actions: [
          IconButton(
            onPressed: _showInactiveMethods,
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Medios de pago desactivados',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _methods.isEmpty
          ? const Center(child: Text('No hay medios de pago.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _methods.length,
              itemBuilder: (context, index) {
                final method = _methods[index];
                final name = method['name'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text(name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _handleDeleteMethod(method);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMethod,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddPaymentMethodDialog extends StatefulWidget {
  const _AddPaymentMethodDialog();

  @override
  State<_AddPaymentMethodDialog> createState() =>
      _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _confirm() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo medio de pago'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          hintText: 'Ej. Yape',
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancelar')),
        FilledButton(onPressed: _confirm, child: const Text('Agregar')),
      ],
    );
  }
}

class _InactivePaymentMethodsPage extends StatefulWidget {
  final int accountId;
  final String accountName;

  const _InactivePaymentMethodsPage({
    required this.accountId,
    required this.accountName,
  });

  @override
  State<_InactivePaymentMethodsPage> createState() =>
      _InactivePaymentMethodsPageState();
}

class _InactivePaymentMethodsPageState
    extends State<_InactivePaymentMethodsPage> {
  final _repository = PaymentMethodRepository();

  bool _loading = true;
  List<Map<String, Object?>> _methods = [];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final methods = await _repository.getInactiveByAccount(widget.accountId);

    if (!mounted) return;

    setState(() {
      _methods = methods;
      _loading = false;
    });
  }

  Future<void> _activateMethod(Map<String, Object?> method) async {
    final id = method['id'] as int;
    final name = method['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reactivar medio de pago'),
          content: Text('¿Quieres reactivar "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reactivar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _repository.activate(id);

    if (!mounted) return;
    await _loadMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medios desactivados — ${widget.accountName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _methods.isEmpty
          ? const Center(child: Text('No hay medios de pago desactivados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _methods.length,
              itemBuilder: (context, index) {
                final method = _methods[index];
                final name = method['name'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.payment_outlined),
                    title: Text(name),
                    trailing: FilledButton.tonal(
                      onPressed: () => _activateMethod(method),
                      child: const Text('Reactivar'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
