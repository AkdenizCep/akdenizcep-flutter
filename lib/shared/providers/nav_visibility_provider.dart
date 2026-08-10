import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alt navigasyon çubuğunun görünürlüğünü kontrol eder.
/// Bir modal bottom sheet gibi tam ekran alt katman açıldığında
/// nav bar'ın üzerine binmemesi için geçici olarak gizlenir.
final bottomNavVisibleProvider = StateProvider<bool>((_) => true);

/// Sabit alt CTA barı olan tam ekran sayfalar için: sayfa açıkken nav barını
/// gizler, kapanınca geri getirir.
///
/// Provider değişimi hem açılışta hem kapanışta frame sonrasına ertelenir;
/// build ya da widget ağacı sökülürken provider'a yazmak exception fırlatır.
mixin HidesBottomNav<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container ??= ProviderScope.containerOf(context, listen: false);
    _setNavVisible(false);
  }

  @override
  void dispose() {
    _setNavVisible(true);
    super.dispose();
  }

  void _setNavVisible(bool visible) {
    final container = _container;
    if (container == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      container.read(bottomNavVisibleProvider.notifier).state = visible;
    });
  }
}
