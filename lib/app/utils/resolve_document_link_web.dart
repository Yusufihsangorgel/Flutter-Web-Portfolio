import 'package:web/web.dart' as web;

/// Resolves document links against the HTML base, not the browser's current URL.
Uri resolveDocumentLink(Uri uri) {
  if (uri.hasScheme ||
      uri.hasAuthority ||
      uri.path.isEmpty ||
      uri.path.startsWith('/')) {
    return uri;
  }
  return Uri.parse(web.document.baseURI).resolveUri(uri);
}
