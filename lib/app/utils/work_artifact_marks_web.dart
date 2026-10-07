import 'package:web/web.dart' as web;

/// Records that the work artifact [asset] has painted its decoded image, as a
/// user-timing mark that browser tests can poll.
void markWorkArtifactPainted(String asset) {
  web.window.performance.mark('work-artifact-painted:$asset');
}
