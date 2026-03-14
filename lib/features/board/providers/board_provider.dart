import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/board_item.dart';
import '../services/board_service.dart';

final boardServiceProvider = Provider((_) => BoardService());

final boardItemsProvider = StreamProvider<List<BoardItem>>((ref) {
  return ref.watch(boardServiceProvider).getItems();
});
