import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/contribution.dart';

const _events = [
  PortfolioEventOrderItem(id: 'subscribe', label: 'Subscribe'),
  PortfolioEventOrderItem(id: 'dispatch', label: 'Dispatch'),
  PortfolioEventOrderItem(id: 'frame', label: 'Frame'),
];
const _flush = PortfolioEventOrderItem(id: 'flush', label: 'Flush');
const _gap = PortfolioEventGap(
  after: 'subscribe',
  before: 'dispatch',
  label: 'Pending delivery',
);
const _sequenceError =
    'Event-order sequences require unique, declared event ids.';
const _coverageError =
    'Every declared event must be used by an event-order sequence.';
const _differentError = 'Baseline and patched event orders must differ.';
const _gapOwnershipError =
    'Only the baseline sequence must declare one risk gap.';
const _gapOrderError = 'The patched order must close the baseline risk gap.';

void main() {
  group('PortfolioEventOrderLab invariants', () {
    _registerDeclarationTests();
    _registerSequenceTests();
    _registerCoverageTests();
    _registerGapOwnershipTests();
    _registerBaselineGapTests();
    _registerPatchedGapTests();
    _registerEarlyFailureOrderTests();
    _registerLateFailureOrderTests();
    _registerOwnershipTests();
    _registerSerializationTests();
    _registerTranslationTests();
  });
}

void _registerDeclarationTests() {
  test('requires three declarations before inspecting their structure', () {
    _expectValid(_lab());
    for (final count in [0, 1, 2]) {
      _expectInvalid(
        _lab(events: _events.take(count).toList()),
        'An event-order lab requires at least three events.',
      );
    }
  });
  test('reports the first repeated declaration with its exact context', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(events: [..._events, _events[1], _events[0]]),
      'Duplicate event-order lab event id: dispatch',
    );
  });
}

void _registerSequenceTests() {
  for (final patched in [false, true]) {
    final side = patched ? 'patched' : 'baseline';
    test('$side sequence requires at least two events', () {
      _expectValid(_lab());
      for (final order in <List<String>>[
        [],
        ['subscribe'],
      ]) {
        _expectInvalid(_withOrder(order, patched: patched), _sequenceError);
      }
    });
    test('$side sequence rejects repeated events', () {
      _expectValid(_lab());
      _expectInvalid(
        _withOrder([
          'subscribe',
          'dispatch',
          'dispatch',
          'frame',
        ], patched: patched),
        _sequenceError,
      );
    });
    test('$side sequence rejects undeclared events', () {
      _expectValid(_lab());
      _expectInvalid(
        _withOrder([
          'subscribe',
          'dispatch',
          'frame',
          'undeclared_event',
        ], patched: patched),
        _sequenceError,
      );
    });
  }
}

void _registerCoverageTests() {
  test('coverage is the union, not every event in each sequence', () {
    final lab = _lab(
      events: [..._events, _flush],
      withPatch: _sequence(['dispatch', 'subscribe', 'flush']),
    );
    _expectValid(lab);
    expect(lab.baseline.order, isNot(contains('flush')));
    expect(lab.withPatch.order, isNot(contains('frame')));
    _expectInvalid(_lab(events: [..._events, _flush]), _coverageError);
  });
  test('separately owned lists with equal order are rejected by value', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(withPatch: _sequence(['subscribe', 'dispatch', 'frame'])),
      _differentError,
    );
  });
}

void _registerGapOwnershipTests() {
  test('baseline must own a gap', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(baseline: _sequence(['subscribe', 'dispatch', 'frame'])),
      _gapOwnershipError,
    );
  });
  test('patched sequence must not own a gap', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(withPatch: _sequence(['dispatch', 'subscribe', 'frame'], gap: _gap)),
      _gapOwnershipError,
    );
  });
}

void _registerBaselineGapTests() {
  test('baseline contains both gap endpoints', () {
    _expectValid(_lab());
    for (final order in [
      ['dispatch', 'frame'],
      ['subscribe', 'frame'],
    ]) {
      _expectInvalid(
        _lab(baseline: _sequence(order, gap: _gap)),
        _gapOrderError,
      );
    }
  });
  test('baseline endpoints are adjacent in the declared direction', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(baseline: _sequence(['subscribe', 'frame', 'dispatch'], gap: _gap)),
      _gapOrderError,
    );
    final patched = _sequence(['dispatch', 'frame', 'subscribe']);
    _expectValid(_lab(withPatch: patched));
    _expectInvalid(
      _lab(
        baseline: _sequence(['dispatch', 'subscribe', 'frame'], gap: _gap),
        withPatch: patched,
      ),
      _gapOrderError,
    );
  });
}

void _registerPatchedGapTests() {
  test('patched order contains both gap endpoints', () {
    _expectValid(_lab());
    for (final order in [
      ['subscribe', 'frame'],
      ['dispatch', 'frame'],
    ]) {
      _expectInvalid(_lab(withPatch: _sequence(order)), _gapOrderError);
    }
  });
  test('patched endpoints reverse direction but need not be adjacent', () {
    _expectValid(
      _lab(withPatch: _sequence(['dispatch', 'frame', 'subscribe'])),
    );
    _expectInvalid(
      _lab(withPatch: _sequence(['subscribe', 'frame', 'dispatch'])),
      _gapOrderError,
    );
  });
  test('gap may use the final baseline pair and outer patched positions', () {
    _expectValid(
      _lab(
        baseline: _sequence(['frame', 'subscribe', 'dispatch'], gap: _gap),
        withPatch: _sequence(['dispatch', 'frame', 'subscribe']),
      ),
    );
  });
}

void _registerEarlyFailureOrderTests() {
  test('declaration count precedes duplicates and sequence failures', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(events: [_events[0], _events[0]], baseline: _sequence([])),
      'An event-order lab requires at least three events.',
    );
  });
  test('declaration uniqueness precedes sequence failures', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(events: [..._events, _events[1]], baseline: _sequence([])),
      'Duplicate event-order lab event id: dispatch',
    );
  });
  test('sequence membership precedes missing union coverage', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(
        events: [..._events, _flush],
        baseline: _sequence(['subscribe', 'undeclared_event'], gap: _gap),
      ),
      _sequenceError,
    );
  });
}

void _registerLateFailureOrderTests() {
  test('union coverage precedes equal order and gap ownership', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(
        events: [..._events, _flush],
        baseline: _sequence(['subscribe', 'dispatch', 'frame']),
        withPatch: _sequence(['subscribe', 'dispatch', 'frame']),
      ),
      _coverageError,
    );
  });
  test('different order precedes missing baseline gap', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(
        baseline: _sequence(['subscribe', 'dispatch', 'frame']),
        withPatch: _sequence(['subscribe', 'dispatch', 'frame']),
      ),
      _differentError,
    );
  });
  test('gap ownership precedes gap relationship failures', () {
    _expectValid(_lab());
    _expectInvalid(
      _lab(
        baseline: _sequence(['subscribe', 'frame', 'dispatch'], gap: _gap),
        withPatch: _sequence(['subscribe', 'dispatch', 'frame'], gap: _gap),
      ),
      _gapOwnershipError,
    );
  });
}

void _registerOwnershipTests() {
  test('snapshots input lists and exposes immutable event orders', () {
    final events = [..._events];
    final baselineOrder = ['subscribe', 'dispatch', 'frame'];
    final patchedOrder = ['dispatch', 'subscribe', 'frame'];
    final lab = _lab(
      events: events,
      baseline: _sequence(baselineOrder, gap: _gap),
      withPatch: _sequence(patchedOrder),
    );
    events.clear();
    baselineOrder.clear();
    patchedOrder.clear();
    _expectValid(lab);
    expect(lab.events, _events);
    expect(lab.baseline.order, ['subscribe', 'dispatch', 'frame']);
    expect(lab.withPatch.order, ['dispatch', 'subscribe', 'frame']);
    expect(() => lab.events.add(_flush), throwsUnsupportedError);
    expect(() => lab.baseline.order.add('flush'), throwsUnsupportedError);
    expect(() => lab.withPatch.order.add('flush'), throwsUnsupportedError);
  });
  test('validation preserves event objects and all sequence order', () {
    final events = [_events[2], _events[1], _events[0]];
    final lab = _lab(
      events: events,
      baseline: _sequence(['frame', 'subscribe', 'dispatch'], gap: _gap),
      withPatch: _sequence(['dispatch', 'frame', 'subscribe']),
    );
    final ownedEvents = lab.events;
    final baseline = lab.baseline.order;
    final patched = lab.withPatch.order;
    _expectValid(lab);
    expect(lab.events, same(ownedEvents));
    expect(lab.events, events);
    expect(lab.eventById('dispatch'), same(_events[1]));
    expect(lab.baseline.order, same(baseline));
    expect(lab.baseline.order, ['frame', 'subscribe', 'dispatch']);
    expect(lab.withPatch.order, same(patched));
    expect(lab.withPatch.order, ['dispatch', 'frame', 'subscribe']);
  });
}

void _registerSerializationTests() {
  test('validation preserves the exact authored JSON structure', () {
    final lab = _lab();
    _expectValid(lab);
    expect(lab.toJson(), {
      'title': 'Event ordering',
      'events': [
        {'id': 'subscribe', 'label': 'Subscribe'},
        {'id': 'dispatch', 'label': 'Dispatch'},
        {'id': 'frame', 'label': 'Frame'},
      ],
      'baseline': {
        'summary': 'Event sequence',
        'order': ['subscribe', 'dispatch', 'frame'],
        'gap': {
          'after': 'subscribe',
          'before': 'dispatch',
          'label': 'Pending delivery',
        },
      },
      'with_patch': {
        'summary': 'Event sequence',
        'order': ['dispatch', 'subscribe', 'frame'],
        'gap': null,
      },
    });
  });
  test('separate equivalent labs retain identity equality', () {
    final lab = _lab();
    final equivalent = _lab();
    _expectValid(lab);
    _expectValid(equivalent);
    expect(lab == equivalent, isFalse);
    expect(lab.toJson(), equivalent.toJson());
  });
}

void _registerTranslationTests() {
  test('label copies preserve ordering and gap facts without revalidation', () {
    final source = _lab();
    final lab = source.copyWith((
      title: 'Delivery ordering',
      events: [
        for (final event in source.events)
          event.copyWith((label: '${event.label} event')),
      ],
      baseline: source.baseline.copyWith((
        summary: 'Baseline ordering',
        gap: source.baseline.gap!.copyWith((label: 'Delivery pending')),
      )),
      withPatch: source.withPatch.copyWith((
        summary: 'Patched ordering',
        gap: null,
      )),
    ));
    _expectValid(lab);
    expect(lab.title, 'Delivery ordering');
    expect(lab.events.map((event) => event.id), [
      'subscribe',
      'dispatch',
      'frame',
    ]);
    expect(lab.events.map((event) => event.label), [
      'Subscribe event',
      'Dispatch event',
      'Frame event',
    ]);
    expect(lab.baseline.order, source.baseline.order);
    expect(lab.withPatch.order, source.withPatch.order);
    expect(lab.baseline.gap!.after, 'subscribe');
    expect(lab.baseline.gap!.before, 'dispatch');
    expect(lab.baseline.gap!.label, 'Delivery pending');
    expect(lab.withPatch.gap, isNull);
    expect(source.baseline.gap, same(_gap));
  });
}

PortfolioEventOrderLab _lab({
  List<PortfolioEventOrderItem> events = _events,
  PortfolioEventSequence? baseline,
  PortfolioEventSequence? withPatch,
}) => PortfolioEventOrderLab(
  title: 'Event ordering',
  events: events,
  baseline:
      baseline ?? _sequence(['subscribe', 'dispatch', 'frame'], gap: _gap),
  withPatch: withPatch ?? _sequence(['dispatch', 'subscribe', 'frame']),
);

PortfolioEventSequence _sequence(
  List<String> order, {
  PortfolioEventGap? gap,
}) => PortfolioEventSequence(summary: 'Event sequence', order: order, gap: gap);

PortfolioEventOrderLab _withOrder(
  List<String> order, {
  required bool patched,
}) => patched
    ? _lab(withPatch: _sequence(order))
    : _lab(baseline: _sequence(order, gap: _gap));

void _expectValid(PortfolioEventOrderLab lab) =>
    expect(lab.validate, returnsNormally);

void _expectInvalid(PortfolioEventOrderLab lab, String message) => expect(
  lab.validate,
  throwsA(
    isA<FormatException>()
        .having((error) => error.message, 'message', message)
        .having((error) => error.source, 'source', isNull)
        .having((error) => error.offset, 'offset', isNull),
  ),
);
