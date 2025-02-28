import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// URL'leri açmak için yardımcı sınıf
class UrlLauncherUtils {
  /// URL'yi harici bir uygulamada açar
  ///
  /// [url] Açılacak URL
  /// [onSuccess] URL başarıyla açıldığında çağrılacak fonksiyon
  /// [onError] URL açılamazsa çağrılacak fonksiyon
  static Future<void> openUrl({
    required String url,
    Function()? onSuccess,
    Function(String error)? onError,
  }) async {
    if (url.isEmpty) return;

    try {
      // URL'nin doğru bir şemaya sahip olduğundan emin olma
      String urlString = url;
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://') &&
          !urlString.startsWith('mailto:') &&
          !urlString.startsWith('tel:')) {
        urlString = 'https://$urlString';
      }

      final uri = Uri.parse(urlString);

      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
        onSuccess?.call();
      } else {
        onError?.call('Could not launch $urlString');
      }
    } catch (e) {
      onError?.call('Error launching URL: $e');
    }
  }
}
