import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

/// Uygulama genelinde kaydırma işlemlerini yöneten controller sınıfı.
/// Bölümler arası geçişleri ve animasyonlu kaydırma işlemlerini yönetir.
class AppScrollController extends GetxController {
  static AppScrollController get to => Get.find();

  // Bölüm anahtarları
  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final experienceKey = GlobalKey();
  final projectsKey = GlobalKey();
  final skillsKey = GlobalKey();
  final contactKey = GlobalKey();

  // Scroll Controller
  final ScrollController scrollController = ScrollController();

  // Aktif bölüm
  final RxString activeSection = 'home'.obs;

  // Bölüm verilerini saklamak için yapı
  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};

  // Manuel scroll kontrolü
  bool _isManualScrolling = false;

  // Timer'lar
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    // ScrollController dinleyicisi ekle
    scrollController.addListener(_handleScroll);

    // Periyodik olarak bölüm bilgilerini güncelle (sayfa yüklendikten sonra)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSectionInfo();
      _periodicTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (_) => _updateSectionInfo(),
      );
    });
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    super.onClose();
  }

  /// Bölümlerin konum ve boyut bilgilerini günceller
  void _updateSectionInfo() {
    _updateKeyInfo('home', homeKey);
    _updateKeyInfo('about', aboutKey);
    _updateKeyInfo('experience', experienceKey);
    _updateKeyInfo('projects', projectsKey);
    _updateKeyInfo('skills', skillsKey);
    _updateKeyInfo('contact', contactKey);
  }

  /// Belirli bir anahtar için konum ve boyut bilgisini günceller
  void _updateKeyInfo(String sectionId, GlobalKey key) {
    if (key.currentContext != null) {
      final RenderBox renderBox =
          key.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      _sectionOffsets[sectionId] = position.dy;
      _sectionHeights[sectionId] = renderBox.size.height;
    }
  }

  /// Scroll pozisyonu değiştiğinde çağrılır
  void _handleScroll() {
    // Manuel scroll devam ediyorsa, aktif bölüm güncellemeyi atla
    if (_isManualScrolling) return;

    // ScrollController kontrolü
    if (!scrollController.hasClients) {
      debugPrint('Scroll error: ScrollController has no clients');
      return;
    }

    // 100ms debounce ile aktif bölümü güncelle (daha hızlı tepki versin)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _detectActiveSection();
    });
  }

  /// Görünür bölüme göre aktif bölümü günceller
  void _detectActiveSection() {
    if (!scrollController.hasClients || _sectionOffsets.isEmpty) return;

    try {
      // AppBar yüksekliği ve ekran boyutları
      const appBarHeight = 80.0;
      final screenHeight = Get.height;

      // Scroll pozisyonu kontrolü
      if (scrollController.positions.isEmpty) {
        debugPrint('Scroll error: No positions available');
        return;
      }

      // Görünür bölge
      final scrollPosition = scrollController.offset;
      final visibleTop = scrollPosition + appBarHeight;
      final visibleBottom = visibleTop + screenHeight - appBarHeight;
      final visibleMiddle = visibleTop + (screenHeight - appBarHeight) / 2;

      // Görünürlük yüzdesi ve mesafe bazında puanlama için
      final Map<String, double> sectionScores = {};

      // Her bölüm için puan hesapla
      _sectionOffsets.forEach((sectionId, offsetTop) {
        final height =
            _sectionHeights[sectionId] ?? 600; // Varsayılan yükseklik
        final offsetBottom = offsetTop + height;

        // Görünür bölge ile kesişim
        final visibleStart = math.max(offsetTop, visibleTop);
        final visibleEnd = math.min(offsetBottom, visibleBottom);

        // Bölüm görünür alanda mı?
        if (visibleEnd > visibleStart) {
          // Görünür kısım (piksel olarak)
          final visibleAmount = visibleEnd - visibleStart;

          // Bölümün ne kadarı görünür (0.0 - 1.0)
          final visibilityPercentage = visibleAmount / height;

          // Bölümün ortasının görünür bölgenin ortasına olan mesafesi
          final sectionMiddle = offsetTop + height / 2;
          final distanceFromMiddle = (sectionMiddle - visibleMiddle).abs();
          final normalizedDistance =
              1.0 - math.min(1.0, distanceFromMiddle / (screenHeight / 2));

          // Toplam puan: görünürlük + ekranın ortasına yakınlık
          sectionScores[sectionId] =
              (visibilityPercentage * 0.7) + (normalizedDistance * 0.3);
        }
      });

      // Puan olmayan bölüm varsa, ekranın dışında demektir
      if (sectionScores.isEmpty) {
        // Görünür bölgeye en yakın bölümü seç
        String closestSection = 'home';
        double minDistance = double.infinity;

        _sectionOffsets.forEach((sectionId, offsetTop) {
          final height = _sectionHeights[sectionId] ?? 0;
          final sectionMiddle = offsetTop + height / 2;
          final distance = (sectionMiddle - visibleMiddle).abs();

          if (distance < minDistance) {
            minDistance = distance;
            closestSection = sectionId;
          }
        });

        if (activeSection.value != closestSection) {
          debugPrint(
            'En yakın bölüm seçildi: ${activeSection.value} -> $closestSection',
          );
          activeSection.value = closestSection;
        }

        return;
      }

      // En yüksek puanlı bölümü bul
      final bestSectionEntry = sectionScores.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      final bestSection = bestSectionEntry.key;

      // Aktif bölüm değiştiyse güncelle
      if (activeSection.value != bestSection) {
        debugPrint(
          'Aktif bölüm değişiyor: ${activeSection.value} -> $bestSection (puan: ${bestSectionEntry.value.toStringAsFixed(2)})',
        );
        activeSection.value = bestSection;
      }
    } catch (e) {
      debugPrint('Scroll error: $e');
    }
  }

  /// Belirli bir bölüme kaydırır
  void scrollToSection(String sectionId) {
    try {
      // ScrollController kontrolü
      if (!scrollController.hasClients) {
        debugPrint('ScrollController hazır değil');
        return;
      }

      // Doğru GlobalKey'i bul
      GlobalKey? sectionKey;
      switch (sectionId) {
        case 'home':
          sectionKey = homeKey;
          break;
        case 'about':
          sectionKey = aboutKey;
          break;
        case 'experience':
          sectionKey = experienceKey;
          break;
        case 'projects':
          sectionKey = projectsKey;
          break;
        case 'skills':
          sectionKey = skillsKey;
          break;
        case 'contact':
          sectionKey = contactKey;
          break;
        default:
          debugPrint('Geçersiz bölüm ID: $sectionId');
          return;
      }

      // Context kontrolü
      if (sectionKey.currentContext == null) {
        debugPrint('$sectionId bölümü bulunamadı');
        return;
      }

      // Manuel scroll başlat
      _isManualScrolling = true;

      // Hemen aktif bölümü güncelle (UI yanıt versin)
      activeSection.value = sectionId;

      // Daha doğru bir yaklaşımla bölüm pozisyonunu hesapla
      final RenderBox renderBox =
          sectionKey.currentContext!.findRenderObject() as RenderBox;
      final Size screenSize = Get.size;

      // AppBar yüksekliği
      const appBarHeight = 80.0;

      // Bölümün global pozisyonu
      final position = renderBox.localToGlobal(Offset.zero);

      // Bölümün boyutu
      final size = renderBox.size;

      // Mevcut scroll pozisyonu
      final currentScrollPosition = scrollController.offset;

      // Ekran yüksekliği (AppBar'ı çıkararak)
      final viewportHeight = screenSize.height - appBarHeight;

      // Bölümün şu anki global y pozisyonu (AppBar'ı hesaba katarak)
      final currentGlobalY = position.dy;

      // Bölümün olması gereken pozisyon hesaplaması - ekranın ortasında olacak şekilde
      final targetGlobalY = appBarHeight + (viewportHeight - size.height) / 2;

      // Scroll miktarını hesapla
      // (Mevcut global pozisyon) - (Olması gereken global pozisyon) + (Mevcut scroll)
      double targetScrollOffset =
          currentGlobalY - targetGlobalY + currentScrollPosition;

      // Scroll sınırları içinde kaldığından emin ol
      targetScrollOffset = math.max(0, targetScrollOffset);

      if (scrollController.position.maxScrollExtent > 0) {
        targetScrollOffset = math.min(
          targetScrollOffset,
          scrollController.position.maxScrollExtent,
        );
      }

      debugPrint('$sectionId bölümüne kaydırılıyor: $targetScrollOffset');

      // Animasyonlu kaydırma
      scrollController
          .animateTo(
            targetScrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          )
          .then((_) {
            _finishScrolling();
          });
    } catch (e) {
      debugPrint('Scroll hatası: $e');
      _isManualScrolling = false;
    }
  }

  // Kaydırma işlemini tamamla
  void _finishScrolling() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _isManualScrolling = false;
      // Bölüm bilgilerini güncelle
      _updateSectionInfo();
      // Aktif bölümü tekrar kontrol et
      _detectActiveSection();
      debugPrint('Kaydırma tamamlandı');
    });
  }
}
