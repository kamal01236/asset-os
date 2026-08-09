@Tags(['unit'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _importOrExport = RegExp(
  r'''^(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

void main() {
  test('lib layers do not use forbidden imports', () {
    final Directory libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'flutter test cwd should be apps/web',
    );
    expect(
      Directory('lib/core').existsSync(),
      isFalse,
      reason: 'lib/core must not remain (no compatibility shims)',
    );

    final List<String> violations = <String>[];
    for (final File file in libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))) {
      final String fileRel = _posixLibRel(file);
      final String? layer = _layerOf(fileRel);
      if (layer == null || layer == 'main' || layer == 'l10n') {
        continue;
      }
      final String source = file.readAsStringSync();
      for (final RegExpMatch match in _importOrExport.allMatches(source)) {
        violations.addAll(_violationsFor(fileRel, layer, match.group(1)!));
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

String _posixLibRel(File file) {
  final String abs = file.absolute.path.replaceAll(r'\', '/');
  final String libAbs =
      Directory('lib').absolute.path.replaceAll(r'\', '/');
  final String suffix =
      abs.substring(libAbs.length).replaceFirst(RegExp(r'^/'), '');
  return 'lib/$suffix';
}

String? _layerOf(String libRel) {
  final String posix = libRel.replaceAll(r'\', '/');
  if (posix == 'lib/main.dart') {
    return 'main';
  }
  if (!posix.startsWith('lib/')) {
    return null;
  }
  final String rest = posix.substring('lib/'.length);
  final int slash = rest.indexOf('/');
  if (slash < 0) {
    return rest == 'main.dart' ? 'main' : rest;
  }
  return rest.substring(0, slash);
}

String? _resolveAssetOsLib(String fromLibRel, String uri) {
  if (uri.startsWith('package:asset_os/')) {
    return 'lib/${uri.substring('package:asset_os/'.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) {
    return null;
  }
  return Uri.parse(fromLibRel).resolve(uri).path;
}

bool _isDrift(String uri) {
  return uri == 'package:drift/drift.dart' ||
      uri.startsWith('package:drift/') ||
      uri.startsWith('package:drift_flutter');
}

bool _isRiverpod(String uri) {
  return uri.startsWith('package:flutter_riverpod') ||
      uri.startsWith('package:riverpod/');
}

List<String> _violationsFor(String fileRel, String layer, String uri) {
  final List<String> out = <String>[];

  if (layer == 'presentation' && _isDrift(uri)) {
    out.add('$fileRel must not import Drift ($uri)');
  }
  if (layer == 'domain' && _isDrift(uri)) {
    out.add('$fileRel (domain) must not import Drift ($uri)');
  }
  if (layer == 'domain' && _isRiverpod(uri)) {
    out.add('$fileRel (domain) must not import Riverpod ($uri)');
  }
  if (layer == 'domain' && uri.startsWith('package:shared_preferences')) {
    out.add('$fileRel (domain) must not import shared_preferences ($uri)');
  }

  final String? imported = _resolveAssetOsLib(fileRel, uri);
  if (imported == null || !imported.startsWith('lib/')) {
    return out;
  }
  final String? importedLayer = _layerOf(imported);
  if (importedLayer == null ||
      importedLayer == 'l10n' ||
      importedLayer == 'main') {
    return out;
  }

  switch (layer) {
    case 'presentation':
      if (imported.startsWith('lib/infrastructure/db/')) {
        out.add('$fileRel must not import infrastructure/db ($uri)');
      }
    case 'application':
      if (importedLayer == 'presentation') {
        out.add('$fileRel (application) must not import presentation ($uri)');
      }
    case 'domain':
      if (importedLayer == 'application' ||
          importedLayer == 'presentation' ||
          importedLayer == 'infrastructure') {
        out.add(
          '$fileRel (domain) must not import $importedLayer ($uri)',
        );
      }
    case 'infrastructure':
      if (importedLayer == 'presentation' || importedLayer == 'application') {
        out.add(
          '$fileRel (infrastructure) must not import $importedLayer ($uri)',
        );
      }
  }
  return out;
}
