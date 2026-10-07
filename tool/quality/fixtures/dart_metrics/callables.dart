// Intentionally preserves block bodies and closure syntax for AST fixtures.
// ignore_for_file: prefer_expression_function_bodies, prefer_function_declarations_over_variables, unnecessary_lambdas

void lineBoundary() {
  // 02
  // 03
  // 04
  // 05
  // 06
  // 07
  // 08
  // 09
  // 10
  // 11
  // 12
  // 13
  // 14
  // 15
  // 16
  // 17
  // 18
  // 19
  // 20
  // 21
  // 22
  // 23
  // 24
  // 25
  // 26
  // 27
  // 28
  // 29
  // 30
  // 31
  // 32
  // 33
  // 34
  // 35
  // 36
  // 37
  // 38
  // 39
  // 40
  // 41
  // 42
  // 43
  // 44
  // 45
  // 46
  // 47
  // 48
  // 49
  // 50
  // 51
  // 52
  // 53
  // 54
  // 55
  // 56
  // 57
  // 58
  // 59
}

void lineViolation() {
  // 02
  // 03
  // 04
  // 05
  // 06
  // 07
  // 08
  // 09
  // 10
  // 11
  // 12
  // 13
  // 14
  // 15
  // 16
  // 17
  // 18
  // 19
  // 20
  // 21
  // 22
  // 23
  // 24
  // 25
  // 26
  // 27
  // 28
  // 29
  // 30
  // 31
  // 32
  // 33
  // 34
  // 35
  // 36
  // 37
  // 38
  // 39
  // 40
  // 41
  // 42
  // 43
  // 44
  // 45
  // 46
  // 47
  // 48
  // 49
  // 50
  // 51
  // 52
  // 53
  // 54
  // 55
  // 56
  // 57
  // 58
  // 59
  // 60
}

class BuildBoundaries {
  Object build() {
    // 02
    // 03
    // 04
    // 05
    // 06
    // 07
    // 08
    // 09
    // 10
    // 11
    // 12
    // 13
    // 14
    // 15
    // 16
    // 17
    // 18
    // 19
    // 20
    // 21
    // 22
    // 23
    // 24
    // 25
    // 26
    // 27
    // 28
    // 29
    // 30
    // 31
    // 32
    // 33
    // 34
    // 35
    // 36
    // 37
    // 38
    // 39
    // 40
    // 41
    // 42
    // 43
    // 44
    // 45
    // 46
    // 47
    // 48
    // 49
    // 50
    // 51
    // 52
    // 53
    // 54
    // 55
    // 56
    // 57
    // 58
    // 59
    // 60
    // 61
    // 62
    // 63
    // 64
    // 65
    // 66
    // 67
    // 68
    // 69
    // 70
    // 71
    // 72
    // 73
    // 74
    // 75
    // 76
    // 77
    // 78
    // 79
    // 80
    // 81
    // 82
    // 83
    // 84
    // 85
    // 86
    // 87
    // 88
    // 89
    // 90
    // 91
    // 92
    // 93
    // 94
    // 95
    // 96
    // 97
    // 98
    return this;
  }
}

class BuildViolation {
  Object build() {
    // 002
    // 003
    // 004
    // 005
    // 006
    // 007
    // 008
    // 009
    // 010
    // 011
    // 012
    // 013
    // 014
    // 015
    // 016
    // 017
    // 018
    // 019
    // 020
    // 021
    // 022
    // 023
    // 024
    // 025
    // 026
    // 027
    // 028
    // 029
    // 030
    // 031
    // 032
    // 033
    // 034
    // 035
    // 036
    // 037
    // 038
    // 039
    // 040
    // 041
    // 042
    // 043
    // 044
    // 045
    // 046
    // 047
    // 048
    // 049
    // 050
    // 051
    // 052
    // 053
    // 054
    // 055
    // 056
    // 057
    // 058
    // 059
    // 060
    // 061
    // 062
    // 063
    // 064
    // 065
    // 066
    // 067
    // 068
    // 069
    // 070
    // 071
    // 072
    // 073
    // 074
    // 075
    // 076
    // 077
    // 078
    // 079
    // 080
    // 081
    // 082
    // 083
    // 084
    // 085
    // 086
    // 087
    // 088
    // 089
    // 090
    // 091
    // 092
    // 093
    // 094
    // 095
    // 096
    // 097
    // 098
    // 099
    return this;
  }
}

void parameterBoundary(Object a, Object b, Object c, Object d) {}

void parameterViolation(Object a, Object b, Object c, Object d, Object e) {}

void nestingBoundary(bool value) {
  if (value) {
    while (value) {
      for (;;) {
        if (value) break;
      }
    }
  }
}

void nestingViolation(bool value) {
  if (value) {
    while (value) {
      for (;;) {
        if (value) {
          do {} while (value);
        }
      }
    }
  }
}

void complexityBoundary(bool value) {
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
}

void complexityViolation(bool value) {
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
  if (value) {}
}

class IdentityFixture {
  IdentityFixture();

  IdentityFixture.named();

  Object get value => this;

  set value(Object next) {}

  void closures() {
    final first = () {
      if (true) {}
    };
    final second = () => first();
    second();
  }
}

class ConstructorInitializerFixture {
  ConstructorInitializerFixture(bool value)
    : selected = value ? 1 : 0,
      callback = (() {
        if (value) return 1;
        return 0;
      });

  final int selected;
  final int Function() callback;
}
