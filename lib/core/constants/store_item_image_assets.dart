/// Maps store item ids to image asset paths for knowledge items and financial assets.
/// Returns null when unmapped; UI should fall back to icon.
class StoreItemImageAssets {
  StoreItemImageAssets._();

  static const String _knowledgeDir = 'assets/images/learning/';
  static const String _assetDir = 'assets/images/asset/';

  static const Map<String, String> _knowledgeBasenameById = {
    'read_book': 'book',
    'online_course': 'online_couse',
    'financial_advisor': 'speed_dial',
    'mindfulness': 'grass',
    'diversification_habit': 'eggs',
    'automate_investments': 'dca',
    'emergency_fund': 'need_cash',
  };

  static const Map<String, String> _assetBasenameById = {
    'cash_savings': 'piggy_bank',
    'swiss_bonds': 'army_knife',
    'eu_bonds': 'eurozone',
    'corporate_bonds': 'big_company',
    'reit': 'landlord_simulator',
    'world_etf': 'planet',
    'single_stocks': 'roulette',
    'gold': 'shiny_rock',
    'crypto': 'moon',
  };

  static String? imagePathForKnowledgeItem(String id) {
    final basename = _knowledgeBasenameById[id];
    if (basename == null) return null;
    return '$_knowledgeDir$basename.png';
  }

  static String? imagePathForStoreAsset(String id) {
    final basename = _assetBasenameById[id];
    if (basename == null) return null;
    return '$_assetDir$basename.png';
  }
}
