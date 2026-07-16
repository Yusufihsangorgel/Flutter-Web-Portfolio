import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_portfolio_repository.dart';

final class PortfolioRepositoryImpl implements IPortfolioRepository {
  factory PortfolioRepositoryImpl({required IAssetsProvider assetsProvider}) =>
      PortfolioRepositoryImpl._(assetsProvider);

  const PortfolioRepositoryImpl._(this._assetsProvider);

  final IAssetsProvider _assetsProvider;

  @override
  Future<PortfolioDocument> load() async =>
      PortfolioDocument.fromJson(await _assetsProvider.loadPortfolio());
}
