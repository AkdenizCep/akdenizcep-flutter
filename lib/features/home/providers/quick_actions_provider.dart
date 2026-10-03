import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quick_action.dart';
import '../services/quick_actions_service.dart';

final quickActionsServiceProvider = Provider((_) => QuickActionsService());

/// Ana sayfadaki hızlı erişim ızgarası. Her zaman tam
/// [kQuickActionSlotCount] öğedir. İlk okuma asenkron olduğu için başlangıç
/// değeri varsayılan ızgaradır; disk okuması bitince state güncellenir.
class QuickActionsNotifier extends StateNotifier<List<QuickAction>> {
  final QuickActionsService _service;

  QuickActionsNotifier(this._service) : super(kDefaultQuickActions) {
    _load();
  }

  Future<void> _load() async {
    try {
      final stored = await _service.load();
      if (!mounted) return;
      state = normalizeQuickActions(stored);
    } catch (_) {
      // Bozuk kayıt açılışı engellemez; varsayılan ızgara kalır.
    }
  }

  /// Seçimi uygular ve kalıcılaştırır. Eksik/fazla/tekrarlı liste ızgara
  /// değişmezini bozmasın diye normalize edilir.
  Future<void> setActions(List<QuickAction> actions) async {
    final next = normalizeQuickActions(actions.map((a) => a.name).toList());
    state = next;
    try {
      await _service.save(next);
    } catch (_) {
      // Yazılamayan seçim bu oturumda geçerli kalır.
    }
  }
}

final quickActionsProvider =
    StateNotifierProvider<QuickActionsNotifier, List<QuickAction>>((ref) {
      return QuickActionsNotifier(ref.watch(quickActionsServiceProvider));
    });
