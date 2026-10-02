// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_local_variable
import 'dart:html' as html;
import 'dart:convert';

void downloadWebFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
