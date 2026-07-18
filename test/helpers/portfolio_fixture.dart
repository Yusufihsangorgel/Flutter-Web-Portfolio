import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

const _fixtureSpecs = <String, ({int width, int height})>{
  'assets/work/.portfolio-test-runtime.png': (width: 680, height: 425),
  'assets/work/.portfolio-test-runtime-compact.png': (width: 900, height: 1200),
  'assets/work/.portfolio-test-release.png': (width: 1600, height: 840),
  'assets/work/.portfolio-test-release-compact.png': (width: 900, height: 1200),
  'assets/work/.portfolio-test-queue.png': (width: 1600, height: 840),
  'assets/work/.portfolio-test-queue-compact.png': (width: 900, height: 1200),
};
final _encodedPngs = <(int, int), Uint8List>{};
final _fixtureBytes = <String, Uint8List>{};

PortfolioDocument loadPortfolioFixture({
  void Function(Map<String, dynamic> json)? mutate,
}) {
  final json = loadPortfolioFixtureJson();
  mutate?.call(json);
  return PortfolioDocument.fromJson(json);
}

Map<String, dynamic> loadPortfolioFixtureJson() {
  final json =
      jsonDecode(File('test/fixtures/portfolio.json').readAsStringSync())
          as Map<String, dynamic>;
  final systems = (json['systems']! as List<dynamic>)
      .cast<Map<String, dynamic>>();
  for (final system in systems) {
    final artifact = system['artifact']! as Map<String, dynamic>;
    _isolateArtifact(artifact);
    if (artifact['compact'] case final Map<String, dynamic> compact) {
      _isolateArtifact(compact);
    }
  }
  final fixturePaths = _fixturePaths(json);
  for (final path in fixturePaths) {
    final bytes = _fixtureBytes[path]!;
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes, flush: true);
  }
  addTearDown(() {
    for (final path in fixturePaths) {
      _fixtureBytes.remove(path);
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
  });
  return json;
}

void _isolateArtifact(Map<String, dynamic> artifact) {
  final configuredPath = artifact['asset']! as String;
  final extension = configuredPath.lastIndexOf('.');
  if (extension <= configuredPath.lastIndexOf('/')) {
    throw ArgumentError.value(
      configuredPath,
      'configuredPath',
      'Fixture assets must include a file extension.',
    );
  }
  final isolatedPath =
      '${configuredPath.substring(0, extension)}-$pid${configuredPath.substring(extension)}';
  final spec = _fixtureSpecs[configuredPath];
  if (spec == null) {
    throw StateError('Unknown fixture asset: $configuredPath');
  }
  artifact['asset'] = isolatedPath;
  _fixtureBytes[isolatedPath] = _encodedPngs.putIfAbsent((
    spec.width,
    spec.height,
  ), () => _encodePng(spec.width, spec.height));
}

Widget withPortfolioFixtureAssets({required Widget child}) =>
    DefaultAssetBundle(bundle: _PortfolioFixtureBundle(), child: child);

Set<String> _fixturePaths(Map<String, dynamic> json) => {
  for (final system in (json['systems']! as List<dynamic>))
    ..._artifactPaths(system as Map<String, dynamic>),
};

Iterable<String> _artifactPaths(Map<String, dynamic> system) sync* {
  final artifact = system['artifact']! as Map<String, dynamic>;
  yield artifact['asset']! as String;
  if (artifact['compact'] case final Map<String, dynamic> compact) {
    yield compact['asset']! as String;
  }
}

final class _PortfolioFixtureBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    final bytes = _fixtureBytes[key];
    if (bytes != null) {
      return Future.value(ByteData.sublistView(bytes));
    }
    return rootBundle.load(key);
  }
}

Uint8List _encodePng(int width, int height) {
  final rowLength = 1 + width * 3;
  final pixels = Uint8List(rowLength * height);
  for (var y = 0; y < height; y++) {
    final row = y * rowLength;
    pixels[row] = 0;
    for (var x = 0; x < width; x++) {
      final pixel = row + 1 + x * 3;
      pixels[pixel] = 0x24;
      pixels[pixel + 1] = 0x57;
      pixels[pixel + 2] = 0xD6;
    }
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final output = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_pngChunk('IHDR', header.buffer.asUint8List()))
    ..add(_pngChunk('IDAT', ZLibCodec(level: 9).encode(pixels)))
    ..add(_pngChunk('IEND', const []));
  return output.takeBytes();
}

Uint8List _pngChunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final crcInput = Uint8List(typeBytes.length + data.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + data.length, data);
  final chunk = ByteData(12 + data.length)
    ..setUint32(0, data.length)
    ..buffer.asUint8List().setRange(4, 8, typeBytes)
    ..buffer.asUint8List().setRange(8, 8 + data.length, data)
    ..setUint32(8 + data.length, _crc32(crcInput));
  return chunk.buffer.asUint8List();
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
