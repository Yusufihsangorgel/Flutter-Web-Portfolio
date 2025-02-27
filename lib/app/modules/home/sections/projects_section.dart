import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final RxList<ProjectWindow> _openWindows = <ProjectWindow>[].obs;
  final RxInt _activeWindowIndex = (-1).obs;

  @override
  void initState() {
    super.initState();
    // 1 saniye sonra pencere açma başlat (sayfa yüklendikten sonra)
    Future.delayed(const Duration(seconds: 1), () {
      _scheduleWindowOpenings();
    });
  }

  void _scheduleWindowOpenings() {
    final projects = languageController.cvData['projects'] ?? [];
    if (projects.isEmpty) return;

    // İlk 3 projeyi otomatik olarak aç (1'er saniye arayla)
    for (int i = 0; i < math.min(3, projects.length); i++) {
      Future.delayed(Duration(seconds: i), () {
        if (i < projects.length) {
          _openProjectWindow(
            projects[i],
            initialPosition: _getRandomPosition(i),
          );
        }
      });
    }
  }

  Offset _getRandomPosition(int index) {
    final random = math.Random();
    // Ekranın farklı bölgelerine dağıt
    double x = 100 + (random.nextDouble() * 200) + (index * 50);
    double y = 150 + (random.nextDouble() * 100) + (index * 30);
    return Offset(x, y);
  }

  void _openProjectWindow(
    Map<String, dynamic> project, {
    Offset? initialPosition,
  }) {
    final newWindowIndex = _openWindows.length;
    final window = ProjectWindow(
      project: project,
      initialPosition: initialPosition ?? const Offset(100, 150),
      windowIndex: newWindowIndex,
      onClose: () => _closeWindow(newWindowIndex),
      onActivate: () => _activateWindow(newWindowIndex),
    );

    _openWindows.add(window);
    _activateWindow(newWindowIndex);
  }

  void _closeWindow(int index) {
    if (index < _openWindows.length) {
      _openWindows.removeAt(index);

      // Pencere indekslerini yeniden düzenle
      for (int i = 0; i < _openWindows.length; i++) {
        _openWindows[i] = _openWindows[i].copyWith(windowIndex: i);
      }

      // Aktif pencereyi güncelle
      if (_activeWindowIndex.value >= _openWindows.length) {
        _activeWindowIndex.value =
            _openWindows.isEmpty ? -1 : _openWindows.length - 1;
      }
    }
  }

  void _activateWindow(int index) {
    if (index >= 0 && index < _openWindows.length) {
      _activeWindowIndex.value = index;

      // Aktif pencereyi listeye en son ekleyerek en üste getir
      final window = _openWindows[index];
      _openWindows.removeAt(index);
      _openWindows.add(window);

      // Pencere indekslerini yeniden düzenle
      for (int i = 0; i < _openWindows.length; i++) {
        _openWindows[i] = _openWindows[i].copyWith(windowIndex: i);
      }

      _activeWindowIndex.value = _openWindows.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      constraints: BoxConstraints(minHeight: screenHeight - 80),
      height: screenHeight - 80,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Masaüstü arkaplanı
          Positioned.fill(
            child: DesktopBackground(themeController: themeController),
          ),

          // Masaüstü alanı (projelerin sürüklenebileceği alan)
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Obx(() {
                      final isEnglish =
                          languageController.currentLanguage == 'en';
                      return ShimmeringText(
                        text: isEnglish ? 'Projects' : 'Projeler',
                        baseColor: Colors.white,
                        highlightColor: themeController.primaryColor,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 30),

                // Proje pencerelerinin alanı
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      // Proje simgeleri
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildProjectIcons(isMobile),
                      ),

                      // Açık pencereler
                      ..._buildOpenWindows(),
                    ],
                  ),
                ),

                // Alt bilgi çubuğu (taskbar)
                isMobile
                    ? const SizedBox.shrink()
                    : TaskBar(
                      openWindows: _openWindows,
                      activeWindowIndex: _activeWindowIndex.value,
                      onTaskClicked: _activateWindow,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectIcons(bool isMobile) {
    return Obx(() {
      final projects = languageController.cvData['projects'] ?? [];

      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: List.generate(projects.length, (index) {
          final project = projects[index];
          return DesktopIcon(
            title: project['title'] ?? '',
            icon: Icons.folder,
            color: themeController.primaryColor,
            onDoubleTap: () => _openProjectWindow(project),
          );
        }),
      );
    });
  }

  List<Widget> _buildOpenWindows() {
    return List.generate(_openWindows.length, (index) {
      final window = _openWindows[index];
      final isActive = index == _activeWindowIndex.value;

      return Positioned(
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: window.copyWith(isActive: isActive),
      );
    });
  }
}

// Masaüstü Simgesi
class DesktopIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onDoubleTap;

  const DesktopIcon({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HoverAnimatedWidget(
      hoverScale: 1.05,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Taskbar
class TaskBar extends StatelessWidget {
  final List<ProjectWindow> openWindows;
  final int activeWindowIndex;
  final Function(int) onTaskClicked;

  const TaskBar({
    Key? key,
    required this.openWindows,
    required this.activeWindowIndex,
    required this.onTaskClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Başlangıç butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {},
            ),
          ),

          // Açık uygulamalar
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(openWindows.length, (index) {
                  final window = openWindows[index];
                  final isActive = index == activeWindowIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: HoverAnimatedWidget(
                      hoverScale: 1.05,
                      child: InkWell(
                        onTap: () => onTaskClicked(window.windowIndex),
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.folder,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                window.project['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Saat
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TimeDisplay(),
          ),
        ],
      ),
    );
  }
}

// Saat gösterimi
class TimeDisplay extends StatefulWidget {
  const TimeDisplay({Key? key}) : super(key: key);

  @override
  State<TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<TimeDisplay> {
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _updateTime();
  }

  void _updateTime() {
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _updateTime();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }
}

// Masaüstü Arkaplanı
class DesktopBackground extends StatelessWidget {
  final ThemeController themeController;

  const DesktopBackground({Key? key, required this.themeController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Ana arkaplan
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A2237), const Color(0xFF0D1425)],
            ),
          ),
        ),

        // Doku/Izgara
        CustomPaint(
          painter: GridPainter(
            lineColor: themeController.primaryColor.withOpacity(0.15),
            gridSize: 30,
          ),
        ),

        // Parlama efektleri
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  themeController.primaryColor.withOpacity(0.3),
                  themeController.primaryColor.withOpacity(0),
                ],
                stops: const [0.2, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeController.primaryColor.withOpacity(0.2),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  themeController.secondaryColor.withOpacity(0.3),
                  themeController.secondaryColor.withOpacity(0),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Izgara
class GridPainter extends CustomPainter {
  final Color lineColor;
  final double gridSize;

  GridPainter({required this.lineColor, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 0.5;

    // Yatay çizgiler
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dikey çizgiler
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Proje Penceresi
class ProjectWindow extends StatefulWidget {
  final Map<String, dynamic> project;
  final Offset initialPosition;
  final int windowIndex;
  final bool isActive;
  final VoidCallback onClose;
  final VoidCallback onActivate;

  const ProjectWindow({
    Key? key,
    required this.project,
    required this.initialPosition,
    required this.windowIndex,
    this.isActive = true,
    required this.onClose,
    required this.onActivate,
  }) : super(key: key);

  ProjectWindow copyWith({
    Map<String, dynamic>? project,
    Offset? initialPosition,
    int? windowIndex,
    bool? isActive,
    VoidCallback? onClose,
    VoidCallback? onActivate,
  }) {
    return ProjectWindow(
      project: project ?? this.project,
      initialPosition: initialPosition ?? this.initialPosition,
      windowIndex: windowIndex ?? this.windowIndex,
      isActive: isActive ?? this.isActive,
      onClose: onClose ?? this.onClose,
      onActivate: onActivate ?? this.onActivate,
    );
  }

  @override
  State<ProjectWindow> createState() => _ProjectWindowState();
}

class _ProjectWindowState extends State<ProjectWindow>
    with SingleTickerProviderStateMixin {
  late Offset _position;
  late Size _size;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _size = const Size(450, 350);

    // Açılış animasyonu
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePosition(Offset delta) {
    setState(() {
      _position = _position.translate(delta.dx, delta.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onActivate,
              onPanStart: (details) {
                if (!widget.isActive) {
                  widget.onActivate();
                  return;
                }
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                if (_isDragging) {
                  _updatePosition(details.delta);
                }
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isActive ? 1.0 : 0.8,
                child: Container(
                  height: _size.height,
                  width: _size.width,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow:
                        widget.isActive
                            ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                            : [],
                    border: Border.all(
                      color:
                          widget.isActive
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pencere başlık çubuğu
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                              widget.isActive
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFF333333),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Kapat butonu
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5F57),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Küçült butonu
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFBD2E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tam ekran butonu
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFF28C841),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Pencere başlığı
                            Expanded(
                              child: Text(
                                widget.project['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),

                      // Proje içeriği
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Proje görüntüsü
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.insert_photo,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Proje bilgileri
                                _buildProjectDetail(
                                  title: 'Description:',
                                  content: widget.project['description'] ?? '',
                                ),

                                const SizedBox(height: 12),

                                // Kullanılan teknolojiler
                                _buildProjectDetail(
                                  title: 'Technologies:',
                                  content: widget.project['technologies'] ?? '',
                                ),

                                const SizedBox(height: 16),

                                // Proje linki
                                if (widget.project['link'] != null)
                                  Center(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.link),
                                      label: const Text('Visit Project'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: const Color(
                                          0xFF007AFF,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectDetail({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// Parlayan metin
class ShimmeringText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color highlightColor;
  final TextStyle style;

  const ShimmeringText({
    Key? key,
    required this.text,
    required this.baseColor,
    required this.highlightColor,
    required this.style,
  }) : super(key: key);

  @override
  State<ShimmeringText> createState() => _ShimmeringTextState();
}

class _ShimmeringTextState extends State<ShimmeringText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerController.value,
              ),
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

// Shader transformasyonu
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 3 - 1.0),
      0.0,
      0.0,
    );
  }
}

class Timer {
  final Duration duration;
  final VoidCallback callback;

  Timer(this.duration, this.callback);

  void cancel() {}
}
