import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import 'topology_download_stub.dart'
    if (dart.library.html) 'topology_download_web.dart';

class TopologyFileHelper {
  /// Open file picker dialog to load a JSON file and return raw string content
  static Future<String?> pickJsonFile() async {
    try {
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final dynamic files = result.files;
        if (files != null && files.isNotEmpty) {
          final dynamic file = files.first;
          if (file.bytes != null) {
            return utf8.decode(file.bytes);
          } else if (file.path != null) {
            return await File(file.path.toString()).readAsString();
          }
        }
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
