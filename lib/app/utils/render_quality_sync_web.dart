import 'package:web/web.dart' as web;

void syncRenderQualityAttributes({
  required String quality,
  required String reason,
}) {
  final root = web.document.documentElement;
  root?.setAttribute('data-render-quality', quality);
  root?.setAttribute('data-render-quality-reason', reason);
}
