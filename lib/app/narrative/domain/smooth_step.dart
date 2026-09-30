/// Smoothstep easing for a progress value in [0, 1].
double smoothStep(double value) => value * value * (3 - 2 * value);
