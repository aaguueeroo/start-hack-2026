import 'package:start_hack_2026/domain/entities/store_item.dart';

/// Educational copy for store asset cards (what it is, how it behaves, risks).
class StoreAssetEducation {
  const StoreAssetEducation({
    required this.kind,
    required this.howItWorks,
    required this.risks,
  });

  final String kind;
  final String howItWorks;
  final String risks;

  static StoreAssetEducation forAsset(StoreItemAsset asset) {
    return _byId[asset.id] ?? _fallback(asset);
  }

  static final Map<String, StoreAssetEducation> _byId = {
    'cash_savings': const StoreAssetEducation(
      kind: 'Cash and bank savings',
      howItWorks:
          'Money sits in very safe accounts. In the simulation it barely grows; '
          'each purchase ties part of your portfolio to this “sleeping” line.',
      risks:
          'Inflation quietly erodes buying power when returns stay below price growth. '
          'Almost no market thrill — the risk is being left behind over long horizons.',
    ),
    'swiss_bonds': const StoreAssetEducation(
      kind: 'Government bonds (CHF)',
      howItWorks:
          'You lend to the Swiss state and earn steady coupon-like returns. '
          'Buys add this line to your mix; the engine blends its expected return and low volatility with the rest.',
      risks:
          'Still subject to rate moves and CHF concentration. '
          'Very low credit drama, but yields can lag riskier assets in strong markets.',
    ),
    'eu_bonds': const StoreAssetEducation(
      kind: 'Government bonds (EUR)',
      howItWorks:
          'Similar idea to Swiss bonds, but euro-area governments pay a bit more because investors demand extra yield.',
      risks:
          'Currency and policy differences vs CHF, plus normal bond sensitivity to interest rates. '
          'Generally safer than stocks, not the same as cash.',
    ),
    'corporate_bonds': const StoreAssetEducation(
      kind: 'Corporate bonds',
      howItWorks:
          'You lend to companies, not countries. Higher coupons than governments because default and spread risk exist. '
          'In-game, credit-risk and volatility sit between governments and equities.',
      risks:
          'If issuers struggle, prices can fall; spreads can widen in stress. '
          'More return potential than pure government paper, with a real credit story.',
    ),
    'reit': const StoreAssetEducation(
      kind: 'Real-estate fund (REIT)',
      howItWorks:
          'A pooled property vehicle: rent and valuations drive returns. '
          'Buys expose your tagged capital to that real-estate return/volatility profile.',
      risks:
          'Liquidity is weaker than large stock ETFs — selling fast can hurt. '
          'Rates, vacancies, and cycles still move prices; it is not a bond substitute.',
    ),
    'smi_fund': const StoreAssetEducation(
      kind: 'Swiss market index fund',
      howItWorks:
          'Broad basket of large Swiss companies in one fund. Diversified within Switzerland, '
          'cheap to run, and each buy routes a slice of your portfolio through its return engine.',
      risks:
          'Heavy home-country concentration: global shocks or a weak Swiss cycle hit you together. '
          'Equity volatility applies — drawdowns happen.',
    ),
    'world_etf': const StoreAssetEducation(
      kind: 'Global index fund',
      howItWorks:
          'Thousands of companies across regions in one holding. '
          'Great baseline for long-term growth; simulation rolls its expected return and volatility into your total.',
      risks:
          'You still ride full equity swings. '
          'Diversification lowers single-stock drama but not global market crashes.',
    ),
    'single_stocks': const StoreAssetEducation(
      kind: 'Single-company stocks',
      howItWorks:
          'Concentrated bets on individual firms. High headline returns in the card reflect upside scenarios; '
          'the sim stresses you with large volatility from that concentration.',
      risks:
          'Earnings misses, sector crashes, or fraud can slash value fast. '
          'Hardest diversification story — exciting, easy to misread as “skill”.',
    ),
    'gold': const StoreAssetEducation(
      kind: 'Gold / commodities',
      howItWorks:
          'Exposure to real assets that often zig when paper markets zag. '
          'Useful as a diversifier; in-game it carries its own return/volatility and cost drag.',
      risks:
          'No reliable yield — you live off price changes. '
          'Can lag stocks for years; storage and product fees nibble returns.',
    ),
    'crypto': const StoreAssetEducation(
      kind: 'Crypto (e.g. Bitcoin)',
      howItWorks:
          'Speculative digital asset sleeve. The card encodes very high upside and volatility assumptions; '
          'each buy makes that wilder path part of your tagged capital.',
      risks:
          'Extreme drawdowns, regulation, exchange, and technology risks. '
          'Treat as a small satellite, not a replacement for core investing.',
    ),
  };

  static StoreAssetEducation _fallback(StoreItemAsset asset) {
    final vol = asset.volatility;
    final volCue = vol >= 45
        ? 'Expect large, fast price swings.'
        : vol >= 18
        ? 'Expect meaningful ups and downs.'
        : 'Usually calmer than broad equities.';
    final credit = asset.creditRisk > 3
        ? ' Credit risk is material — issuers can disappoint.'
        : '';
    final fx = asset.currencyRisk > 2
        ? ' Currency moves can help or hurt vs your base.'
        : '';
    return StoreAssetEducation(
      kind: 'Portfolio line item',
      howItWorks:
          'Investing tags part of your capital to this asset. The simulation combines its expected return, '
          'volatility, costs, and liquidity with your other holdings each round.',
      risks: '$volCue$credit$fx',
    );
  }
}
