// test/architecture_test.dart
//
// One job: fail the build when an import breaks the layer and feature rules in
// AGENTS.md ("Import rules").
// Reason: a rule that nothing checks drifts. Import lines are the one part of
// the architecture a test can read without running the app.
//
// Limit: this file checks imports only. It cannot see business logic inside a
// widget. Code review catches that.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Reason: reads the URI of each import or export line. A commented-out import
// does not start with the keyword, so it is ignored.
final _importLine = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

// Packages a domain file may import.
const _domainPackages = {'fpdart', 'equatable', 'intl'};

// core folders a domain file may import.
const _domainCoreAreas = {
  'domain',
  'error',
  'formatting',
  'usecase',
  'constants',
  'platform',
};

// Packages a presentation file may import.
const _presentationPackages = {
  'flutter',
  'flutter_bloc',
  'bloc_concurrency',
  'equatable',
  'fpdart',
  'get_it',
};

// Feature to features whose domain layer it may import, from any layer.
const _domainImports = <String, Set<String>>{
  'export': {'items', 'shopping_lists', 'settings'},
  'items': {'shopping_lists'},
  'settings': {'shopping_lists'},
};

// The only other cross-feature imports allowed. Key is "feature/layer" of the
// importing file. Value is the exact files it may import.
const _fileExceptions = <String, Set<String>>{
  'items/presentation': {
    'lib/features/export/presentation/cubit/share_cubit.dart',
    'lib/features/export/presentation/cubit/share_state.dart',
    'lib/features/export/presentation/widgets/share_sheet.dart',
  },
  'shopping_lists/presentation': {
    'lib/features/settings/presentation/cubit/settings_cubit.dart',
    'lib/features/settings/presentation/cubit/settings_state.dart',
  },
};

void main() {
  final files = _sourceFiles();

  test('lib/ has Dart files to check', () {
    // Reason: a wrong working directory would scan nothing and pass silently.
    expect(files, isNotEmpty);
  });

  test('every import follows the rules in AGENTS.md', () {
    final packageName = _packageName();
    final violations = <String>[];

    for (final path in files) {
      final from = _Location.parse(path);
      final source = File(path).readAsStringSync();
      for (final match in _importLine.allMatches(source)) {
        final uri = match.group(1)!;
        final problem = _check(from, uri, packageName);
        if (problem != null) violations.add('$path imports $uri. $problem');
      }
    }

    expect(violations, isEmpty, reason: '\n${violations.join('\n')}');
  });
}

// ---------------------------------------------------------------------------
// Checks
// ---------------------------------------------------------------------------

String? _check(_Location from, String uri, String packageName) {
  final package = _externalPackage(uri, packageName);
  final target = _projectPath(from.path, uri, packageName);

  if (package != null) {
    final misplaced = _checkPackagePlacement(from, package);
    if (misplaced != null) return misplaced;
  }

  switch (from.layer) {
    case 'domain':
      return _checkDomain(from, uri, package, target);
    case 'data':
      return _checkData(from, uri, package, target);
    case 'presentation':
      return _checkPresentation(from, package, target);
    default:
    // core and lib/ root files: only package placement is checked.
      return null;
  }
}

// Reason: Drift code stays in one layer so a storage change touches one place.
// The same holds for pdf, share_plus, and path_provider.
String? _checkPackagePlacement(_Location from, String package) {
  final inData = from.layer == 'data';
  final inCoreDatabase = from.coreArea == 'database';
  if ((package == 'drift' || package == 'drift_flutter') &&
      !(inData || inCoreDatabase)) {
    return 'Only data and core/database may import $package. '
        'Reason: storage code stays in one layer.';
  }
  if (const {'pdf', 'share_plus', 'path_provider'}.contains(package) &&
      !inData) {
    return 'Only data may import $package. '
        'Reason: platform code stays out of domain and presentation.';
  }
  return null;
}

// Reason: domain holds the business rules. It must run in a plain Dart test,
// with no Flutter and no storage.
String? _checkDomain(
    _Location from,
    String uri,
    String? package,
    String? target,
    ) {
  if (uri == 'dart:ui') {
    return 'domain is pure Dart. dart:ui belongs to Flutter.';
  }
  if (uri.startsWith('dart:')) return null;
  if (package != null) {
    return _domainPackages.contains(package)
        ? null
        : 'domain may import only fpdart, equatable, and intl. '
        'Reason: domain stays free of Flutter and platform code.';
  }
  if (target == null) return null;
  return _checkProjectTarget(
    from,
    target,
    sameFeatureLayers: const {'domain'},
    allowedCore: _domainCoreAreas,
  );
}

// Reason: data implements domain interfaces. It never reaches up into screens.
String? _checkData(
    _Location from,
    String uri,
    String? package,
    String? target,
    ) {
  if (package == 'flutter' && uri != 'package:flutter/services.dart') {
    return 'data may import only package:flutter/services.dart from Flutter. '
        'Reason: no widgets in data. The purpose (loading font assets) '
        'cannot be machine-checked.';
  }
  if (target == null) return null;
  return _checkProjectTarget(
    from,
    target,
    sameFeatureLayers: const {'domain', 'data'},
  );
}

// Reason: screens call use cases. They never read storage or platform code.
String? _checkPresentation(_Location from, String? package, String? target) {
  if (package != null && !_presentationPackages.contains(package)) {
    return 'presentation may import only flutter, flutter_bloc, '
        'bloc_concurrency, equatable, fpdart, and get_it. '
        'Reason: screens depend on use cases, not on storage or platform code.';
  }
  if (target == null) return null;
  if (from.isPage && target.contains('/presentation/pages/')) {
    return 'Pages reach other pages only through core/router. '
        'Reason: one place owns navigation.';
  }
  return _checkProjectTarget(
    from,
    target,
    sameFeatureLayers: const {'domain', 'presentation'},
    bannedCore: const {'database'},
  );
}

String? _checkProjectTarget(
    _Location from,
    String target, {
      required Set<String> sameFeatureLayers,
      Set<String>? allowedCore,
      Set<String> bannedCore = const {},
    }) {
  final to = _Location.parse(target);

  if (to.coreArea != null) {
    if (allowedCore != null && !allowedCore.contains(to.coreArea)) {
      return 'This layer may not import core/${to.coreArea}. '
          'Reason: keeps the layer free of unrelated code.';
    }
    if (bannedCore.contains(to.coreArea)) {
      return 'This layer may not import core/${to.coreArea}. '
          'Reason: it holds storage code. Screens call use cases.';
    }
    return null;
  }

  if (to.feature == null) {
    return 'No layer may import files in the lib/ root. '
        'Reason: the root wires the app. It is not a dependency.';
  }

  if (to.feature == from.feature) {
    if (!sameFeatureLayers.contains(to.layer)) {
      return '${from.layer} may not import ${to.layer} in the same feature. '
          'Reason: dependencies point inward, toward domain.';
    }
    return null;
  }

  return _checkCrossFeature(from, to);
}

String? _checkCrossFeature(_Location from, _Location to) {
  if (to.layer == 'domain' &&
      (_domainImports[from.feature]?.contains(to.feature) ?? false)) {
    return null;
  }
  final exact = _fileExceptions['${from.feature}/${from.layer}'];
  if (exact != null && exact.contains(to.path)) return null;
  return '${from.feature} may not import ${to.feature}/${to.layer}. '
      'Reason: only the cross-feature imports listed in AGENTS.md are allowed.';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _sourceFiles() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((path) => path.endsWith('.dart') && !path.endsWith('.g.dart'))
      .toList();
}

// Reason: the package name is read from pubspec.yaml so the test never
// guesses it.
String _packageName() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  if (match == null) fail('pubspec.yaml has no name field.');
  return match.group(1)!;
}

// Name of a package other than this project, or null.
String? _externalPackage(String uri, String packageName) {
  if (!uri.startsWith('package:') || uri.startsWith('package:$packageName/')) {
    return null;
  }
  return uri.substring('package:'.length, uri.indexOf('/'));
}

// Path under lib/ for an import of this project, or null for dart: and
// other-package imports. Relative imports are resolved so they cannot hide a
// violation.
String? _projectPath(String fromPath, String uri, String packageName) {
  final prefix = 'package:$packageName/';
  if (uri.startsWith(prefix)) return 'lib/${uri.substring(prefix.length)}';
  if (uri.contains(':')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(fromPath), uri));
}

class _Location {
  _Location(this.path, this.feature, this.layer, this.coreArea);

  factory _Location.parse(String path) {
    final parts = p.posix.split(path);
    String? feature;
    String? layer;
    String? coreArea;
    if (parts.length > 3 && parts[1] == 'features') {
      feature = parts[2];
      layer = parts[3];
    } else if (parts.length > 2 && parts[1] == 'core') {
      coreArea = parts[2];
    }
    return _Location(path, feature, layer, coreArea);
  }

  final String path;
  final String? feature; // set for lib/features/<feature>/...
  final String? layer; // domain, data, or presentation, inside a feature
  final String? coreArea; // set for lib/core/<area>/...

  bool get isPage =>
      layer == 'presentation' && path.contains('/presentation/pages/');
}