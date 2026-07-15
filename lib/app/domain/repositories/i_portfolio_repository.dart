import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

abstract interface class IPortfolioRepository {
  Future<PortfolioDocument> load();
}
