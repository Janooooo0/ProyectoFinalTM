import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DraftHelper {
  static final DraftHelper _instance = DraftHelper._internal();
  factory DraftHelper() => _instance;
  DraftHelper._internal();

  Future<Directory> _getDraftsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final draftsDir = Directory('${directory.path}/drafts');
    if (!await draftsDir.exists()) {
      await draftsDir.create(recursive: true);
    }
    return draftsDir;
  }

  Future<void> saveDraft(String title, String content) async {
    final directory = await _getDraftsDirectory();
    final fileName = 'draft_${DateTime.now().millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString('$title|SEPARATOR|$content');
  }

  Future<List<Map<String, dynamic>>> getAllDrafts() async {
    final directory = await _getDraftsDirectory();
    final List<Map<String, dynamic>> drafts = [];
    
    final List<FileSystemEntity> files = directory.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('.txt')) {
        final data = await file.readAsString();
        final parts = data.split('|SEPARATOR|');
        if (parts.length == 2) {
          drafts.add({
            'path': file.path,
            'title': parts[0],
            'content': parts[1],
            'date': 'Borrador',
          });
        }
      }
    }
    return drafts;
  }

  Future<void> deleteDraft(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
