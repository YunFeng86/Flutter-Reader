import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings/reader_settings.dart';
import '../services/settings/reader_settings_store.dart';

final readerSettingsStoreProvider =
    Provider<ReaderSettingsStore>((ref) => ReaderSettingsStore());

class ReaderSettingsController extends AsyncNotifier<ReaderSettings> {
  @override
  Future<ReaderSettings> build() async {
    return ref.read(readerSettingsStoreProvider).load();
  }

  Future<void> save(ReaderSettings next) async {
    state = AsyncValue.data(next);
    await ref.read(readerSettingsStoreProvider).save(next);
  }
}

final readerSettingsProvider =
    AsyncNotifierProvider<ReaderSettingsController, ReaderSettings>(
  ReaderSettingsController.new,
);
