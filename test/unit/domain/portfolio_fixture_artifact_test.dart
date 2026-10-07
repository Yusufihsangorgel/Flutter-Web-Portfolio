import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/portfolio_fixture.dart';

void main() {
  test('stores generated artifacts under the temporary directory', () async {
    final temporaryRoot =
        '${Directory.systemTemp.path}${Platform.pathSeparator}';
    final temporaryDirectories = <Directory>{};
    addTearDown(() {
      expect(temporaryDirectories, isNotEmpty);
      expect(
        temporaryDirectories.every((directory) => !directory.existsSync()),
        isTrue,
      );
    });
    final document = loadPortfolioFixture();

    for (final system in document.systems) {
      final artifact = system.artifact;
      final file = portfolioFixtureFile(artifact.asset);
      temporaryDirectories.add(file.parent);
      expect(file.path, startsWith(temporaryRoot));
      expect(file.existsSync(), isTrue, reason: system.id);

      final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, artifact.width, reason: system.id);
      expect(frame.image.height, artifact.height, reason: system.id);
      frame.image.dispose();
      codec.dispose();

      final compact = artifact.compact;
      if (compact == null) continue;
      final compactFile = portfolioFixtureFile(compact.asset);
      temporaryDirectories.add(compactFile.parent);
      expect(compactFile.path, startsWith(temporaryRoot));
      expect(compactFile.existsSync(), isTrue, reason: system.id);

      final compactCodec = await ui.instantiateImageCodec(
        compactFile.readAsBytesSync(),
      );
      final compactFrame = await compactCodec.getNextFrame();
      expect(compactFrame.image.width, compact.width, reason: system.id);
      expect(compactFrame.image.height, compact.height, reason: system.id);
      expect(
        compactFrame.image.width < compactFrame.image.height,
        isTrue,
        reason: '${system.id} compact artifact must be portrait',
      );
      compactFrame.image.dispose();
      compactCodec.dispose();
    }
  });
}
