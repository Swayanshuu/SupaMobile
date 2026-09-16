import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class InMemoryQueriesNotifier extends Notifier<List<SavedQuery>> {
  @override
  List<SavedQuery> build() => [];

  void add(SavedQuery query) {
    state = [...state, query];
  }

  void remove(String id) {
    state = state.where((q) => q.id != id).toList();
  }
}

final inMemoryQueriesProvider = NotifierProvider<InMemoryQueriesNotifier, List<SavedQuery>>(InMemoryQueriesNotifier.new);

final savedQueriesStreamProvider = StreamProvider<List<SavedQuery>>((ref) {
  return Stream.value(ref.watch(inMemoryQueriesProvider));
});

class SavedQueriesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> saveQuery(String name, String query, {String? projectRef}) async {
    final newQuery = SavedQuery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      query: query,
      projectRef: projectRef,
    );
    ref.read(inMemoryQueriesProvider.notifier).add(newQuery);
  }

  Future<void> deleteQuery(String id) async {
    ref.read(inMemoryQueriesProvider.notifier).remove(id);
  }
}

final savedQueriesActionsProvider = NotifierProvider<SavedQueriesNotifier, void>(SavedQueriesNotifier.new);
