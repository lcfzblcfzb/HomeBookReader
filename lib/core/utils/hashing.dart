import 'dart:io';

import 'package:crypto/crypto.dart';

/// 计算文件内容的 SHA-256（小写十六进制），用于去重与文件校验。
Future<String> sha256OfFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}
