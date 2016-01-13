// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Builds an index.html file in each folder containing entry points, if none
/// already exists. This file simply lists all the entry point files.
library index_page.transformer;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

/// Builds an index.html file in each folder containing entry points, if none
/// already exists. This file simply lists all the entry point files.
class IndexPageBuilder extends AggregateTransformer
    implements DeclaringAggregateTransformer, LazyAggregateTransformer {
  final bool shouldRun;

  IndexPageBuilder.asPlugin(BarbackSettings settings)
      : shouldRun = settings.mode == BarbackMode.DEBUG;

  /// Group by top level directory.
  classifyPrimary(AssetId id) {
    if (!shouldRun) return null;
    var parts = path.url.split(id.path);
    if (parts.length < 2) return null;
    return parts[0];
  }

  /// Outputs an index.html file in every folder which doesn't already have an
  /// index.html file.
  declareOutputs(DeclaringAggregateTransform transform) async {
    final ids = await transform.primaryIds.toList();
    final dirFiles = _getDirsAndFiles(ids);
    for (var dir in dirFiles.keys) {
      if (dirFiles[dir].contains('index.html')) continue;
      transform.declareOutput(
          new AssetId(transform.package, path.url.join(dir, 'index.html')));
    }
  }

  /// Actually run the transformer.
  Future apply(AggregateTransform transform) async {
    if (!shouldRun) return;
    final assets = await transform.primaryInputs.toList();
    var dirFiles = _getDirsAndFiles(assets.map((asset) => asset.id));

    // Create an output index.html file for each directory, if one doesn't
    // exist already
    dirFiles.forEach((directory, files) {
      if (dirFiles[directory].contains('index.html')) return;
      _createOutput(directory, files.toList(), transform);
    });
  }

  Map<String, List<String>> _getDirsAndFiles(Iterable<AssetId> ids) {
    final dirFiles = <String, Set<String>>{};
    for (var id in ids) {
      var dir = path.url.dirname(id.path);
      dirFiles.putIfAbsent(dir, () => new Set());
      dirFiles[dir].add(path.url.relative(id.path, from: dir));

      var parentDir = path.url.dirname(dir);
      if (parentDir != '.') {
        dirFiles.putIfAbsent(parentDir, () => new Set());
        dirFiles[parentDir].add(path.url.relative(dir, from: parentDir));
      }
    }

    return dirFiles;
  }

  void _createOutput(
      String directory, List<String> files, AggregateTransform transform) {
    var indexAsset =
        new AssetId(transform.package, path.url.join(directory, 'index.html'));

    // Sort alphabetically by recursive path parts.
    files..sort((String a, String b) => a.compareTo(b));

    // Create the document with a list.
    var doc = new StringBuffer('<!DOCTYPE html><html><body>');
    doc.writeln('<h1>');
    var dirParts = path.url.split(directory);
    var url = '/';
    for (var part in dirParts) {
      // skip first dir in the url
      if (part != dirParts.first) url = path.url.join(url, part);
      doc.write('<a href="$url">$part</a> / ');
    }
    doc.write('</h1>');
    doc.writeln('<ul>');

    // Add all the assets to the list.
    for (var file in files) {
      doc.writeln('<li><a href="$file">$file</a></li>');
    }

    doc.writeln('</ul></body></html>');

    // Output the index.html file
    transform.addOutput(new Asset.fromString(indexAsset, doc.toString()));
  }
}
