import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> saveExport(String fileName, String content) async {
  final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return 'Fichier « $fileName » téléchargé';
}
