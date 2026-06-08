import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImportedStopwatchFont {
  final String path;
  final String family;
  final String label;

  const ImportedStopwatchFont({
    required this.path,
    required this.family,
    required this.label,
  });
}

abstract final class CustomFontService {
  static final Set<String> _loadedFamilies = <String>{};

  static Future<ImportedStopwatchFont> importFont(String sourcePath) async {
    final trimmedPath = sourcePath.trim();
    if (trimmedPath.isEmpty) {
      throw const FormatException('请输入字体文件路径');
    }

    final sourceFile = File(trimmedPath);
    if (!await sourceFile.exists()) {
      throw const FileSystemException('字体文件不存在');
    }

    final extension = p.extension(trimmedPath).toLowerCase();
    if (!const {'.ttf', '.otf', '.ttc'}.contains(extension)) {
      throw const FormatException('仅支持 .ttf、.otf、.ttc 字体文件');
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final fontsDirectory = await _fontsDirectory();
    final fileName = _safeFileName(p.basename(trimmedPath));
    final targetPath = p.join(fontsDirectory.path, '${timestamp}_$fileName');
    await sourceFile.copy(targetPath);

    final family = 'StopwatchLogCustomFont_$timestamp';
    await loadFont(path: targetPath, family: family);

    return ImportedStopwatchFont(
      path: targetPath,
      family: family,
      label: p.basenameWithoutExtension(fileName),
    );
  }

  static Future<void> loadFont({
    required String path,
    required String family,
  }) async {
    if (_loadedFamilies.contains(family)) return;

    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('字体文件不存在', path);
    }

    final bytes = await file.readAsBytes();
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loadedFamilies.add(family);
  }

  static Future<Directory> _fontsDirectory() async {
    final documentsFolder = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documentsFolder.path, 'Stopwatch Log', 'fonts'),
    );
    await directory.create(recursive: true);
    return directory;
  }

  static String _safeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
