// Collection-control syntax is intentionally repetitive at exact boundaries.

List<int> collectionControlPassing(bool value) => <int>[
  if (value) 1,
  for (final item in <int>[1]) item,
];

List<int> collectionComplexityBoundary(bool value) => <int>[
  if (value) 1,
  if (value) 2,
  if (value) 3,
  if (value) 4,
  if (value) 5,
  if (value) 6,
  if (value) 7,
  for (final item in <int>[1]) item,
  for (final item in <int>[2]) item,
  for (final item in <int>[3]) item,
  for (final item in <int>[4]) item,
  for (final item in <int>[5]) item,
  for (final item in <int>[6]) item,
  for (final item in <int>[7]) item,
];

List<int> collectionComplexityViolation(bool value) => <int>[
  if (value) 1,
  if (value) 2,
  if (value) 3,
  if (value) 4,
  if (value) 5,
  if (value) 6,
  if (value) 7,
  if (value) 8,
  for (final item in <int>[1]) item,
  for (final item in <int>[2]) item,
  for (final item in <int>[3]) item,
  for (final item in <int>[4]) item,
  for (final item in <int>[5]) item,
  for (final item in <int>[6]) item,
  for (final item in <int>[7]) item,
];

List<int> collectionNestingBoundary(List<int> values) => <int>[
  for (final first in values)
    for (final second in values)
      for (final third in values)
        for (final fourth in values) first + second + third + fourth,
];

List<int> collectionNestingViolation(List<int> values) => <int>[
  for (final first in values)
    for (final second in values)
      for (final third in values)
        for (final fourth in values)
          for (final fifth in values) first + second + third + fourth + fifth,
];

List<int> collectionIfNestingBoundary(bool value) => <int>[
  if (value) ...<int>[
    if (value) ...<int>[
      if (value) ...<int>[if (value) 1],
    ],
  ],
];

List<int> collectionIfNestingViolation(bool value) => <int>[
  if (value) ...<int>[
    if (value) ...<int>[
      if (value) ...<int>[
        if (value) ...<int>[if (value) 1],
      ],
    ],
  ],
];

List<int> collectionElseIf(bool first, bool second) => <int>[
  if (first) 1 else if (second) 2 else 3,
];

List<int> collectionClosureIsolation(bool value) {
  final callback = () => <int>[
    if (value) 1,
    for (final item in <int>[2]) item,
  ];
  return callback();
}
