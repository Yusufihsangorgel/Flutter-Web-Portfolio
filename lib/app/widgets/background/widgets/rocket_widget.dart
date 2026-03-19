import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../painters/rocket_light_reflection_painter.dart';

class RocketWidget extends StatelessWidget {

  const RocketWidget({
    super.key,
    required this.animController,
    this.isDragging = false,
  });
  final AnimationController animController;
  final bool isDragging;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final perspectiveAngle = math.sin(animController.value * math.pi) * 0.1;
        final lightAngle = animController.value * math.pi * 2;
        final lightX = math.cos(lightAngle) * 0.5;
        final lightY = math.sin(lightAngle) * 0.5;

        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(perspectiveAngle)
                ..rotateY(perspectiveAngle * 0.7),
          alignment: Alignment.center,
          child: SizedBox(
            height: 100,
            width: 50,
            child: Stack(
              children: [
                // Rocket body - metallic look
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
                                ? const [
                                  Color(0xFFF5F5F5),
                                  Color(0xFFE0E0E0),
                                  Color(0xFFBDBDBD),
                                ]
                                : const [
                                  Color(0xFFE0E0E0),
                                  Color(0xFF9E9E9E),
                                  Color(0xFFBDBDBD),
                                ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDragging
                                  ? Colors.blue.withValues(alpha:0.5)
                                  : Colors.black.withValues(alpha:0.5),
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

                // Rocket nose cone
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
                          Color(0xFFE0E0E0),
                          Color(0xFFBDBDBD),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.3),
                          blurRadius: 3,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    // Specular highlight on the nose
                    child: Align(
                      alignment: Alignment(lightX * 2, lightY * 2),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:0.7),
                        ),
                      ),
                    ),
                  ),
                ),

                // Rocket window - glass effect
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
                          color: Colors.lightBlue.shade200.withValues(alpha:0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment(lightX, lightY),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:0.8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Left fin
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
                            Color(0xFFE53935),
                            Color(0xFFB71C1C),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                          topRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.5),
                            blurRadius: 3,
                            offset: const Offset(-1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right fin
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
                            Color(0xFFE53935),
                            Color(0xFFB71C1C),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(5),
                          topLeft: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.5),
                            blurRadius: 3,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Engine nozzle
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
                          Color(0xFF9E9E9E),
                          Color(0xFF616161),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Light reflection overlay
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) => CustomPaint(
                        painter: RocketLightReflectionPainter(
                          time: animController.value,
                          lightX: lightX,
                          lightY: lightY,
                          isDragging: isDragging,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
}
