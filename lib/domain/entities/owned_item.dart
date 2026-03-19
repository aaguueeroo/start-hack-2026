import 'package:start_hack_2026/domain/entities/store_item.dart';

class OwnedItem {
  const OwnedItem({
    required this.item,
    required this.slotIndex,
    required this.level,
  });

  final StoreItemItem item;
  final int slotIndex;
  final int level;

  String get id => item.id;
  String get name => item.name;
  String get icon => item.icon;
  Map<String, double> get statEffects => item.statEffects;
}
