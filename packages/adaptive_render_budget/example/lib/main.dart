import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter/material.dart';

/// Starts the budget example.
void main() => runApp(const BudgetExample());

/// Displays the current adaptive rendering tier.
class BudgetExample extends StatefulWidget {
  /// Creates the example widget.
  const BudgetExample({super.key});

  @override
  State<BudgetExample> createState() => _BudgetExampleState();
}

class _BudgetExampleState extends State<BudgetExample> {
  late final SchedulerFrameTimingSource _timings;
  late final DisplayRefreshRateSource _refreshRate;
  late final AdaptiveRenderBudgetController _budget;

  @override
  void initState() {
    super.initState();
    _timings = SchedulerFrameTimingSource();
    _refreshRate = DisplayRefreshRateSource(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
    );
    _budget = AdaptiveRenderBudgetController(
      timingSource: _timings,
      refreshRateSource: _refreshRate,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: ValueListenableBuilder<AdaptiveRenderBudgetState>(
          valueListenable: _budget,
          builder: (context, state, child) =>
              Text('Rendering tier: ${state.level.name}'),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _budget.dispose();
    _timings.dispose();
    _refreshRate.dispose();
    super.dispose();
  }
}
