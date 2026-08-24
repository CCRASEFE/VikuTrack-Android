// ==========================================
// ARCHIVO: lib/features/settings/categories_page.dart
// ==========================================

import 'package:flutter/material.dart';

import '../../repositories/category_repository.dart';
import '../../repositories/subcategory_repository.dart';
import '../../services/category_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final SubcategoryRepository _subcategoryRepository = SubcategoryRepository();
  final CategoryService _categoryService = CategoryService();

  List<Map<String, Object?>> _categories = [];
  bool _loading = true;

  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _showInactiveCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InactiveCategoriesPage(categoryService: _categoryService),
      ),
    );

    if (!mounted) return;
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryRepository.getAll();

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  List<Map<String, Object?>> get _filteredCategories {
    if (_filterType == 'all') return _categories;
    return _categories.where((c) => c['type'] == _filterType).toList();
  }

  Future<void> _createCategory() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController();
        String type = _filterType == 'income' ? 'income' : 'expense';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Alimentación o Sueldo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                      DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        type = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(dialogContext).pop({'name': name, 'type': type});
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await _categoryRepository.insert(
      name: result['name']!,
      type: result['type']!,
    );

    if (!mounted) return;
    await _loadCategories();
  }

  Future<void> _editCategory(
    int id,
    String currentName,
    String currentType,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController(text: currentName);
        String type = currentType;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                      DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        type = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(dialogContext).pop({'name': name, 'type': type});
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await _categoryRepository.update(
      id: id,
      name: result['name']!,
      type: result['type']!,
    );

    if (!mounted) return;
    await _loadCategories();
  }

  Future<void> _handleDeleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text('¿Quieres eliminar la categoría "$name"?'),
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

    if (confirmed != true) return;

    final physicallyDeleted = await _categoryService.deleteOrDeactivateCategory(id);

    if (!mounted) return;
    await _loadCategories();

    if (!mounted) return;
    if (physicallyDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoría "$name" eliminada definitivamente.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La categoría "$name" contiene operaciones registradas. Se ha desactivado para proteger tu historial.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _createSubcategory(int categoryId, String categoryName) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController();

        return AlertDialog(
          title: const Text('Nueva subcategoría'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Restaurantes',
              helperText: 'Categoría: $categoryName',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await _subcategoryRepository.insert(categoryId: categoryId, name: result);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editSubcategory(int id, String currentName) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController(text: currentName);

        return AlertDialog(
          title: const Text('Editar subcategoría'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await _subcategoryRepository.update(id: id, name: result);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleDeleteSubcategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar subcategoría'),
          content: Text('¿Quieres eliminar la subcategoría "$name"?'),
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

    if (confirmed != true) return;

    final physicallyDeleted = await _categoryService.deleteOrDeactivateSubcategory(id);

    if (!mounted) return;
    setState(() {});

    if (!mounted) return;
    if (physicallyDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subcategoría "$name" eliminada definitivamente.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La subcategoría "$name" contiene gastos registrados. Se ha desactivado para proteger tu historial.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showInactiveSubcategories(
    int categoryId,
    String categoryName,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InactiveSubcategoriesPage(
          categoryService: _categoryService,
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Widget _buildSubcategoriesList(int categoryId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Map<String, Object?>>>(
      future: _subcategoryRepository.getByCategory(categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        final subcategories = snapshot.data ?? [];

        if (subcategories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Sin subcategorías agregadas.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subcategories.map((sub) {
              final subId = sub['id'] as int;
              final subName = sub['name']?.toString() ?? '';

              return Chip(
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide(color: colorScheme.outlineVariant),
                label: Text(
                  subName,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
                deleteIcon: Icon(Icons.more_horiz, size: 16, color: colorScheme.onSurfaceVariant),
                onDeleted: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (sheetContext) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: Text('Editar "$subName"'),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _editSubcategory(subId, subName);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Eliminar "$subName"', style: const TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _handleDeleteSubcategory(subId, subName);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFilterSelector() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'all',
          label: Text('Todas (${_categories.length})'),
        ),
        ButtonSegment(
          value: 'expense',
          label: Text('Gastos (${_categories.where((c) => c['type'] == 'expense').length})'),
          icon: const Icon(Icons.arrow_upward, size: 16, color: Colors.redAccent),
        ),
        ButtonSegment(
          value: 'income',
          label: Text('Ingresos (${_categories.where((c) => c['type'] == 'income').length})'),
          icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.green),
        ),
      ],
      selected: {_filterType},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        setState(() {
          _filterType = selection.first;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'inactive') {
                _showInactiveCategories();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'inactive',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Categorías desactivadas'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterSelector(),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay categorías en esta sección.\nCrea una nueva categoría con el botón inferior.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map((category) {
                    final id = category['id'] as int;
                    final name = category['name']?.toString() ?? '';
                    final type = category['type']?.toString() ?? '';
                    final isIncome = type == 'income';

                    // Tarjeta de Ingreso
                    if (isIncome) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.green.shade900.withAlpha(100) : Colors.green.shade50,
                            child: Icon(
                              Icons.arrow_downward,
                              color: isDark ? Colors.greenAccent : Colors.green,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Ingreso',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editCategory(id, name, type);
                              } else if (value == 'delete') {
                                _handleDeleteCategory(id, name);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Editar'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline, color: Colors.red),
                                  title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Tarjeta de Gasto
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? Colors.red.shade900.withAlpha(100) : Colors.red.shade50,
                          child: Icon(
                            Icons.arrow_upward,
                            color: isDark ? Colors.redAccent.shade100 : Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Gasto · Toca para ver subcategorías',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editCategory(id, name, type);
                            } else if (value == 'delete') {
                              _handleDeleteCategory(id, name);
                            } else if (value == 'inactive_subcategories') {
                              _showInactiveSubcategories(id, name);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Editar'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline, color: Colors.red),
                                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'inactive_subcategories',
                              child: ListTile(
                                leading: Icon(Icons.restore_from_trash),
                                title: Text('Subcategorías desactivadas'),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          _buildSubcategoriesList(id),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _createSubcategory(id, name),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Nueva subcategoría'),
                                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        icon: const Icon(Icons.add),
        label: const Text('Categoría'),
      ),
    );
  }
}

class _InactiveCategoriesPage extends StatefulWidget {
  final CategoryService categoryService;

  const _InactiveCategoriesPage({required this.categoryService});

  @override
  State<_InactiveCategoriesPage> createState() => _InactiveCategoriesPageState();
}

class _InactiveCategoriesPageState extends State<_InactiveCategoriesPage> {
  List<Map<String, Object?>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInactiveCategories();
  }

  Future<void> _loadInactiveCategories() async {
    final categories = await widget.categoryService.getInactiveCategories();

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _reactivateCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reactivar categoría'),
          content: Text(
            '¿Quieres reactivar la categoría "$name"?\n\n'
            'También se reactivarán todas las subcategorías que contiene.',
          ),
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

    if (confirmed != true) return;

    await widget.categoryService.reactivateCategory(id);

    if (!mounted) return;
    await _loadInactiveCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías desactivadas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No hay categorías desactivadas.', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final id = category['id'] as int;
                final name = category['name']?.toString() ?? '';
                final type = category['type']?.toString() ?? '';
                final typeLabel = type == 'income' ? 'Ingreso' : 'Gasto';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.folder_off_outlined),
                    title: Text(name, style: TextStyle(color: colorScheme.onSurface)),
                    subtitle: Text('$typeLabel · Desactivada', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    trailing: FilledButton.tonal(
                      onPressed: () => _reactivateCategory(id, name),
                      child: const Text('Reactivar'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InactiveSubcategoriesPage extends StatefulWidget {
  final CategoryService categoryService;
  final int categoryId;
  final String categoryName;

  const _InactiveSubcategoriesPage({
    required this.categoryService,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<_InactiveSubcategoriesPage> createState() => _InactiveSubcategoriesPageState();
}

class _InactiveSubcategoriesPageState extends State<_InactiveSubcategoriesPage> {
  List<Map<String, Object?>> _subcategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInactiveSubcategories();
  }

  Future<void> _loadInactiveSubcategories() async {
    final subcategories = await widget.categoryService.getInactiveSubcategories(widget.categoryId);

    if (!mounted) return;

    setState(() {
      _subcategories = subcategories;
      _loading = false;
    });
  }

  Future<void> _reactivateSubcategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reactivar subcategoría'),
          content: Text('¿Quieres reactivar la subcategoría "$name"?'),
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

    if (confirmed != true) return;

    await widget.categoryService.reactivateSubcategory(id);

    if (!mounted) return;
    await _loadInactiveSubcategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Subcategorías desactivadas — ${widget.categoryName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subcategories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No hay subcategorías desactivadas.', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = _subcategories[index];
                final id = subcategory['id'] as int;
                final name = subcategory['name']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.subdirectory_arrow_right),
                    title: Text(name, style: TextStyle(color: colorScheme.onSurface)),
                    subtitle: Text(widget.categoryName, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    trailing: FilledButton.tonal(
                      onPressed: () => _reactivateSubcategory(id, name),
                      child: const Text('Reactivar'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}