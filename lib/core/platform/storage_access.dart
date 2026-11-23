import 'dart:io';

import 'package:flutter/services.dart';

/// 共享存储访问状态。
enum StorageAccessStatus {
  /// 已获得扫描所需的读写权限。
  granted,

  /// Android 未授权。
  denied,

  /// Windows 等平台无需权限。
  notRequired,
}

/// 扫描本机文件（PDF / EPUB）所需的存储权限。
///
/// Android 11+ 使用「所有文件访问权限」（系统设置页开关）；
/// Android 10 及以下使用 READ_EXTERNAL_STORAGE 运行时权限。
abstract final class StorageAccess {
  static const MethodChannel _channel =
      MethodChannel('homepdfreader/storage_access');

  static bool get _isAndroid => Platform.isAndroid;

  static Future<StorageAccessStatus> status() async {
    if (!_isAndroid) return StorageAccessStatus.notRequired;
    final value = await _channel.invokeMethod<String>('status');
    return value == 'granted'
        ? StorageAccessStatus.granted
        : StorageAccessStatus.denied;
  }

  /// 发起授权。Android 11+ 会打开系统设置页，返回后需重新查询 [status]。
  static Future<void> request() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<String>('request');
  }

  /// Android 共享存储根目录（通常是 /storage/emulated/0）。
  static Future<String?> androidRoot() async {
    if (!_isAndroid) return null;
    return _channel.invokeMethod<String>('root');
  }
}
