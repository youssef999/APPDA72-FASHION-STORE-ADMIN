import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'column_mapper.dart';

class DocxContent {
  /// Rows from a table whose header matches the template (no AI needed).
  final List<Map<String, String>> tableRows;

  /// All paragraphs and tables as plain text, sent to Gemini when there is no usable table.
  final String text;

  const DocxContent(this.tableRows, this.text);
}

/// Reads `word/document.xml` from a .docx (a zip) without any server.
class DocxParser {
  DocxParser._();

  static DocxContent parse(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.findFile('word/document.xml');
    if (entry == null) throw 'ملف Word غير صالح';
    final document = XmlDocument.parse(utf8.decode(entry.content as List<int>, allowMalformed: true));

    final rows = <Map<String, String>>[];
    final lines = <String>[];
    final body = document.findAllElements('w:body').firstOrNull;
    if (body == null) return const DocxContent([], '');

    for (final node in body.childElements) {
      if (node.name.qualified == 'w:tbl') {
        final table = node
            .findElements('w:tr')
            .map((tr) => tr.findElements('w:tc').map(_text).toList())
            .toList();
        rows.addAll(ColumnMapper.mapTable(table));
        lines.addAll(table.map((cells) => cells.join(' | ')));
      } else if (node.name.qualified == 'w:p') {
        final text = _text(node);
        if (text.isNotEmpty) lines.add(text);
      }
    }
    return DocxContent(rows, lines.join('\n'));
  }

  static String _text(XmlElement element) {
    final paragraphs = element.name.qualified == 'w:p' ? [element] : element.findAllElements('w:p').toList();
    return paragraphs
        .map((p) => p.findAllElements('w:t').map((t) => t.innerText).join())
        .where((t) => t.trim().isNotEmpty)
        .join(' ')
        .trim();
  }
}
