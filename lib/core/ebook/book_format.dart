import 'package:path/path.dart' as p;

/// 支持的电子书格式。数据库 `documents.format` 存枚举名。
enum BookFormat {
  pdf,
  epub,
}

/// 按扩展名判定支持的格式；其它格式返回 null（扫描与导入共用）。
BookFormat? formatOfFileName(String name) =>
    switch (p.extension(name).toLowerCase()) {
      '.pdf' => BookFormat.pdf,
      '.epub' => BookFormat.epub,
      _ => null,
    };
