import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import '../parsers/column_mapper.dart';

/// Turns unstructured catalogues (PDF, Word text, messy sheets) into canonical import rows with Gemini
/// (Firebase AI Logic, Gemini Developer API free tier). Output is forced to [_schema].
class GeminiProductExtractor {
  GeminiProductExtractor._();

  static const String _model = 'gemini-flash-latest';

  /// Keeps each request well inside the free-tier token limits.
  static const int _chunkChars = 12000;

  /// Gemini inline data limit.
  static const int maxPdfBytes = 19 * 1024 * 1024;

  static final Schema _schema = Schema.object(properties: {
    'products': Schema.array(
      items: Schema.object(
        properties: {
          'productid': Schema.string(description: 'SKU or product code if present'),
          'groupId': Schema.string(description: 'Same value for colors of the same model'),
          'name': Schema.string(description: 'English product name'),
          'nameAr': Schema.string(description: 'Arabic product name'),
          'des': Schema.string(description: 'English description'),
          'desAr': Schema.string(description: 'Arabic description'),
          'brand': Schema.string(),
          'category': Schema.string(description: 'One of the store categories'),
          'price': Schema.number(description: 'Current selling price'),
          'oldPrice': Schema.number(description: 'Price before discount, 0 if none'),
          'color': Schema.string(description: 'English color name'),
          'colorAr': Schema.string(description: 'Arabic color name'),
          'colorHex': Schema.string(description: 'Color as #RRGGBB'),
          'stock': Schema.array(
            items: Schema.object(properties: {'size': Schema.string(), 'quantity': Schema.integer()}),
          ),
          'images': Schema.array(items: Schema.string(), description: 'Image URLs or file names mentioned'),
        },
        optionalProperties: [
          'productid', 'groupId', 'des', 'desAr', 'brand', 'oldPrice',
          'color', 'colorAr', 'colorHex', 'stock', 'images', 'nameAr', 'name',
        ],
      ),
    ),
  });

  static String _prompt(List<String> categories) => '''
You extract fashion products from a store catalogue for import.
Rules:
- One output item per product color. If a model comes in several colors, output one item per color and give them the same groupId.
- category must be exactly one of: ${categories.join(', ')}. Choose the closest one.
- Fill both English and Arabic names/descriptions; translate when only one language is given.
- price is the current selling price. oldPrice is the price before discount, or 0.
- colorHex is your best #RRGGBB guess for the color name.
- stock lists each size with its quantity; use 0 when the quantity is unknown.
- Never invent products that are not in the document. Return {"products": []} if there are none.''';

  static GenerativeModel _client() => FirebaseAI.googleAI().generativeModel(
        model: _model,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _schema,
          temperature: 0.1,
        ),
      );

  static Future<List<Map<String, String>>> fromPdf(Uint8List bytes, List<String> categories) async {
    if (bytes.length > maxPdfBytes) throw 'ملف PDF أكبر من 19 ميجا، قسّمه لملفات أصغر';
    return _run([
      Content.multi([TextPart(_prompt(categories)), InlineDataPart('application/pdf', bytes)]),
    ]);
  }

  /// [onChunk] reports progress as (done, total) chunks.
  static Future<List<Map<String, String>>> fromText(
    String text,
    List<String> categories, {
    void Function(int done, int total)? onChunk,
  }) async {
    final chunks = _split(text);
    final rows = <Map<String, String>>[];
    for (var i = 0; i < chunks.length; i++) {
      rows.addAll(await _run([Content.text('${_prompt(categories)}\n\nDocument:\n${chunks[i]}')]));
      onChunk?.call(i + 1, chunks.length);
    }
    return rows;
  }

  static Future<List<Map<String, String>>> _run(List<Content> content) async {
    try {
      final response = await _client().generateContent(content);
      final decoded = jsonDecode(response.text ?? '{}');
      final products = decoded is Map ? decoded['products'] : null;
      if (products is! List) return const [];
      return products.whereType<Map>().map(_toRaw).toList();
    } on QuotaExceeded {
      throw 'تم استهلاك الحصة المجانية لـ Gemini اليوم، حاول لاحقاً';
    } on ServiceApiNotEnabled {
      throw 'فعّل Firebase AI Logic (Gemini Developer API) من Firebase Console أولاً';
    } on FormatException {
      throw 'رد غير مفهوم من الذكاء الاصطناعي، حاول مرة أخرى';
    }
  }

  static Map<String, String> _toRaw(Map item) {
    final raw = <String, String>{};
    item.forEach((key, value) {
      if (key == 'stock' && value is List) {
        raw[ImportColumns.stock] = value
            .whereType<Map>()
            .map((s) => '${s['size'] ?? ''}:${s['quantity'] ?? 0}')
            .where((s) => !s.startsWith(':'))
            .join('|');
      } else if (key == 'images' && value is List) {
        raw[ImportColumns.images] = value.map((e) => '$e').join('|');
      } else if (value != null && '$value'.trim().isNotEmpty) {
        raw['$key'] = '$value'.trim();
      }
    });
    return raw;
  }

  /// Splits on line boundaries so a product is rarely cut in half.
  static List<String> _split(String text) {
    final chunks = <String>[];
    final buffer = StringBuffer();
    for (final line in const LineSplitter().convert(text)) {
      if (buffer.length + line.length > _chunkChars && buffer.isNotEmpty) {
        chunks.add(buffer.toString());
        buffer.clear();
      }
      buffer.writeln(line);
    }
    if (buffer.isNotEmpty) chunks.add(buffer.toString());
    return chunks;
  }
}
