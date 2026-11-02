import 'package:flutter/services.dart';

Future<String> saveExport(String fileName, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  return 'Tes données ont été copiées dans le presse-papiers';
}
