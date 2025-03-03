import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../painters/rocket_light_reflection_painter.dart';

class RocketWidget extends StatelessWidget {
  final AnimationController animController;
  final bool isDragging;

  const RocketWidget({
    Key? key,
    required this.animController,
    this.isDragging = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        // 3D efekti için perspektif açısı
        final perspectiveAngle = math.sin(animController.value * math.pi) * 0.1;

        // Işık açısı - zamanla değişen
        final lightAngle = animController.value * math.pi * 2;
        final lightX = math.cos(lightAngle) * 0.5;
        final lightY = math.sin(lightAngle) * 0.5;

        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspektif efekti için
                ..rotateX(perspectiveAngle)
                ..rotateY(perspectiveAngle * 0.7),
          alignment: Alignment.center,
          child: SizedBox(
            height: 100,
            width: 50,
            child: Stack(
              children: [
                // Roket gövdesi - metalik görünüm
                Positioned(
                  top: 20,
                  left: 10,
                  right: 10,
                  bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors:
                            isDragging
                                ? [
                                  const Color(0xFFF5F5F5), // Daha parlak beyaz
                                  const Color(0xFFE0E0E0), // Açık gri
                                  const Color(0xFFBDBDBD), // Orta gri
                                ]
                                : const [
                                  Color(0xFFE0E0E0), // Açık gri
                                  Color(0xFF9E9E9E), // Gri
                                  Color(0xFFBDBDBD), // Orta gri
                                ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDragging
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5),
                          blurRadius: isDragging ? 8 : 5,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Roket detayları - çizgiler
                          Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Roket burnu - metalik koni
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors: const [
                          Color(0xFFE0E0E0), // Açık gri
                          Color(0xFFBDBDBD), // Orta gri
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    // Burun üzerinde parlak nokta
                    child: Align(
                      alignment: Alignment(lightX * 2, lightY * 2),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),

                // Roket penceresi - parlak cam efekti
                Positioned(
                  top: 30,
                  left: 15,
                  child: Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors: [
                          Colors.lightBlue.shade100,
                          Colors.lightBlue.shade300,
                        ],
                      ),
                      border: Border.all(color: Colors.white70, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlue.shade200.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    // Pencere üzerinde parlak nokta
                    child: Align(
                      alignment: Alignment(lightX, lightY),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Roket kanatları - sol
                Positioned(
                  bottom: 15,
                  left: 0,
                  child: Transform(
                    transform: Matrix4.identity()..rotateZ(-0.1),
                    alignment: Alignment.topRight,
                    child: Container(
                      height: 25,
                      width: 15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(lightX, lightY),
                          end: Alignment(-lightX, -lightY),
                          colors: const [
                            Color(0xFFE53935), // Kırmızı
                            Color(0xFFB71C1C), // Koyu kırmızı
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                          topRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 3,
                            offset: const Offset(-1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Roket kanatları - sağ
                Positioned(
                  bottom: 15,
                  right: 0,
                  child: Transform(
                    transform: Matrix4.identity()..rotateZ(0.1),
                    alignment: Alignment.topLeft,
                    child: Container(
                      height: 25,
                      width: 15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(lightX, lightY),
                          end: Alignment(-lightX, -lightY),
                          colors: const [
                            Color(0xFFE53935), // Kırmızı
                            Color(0xFFB71C1C), // Koyu kırmızı
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(5),
                          topLeft: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 3,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Roket motor tabanı - ateşsiz
                Positioned(
                  bottom: 0,
                  left: 15,
                  right: 15,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors: const [
                          Color(0xFF9E9E9E), // Gri
                          Color(0xFF616161), // Koyu gri
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Işık yansıması efekti
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        painter: RocketLightReflectionPainter(
                          time: animController.value,
                          lightX: lightX,
                          lightY: lightY,
                          isDragging: isDragging,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
