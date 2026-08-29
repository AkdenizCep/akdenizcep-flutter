import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/user_provider.dart';
import '../models/lost_found_item.dart';
import '../services/lost_found_service.dart';

final lostFoundServiceProvider = Provider((_) => LostFoundService());

final lostFoundItemsProvider = StreamProvider<List<LostFoundItem>>((ref) {
  return ref.watch(lostFoundServiceProvider).getItems();
});

enum LostFoundTypeFilter { all, lost, found }

final lostFoundTypeFilterProvider = StateProvider<LostFoundTypeFilter>(
  (_) => LostFoundTypeFilter.all,
);

/// "İlanlarım" görünümü — yalnızca kullanıcının kendi ilanlarını gösterir.
/// Bu görünümdeyken çözülmüş ilanlar da dahil edilir, çünkü sahibinin kendi
/// geçmiş ilanını yönetebilmesi (yeniden açma dahil) gerekir. Genel gezinme
/// modunda ise çözülmüş ilanlar varsayılan olarak gizlenir.
final showMyListingsOnlyProvider = StateProvider<bool>((_) => false);

final filteredLostFoundItemsProvider = Provider<List<LostFoundItem>>((ref) {
  final items = ref.watch(lostFoundItemsProvider).valueOrNull ?? const [];
  final typeFilter = ref.watch(lostFoundTypeFilterProvider);
  final myListingsOnly = ref.watch(showMyListingsOnlyProvider);
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

  return items.where((item) {
    if (myListingsOnly) {
      if (currentUserId == null || item.authorUid != currentUserId) {
        return false;
      }
    } else if (item.isResolved) {
      return false;
    }

    return switch (typeFilter) {
      LostFoundTypeFilter.all => true,
      LostFoundTypeFilter.lost => item.isLost,
      LostFoundTypeFilter.found => !item.isLost,
    };
  }).toList();
});
