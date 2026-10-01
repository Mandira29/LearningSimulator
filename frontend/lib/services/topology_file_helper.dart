import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import 'topology_download_stub.dart'
    if (dart.library.html) 'topology_download_web.dart';

class TopologyFileHelper {
  /// Open file picker dialog to load a JSON file and return raw string content
  static Future<String?> pickJsonFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.isNotEmpty) {
        final file = result.first;
        final bytes = await file.readAsBytes();
        return utf8.decode(bytes);
      }
    } catch (e) {
      debugPrint('Error picking topology file: $e');
    }
    return null;
  }

  /// Triggers browser download or OS save file dialog
  static Future<bool> saveJsonFile(String jsonString, String filename) async {
    try {
      if (kIsWeb) {
        downloadWebFile(jsonString, filename);
        return true;
      } else {
        final result = await FilePicker.saveFile(
          dialogTitle: 'Save Topology JSON',
          fileName: filename,
          bytes: Uint8List.fromList(utf8.encode(jsonString)),
        );
        return result != null;
      }
    } catch (e) {
      debugPrint('Error saving topology file: $e');
      return false;
    }
  }
}
