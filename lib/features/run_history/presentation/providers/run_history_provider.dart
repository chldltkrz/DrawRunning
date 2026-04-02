import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/run_history_repository.dart';
import '../../domain/entities/run_record.dart';

final runHistoryRepositoryProvider = Provider<RunHistoryRepository>((ref) {
  return RunHistoryRepository();
});

class RunHistoryNotifier extends StateNotifier<AsyncValue<List<RunRecord>>> {
  final RunHistoryRepository _repository;

  RunHistoryNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadRuns() async {
    state = const AsyncValue.loading();
    try {
      final runs = await _repository.getAllRuns();
      state = AsyncValue.data(runs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRun(RunRecord record) async {
    try {
      await _repository.insertRun(record);
      await loadRuns();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRun(int id) async {
    try {
      await _repository.deleteRun(id);
      await loadRuns();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final runHistoryProvider =
    StateNotifierProvider<RunHistoryNotifier, AsyncValue<List<RunRecord>>>(
  (ref) {
    final repository = ref.watch(runHistoryRepositoryProvider);
    final notifier = RunHistoryNotifier(repository);
    notifier.loadRuns();
    return notifier;
  },
);
