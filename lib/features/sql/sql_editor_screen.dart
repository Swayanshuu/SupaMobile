import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../../widgets/supa_text_field.dart';
import '../../widgets/supa_button.dart';
import '../../widgets/supa_drawer.dart';
import '../../widgets/supa_card.dart';
import '../tables/tables_provider.dart';
import 'sql_editor_provider.dart';

class SqlEditorScreen extends ConsumerStatefulWidget {
  final String projectRef;
  const SqlEditorScreen({super.key, required this.projectRef});

  @override
  ConsumerState<SqlEditorScreen> createState() => _SqlEditorScreenState();
}

class _SqlEditorScreenState extends ConsumerState<SqlEditorScreen> {
  final _queryController = TextEditingController(text: 'SELECT * FROM auth.users LIMIT 10;');
  final _searchController = TextEditingController();
  int? _sortColumnIndex;
  bool _isAscending = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _showSaveDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgOverlay,
        title: const Text('Save Query'),
        content: SupaTextField(
          label: 'Query Name',
          controller: nameController,
          placeholder: 'e.g. List Users',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          SupaButton(
            text: 'Save',
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(sqlEditorProvider).saveQuery(
                  nameController.text,
                  _queryController.text,
                );
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Query saved successfully')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSavedQueries() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final savedAsync = ref.watch(savedQueriesProvider);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Icon(Icons.bookmarks_rounded, color: AppColors.supaGreen),
                    const SizedBox(width: 12),
                    Text('Saved Queries', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: savedAsync.when(
                  data: (queries) {
                    if (queries.isEmpty) {
                      return Center(child: Text('No saved queries yet', style: TextStyle(color: AppColors.textMuted)));
                    }
                    return ListView.builder(
                      itemCount: queries.length,
                      itemBuilder: (context, index) {
                        final name = queries.keys.elementAt(index);
                        final sql = queries[name]!;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(sql, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          onTap: () {
                            _queryController.text = sql;
                            Navigator.pop(context);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => ref.read(sqlEditorProvider).deleteQuery(name),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading queries')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTablesList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final tablesAsync = ref.watch(tableListProvider(widget.projectRef));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Icon(Icons.table_view_rounded, color: AppColors.supaGreen),
                    const SizedBox(width: 12),
                    Text('Insert Table Query', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: tablesAsync.when(
                  data: (tables) {
                    if (tables.isEmpty) {
                      return Center(child: Text('No tables found', style: TextStyle(color: AppColors.textMuted)));
                    }
                    return ListView.builder(
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final tableName = tables[index]['table_name'] as String;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: Icon(Icons.table_rows_rounded, color: AppColors.textMuted, size: 20),
                          title: Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('SELECT * FROM "$tableName" LIMIT 10;', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          onTap: () {
                            _queryController.text = 'SELECT * FROM "$tableName" LIMIT 10;';
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading tables')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultNotifier = ref.watch(sqlResultProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SupaAppBarSwitcher(
        title: 'SQL Editor',
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.table_view_rounded, color: AppColors.textPrimary),
            onPressed: _showTablesList,
            tooltip: 'Insert Table',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined, color: AppColors.supaGreen),
            onPressed: _showSavedQueries,
            tooltip: 'Saved Queries',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SupaCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.code_rounded, color: AppColors.supaGreen, size: 20),
                                const SizedBox(width: 8),
                                Text('SQL QUERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SupaTextField(
                              label: '',
                              controller: _queryController,
                              maxLines: 8,
                              isCode: true,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ValueListenableBuilder<AsyncValue<List<dynamic>?>>(
                                    valueListenable: resultNotifier,
                                    builder: (context, sqlState, _) {
                                      return SupaButton(
                                        text: 'Run Query',
                                        isLoading: sqlState is AsyncLoading,
                                        icon: Icons.play_arrow_rounded,
                                        onPressed: () {
                                          ref.read(sqlEditorProvider).executeQuery(widget.projectRef, _queryController.text);
                                        },
                                      );
                                    }
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SupaButton(
                                    text: 'Save',
                                    isSecondary: true,
                                    icon: Icons.save_outlined,
                                    onPressed: _showSaveDialog,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ValueListenableBuilder<AsyncValue<List<dynamic>?>>(
                        valueListenable: resultNotifier,
                        builder: (context, sqlState, _) {
                          return sqlState.when(
                            data: (results) {
                              if (results == null) return const SizedBox.shrink();
                              return _buildResultsSection(results);
                            },
                            loading: () => const Center(child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(),
                            )),
                            error: (e, s) => _buildErrorSection(e),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(List<dynamic> results) {
    if (results.isEmpty) {
      return SupaCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.supaGreen, size: 48),
            const SizedBox(height: 16),
            const Text('Query successful', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('0 rows returned', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final columns = (results.first as Map<String, dynamic>).keys.toList();

    // Apply Search
    var displayRows = results.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row.values.any((v) => v.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    // Apply Sorting
    if (_sortColumnIndex != null && _sortColumnIndex! < columns.length) {
      final colName = columns[_sortColumnIndex!];
      displayRows.sort((a, b) {
        final valA = a[colName];
        final valB = b[colName];
        if (valA == null) return 1;
        if (valB == null) return -1;
        final cmp = valA.toString().compareTo(valB.toString());
        return _isAscending ? cmp : -cmp;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.table_rows_rounded, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RESULTS (${displayRows.length} rows)', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              height: 36,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search results...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: AppColors.bgBase.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SupaCard(
          padding: EdgeInsets.zero,
          child: _buildResultsTable(displayRows, columns),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildErrorSection(Object e) {
    return SupaCard(
      color: Colors.red.withOpacity(0.05),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              const Text('SQL ERROR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(e.toString(), style: const TextStyle(color: Colors.red, fontFamily: 'JetBrains Mono', fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultsTable(List<dynamic> rows, List<String> columns) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.bgBase.withOpacity(0.5)),
        columnSpacing: 24,
        horizontalMargin: 24,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _isAscending,
        columns: columns
            .map((c) => DataColumn(
                  label: Text(c, style: const TextStyle(color: AppColors.supaGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ))
            .toList(),
        rows: rows.map((row) {
          final rowMap = row as Map<String, dynamic>;
          return DataRow(
            cells: columns
                .map((c) => DataCell(Text(rowMap[c]?.toString() ?? 'NULL',
                    style: TextStyle(color: AppColors.textPrimary.withOpacity(0.9), fontSize: 13))))
                .toList(),
          );
        }).toList(),
      ),
    );
  }
}
