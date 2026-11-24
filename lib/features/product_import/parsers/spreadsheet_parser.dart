import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'column_mapper.dart';

/// Excel, CSV and public Google Sheets → [ParsedSheet] / canonical rows.
class SpreadsheetParser {
  SpreadsheetParser._();

  static ParsedSheet? parseXlsxSheet(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      for (final sheet in excel.tables.values) {
        final table = <List<String>>[];
        for (var r = 0; r < sheet.rows.length; r++) {
          try {
            table.add(sheet.rows[r].map((cell) => _cellText(cell?.value)).toList());
          } catch (e, st) {
            debugPrint('xlsx row $r cell read failed: $e\n$st');
            table.add(const []);
          }
        }
        final parsed = ColumnMapper.parseSheet(table);
        if (parsed != null && !parsed.isEmpty) return parsed;
      }
    } catch (e, st) {
      debugPrint('Excel.decodeBytes failed, using raw xlsx fallback: $e\n$st');
    }
    return _parseXlsxRawSheet(bytes);
  }

  static List<Map<String, String>> parseXlsx(Uint8List bytes) {
    final sheet = parseXlsxSheet(bytes);
    if (sheet == null) return const [];
    return sheet.applyMapping(sheet.suggestedMapping);
  }

  /// Every sheet as `cell | cell` lines, for the AI fallback when headers are not recognised.
  static String parseXlsxAsText(List<int> bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      return excel.tables.values
          .expand((sheet) => sheet.rows)
          .map((cells) {
            try {
              return cells.map((cell) => _cellText(cell?.value)).where((t) => t.isNotEmpty).join(' | ');
            } catch (e, st) {
              debugPrint('xlsx text row failed: $e\n$st');
              return '';
            }
          })
          .where((line) => line.isNotEmpty)
          .join('\n');
    } catch (e, st) {
      debugPrint('parseXlsxAsText decode failed, using raw fallback: $e\n$st');
      final tables = _parseXlsxRawTables(Uint8List.fromList(bytes));
      return tables
          .expand((table) => table)
          .map((row) => row.where((c) => c.isNotEmpty).join(' | '))
          .where((line) => line.isNotEmpty)
          .join('\n');
    }
  }

  static ParsedSheet? parseCsvSheet(String text) {
    final table = Csv().decode(text.replaceFirst('\uFEFF', ''));
    return ColumnMapper.parseSheet(table.map((r) => r.map((c) => '${c ?? ''}').toList()).toList());
  }

  static List<Map<String, String>> parseCsv(String text) {
    final sheet = parseCsvSheet(text);
    if (sheet == null) return const [];
    return sheet.applyMapping(sheet.suggestedMapping);
  }

  static ParsedSheet? parseCsvBytesSheet(Uint8List bytes) => parseCsvSheet(utf8.decode(bytes, allowMalformed: true));

  static List<Map<String, String>> parseCsvBytes(Uint8List bytes) => parseCsv(utf8.decode(bytes, allowMalformed: true));

  /// Accepts any Google Sheets link; the sheet must be shared as "anyone with the link can view".
  static Future<ParsedSheet?> fetchGoogleSheetParsed(String link) async {
    final id = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(link)?.group(1);
    if (id == null) throw 'رابط Google Sheets غير صحيح';
    final gid = RegExp(r'[#&?]gid=(\d+)').firstMatch(link)?.group(1);
    final uri = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$id/export?format=csv${gid == null ? '' : '&gid=$gid'}',
    );
    final response = await http.get(uri);
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (response.statusCode != 200 || body.trimLeft().startsWith('<')) {
      throw 'تعذر قراءة الشيت، تأكد أن المشاركة "أي شخص لديه الرابط"';
    }
    return parseCsvSheet(body);
  }

  static Future<List<Map<String, String>>> fetchGoogleSheet(String link) async {
    final sheet = await fetchGoogleSheetParsed(link);
    if (sheet == null) return const [];
    return sheet.applyMapping(sheet.suggestedMapping);
  }

  static String _cellText(CellValue? value) {
    if (value == null) return '';
    try {
      return switch (value) {
        TextCellValue(:final value) => value.toString(),
        IntCellValue(:final value) => '$value',
        DoubleCellValue(:final value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value',
        BoolCellValue(:final value) => value ? 'true' : 'false',
        FormulaCellValue(:final formula) => formula,
        DateCellValue(:final year, :final month, :final day) =>
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        DateTimeCellValue() => value.toString(),
        TimeCellValue() => value.toString(),
      };
    } catch (e, st) {
      debugPrint('excel cell toString failed: $e\n$st value=$value');
      return '';
    }
  }

  static ParsedSheet? _parseXlsxRawSheet(Uint8List bytes) {
    for (final table in _parseXlsxRawTables(bytes)) {
      final parsed = ColumnMapper.parseSheet(table);
      if (parsed != null && !parsed.isEmpty) return parsed;
    }
    return null;
  }

  static List<List<List<String>>> _parseXlsxRawTables(Uint8List bytes) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (e, st) {
      debugPrint('xlsx zip decode failed: $e\n$st');
      return const [];
    }
    final shared = _readSharedStrings(archive);
    final sheets = archive.files
        .where((f) => f.name.contains('xl/worksheets/sheet') && f.name.endsWith('.xml') && f.isFile)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final tables = <List<List<String>>>[];
    for (final file in sheets) {
      try {
        file.decompress();
        final content = file.content;
        final xmlBytes = content is List<int> ? content : (content as Uint8List).toList();
        tables.add(_sheetXmlToTable(utf8.decode(xmlBytes, allowMalformed: true), shared));
      } catch (e, st) {
        debugPrint('raw sheet ${file.name} failed: $e\n$st');
      }
    }
    return tables;
  }

  static List<String> _readSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return const [];
    try {
      file.decompress();
      final content = file.content;
      final xmlBytes = content is List<int> ? content : (content as Uint8List).toList();
      final doc = XmlDocument.parse(utf8.decode(xmlBytes, allowMalformed: true));
      return doc.findAllElements('si').map((si) {
        final texts = si.findAllElements('t').map((t) => t.innerText).toList();
        if (texts.isNotEmpty) return texts.join();
        return si.innerText;
      }).toList();
    } catch (e, st) {
      debugPrint('sharedStrings parse failed: $e\n$st');
      return const [];
    }
  }

  static List<List<String>> _sheetXmlToTable(String xml, List<String> shared) {
    final doc = XmlDocument.parse(xml);
    final grid = <int, Map<int, String>>{};
    var maxRow = -1;
    var maxCol = -1;

    for (final cell in doc.findAllElements('c')) {
      final ref = cell.getAttribute('r');
      if (ref == null || ref.isEmpty) continue;
      final coords = _cellRef(ref);
      if (coords == null) continue;
      final (row, col) = coords;
      final text = _xmlCellText(cell, shared);
      grid.putIfAbsent(row, () => {})[col] = text;
      if (row > maxRow) maxRow = row;
      if (col > maxCol) maxCol = col;
    }

    if (maxRow < 0) return const [];
    return [
      for (var r = 0; r <= maxRow; r++)
        [for (var c = 0; c <= maxCol; c++) grid[r]?[c] ?? ''],
    ];
  }

  static String _xmlCellText(XmlElement cell, List<String> shared) {
    try {
      final type = cell.getAttribute('t');
      if (type == 's') {
        final v = cell.findElements('v').firstOrNull?.innerText.trim() ?? '';
        final index = int.tryParse(v);
        if (index == null || index < 0 || index >= shared.length) return '';
        return shared[index];
      }
      if (type == 'inlineStr' || type == 'str') {
        final inline = cell.findAllElements('t').map((t) => t.innerText).join();
        if (inline.isNotEmpty) return inline;
      }
      if (type == 'b') {
        final v = cell.findElements('v').firstOrNull?.innerText.trim() ?? '';
        return v == '1' ? 'true' : 'false';
      }
      final v = cell.findElements('v').firstOrNull?.innerText ?? '';
      return v.trim();
    } catch (e, st) {
      debugPrint('xml cell text failed: $e\n$st');
      return '';
    }
  }

  static (int row, int col)? _cellRef(String ref) {
    final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(ref.trim());
    if (match == null) return null;
    final letters = match.group(1)!.toUpperCase();
    final row = int.tryParse(match.group(2)!);
    if (row == null || row < 1) return null;
    var col = 0;
    for (final code in letters.codeUnits) {
      col = col * 26 + (code - 64);
    }
    return (row - 1, col - 1);
  }
}
