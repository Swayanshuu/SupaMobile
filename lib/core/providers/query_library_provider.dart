import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class SavedQuery {
  final String id;
  final String name;
  final String query;
  final String? projectRef;

  SavedQuery({
    required this.id,
    required this.name,
    required this.query,
    this.projectRef,
  });

  factory SavedQuery.fromJson(Map<String, dynamic> json) {
    return SavedQuery(
      id: json['id'],
      name: json['name'],
      query: json['query'],
      projectRef: json['project_ref'],
    );
  }
}

final savedQueriesProvider = StreamProvider<List<SavedQuery>>((ref) {
  return Stream.value(ref.watch(_inMemoryQueriesProvider));
});

final _inMemoryQueriesProvider = StateProvider<List<SavedQuery>>((ref) => []);

class SavedQueriesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> saveQuery(
    String name,
    String query, {
    String? projectRef,
  }) async {
    final newQuery = SavedQuery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      query: query,
      projectRef: projectRef,
    );

    final current = ref.read(_inMemoryQueriesProvider);
    ref.read(_inMemoryQueriesProvider.notifier).state = [...current, newQuery];
  }

  Future<void> deleteQuery(String id) async {
    final current = ref.read(_inMemoryQueriesProvider);
    ref.read(_inMemoryQueriesProvider.notifier).state = current
        .where((q) => q.id != id)
        .toList();
  }
}

final savedQueriesActionsProvider =
    NotifierProvider<SavedQueriesNotifier, void>(() => SavedQueriesNotifier());
