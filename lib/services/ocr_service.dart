import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/word.dart';

/// OCR识别服务
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  /// 从相机拍照
  Future<File?> takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    return File(image.path);
  }

  /// 从相册选择图片
  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    return File(image.path);
  }

  /// 识别图片中的文字
  Future<OCRResult> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 解析识别结果
      final lines = <OCRLine>[];
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;
          
          // 尝试识别单词和标记
          final parsedLine = _parseLine(text, line.boundingBox);
          lines.add(parsedLine);
        }
      }
      
      return OCRResult(
        success: true,
        lines: lines,
        rawText: recognizedText.text,
      );
    } catch (e) {
      return OCRResult(
        success: false,
        error: e.toString(),
        lines: [],
        rawText: '',
      );
    }
  }

  /// 解析单行文字，识别单词和标记
  OCRLine _parseLine(String text, Rect? boundingBox) {
    // 检测 ✓ 或 X 标记
    // 常见模式：
    // "✓ cotton" 或 "✓cotton" - 认识
    // "X abandon" 或 "Xabandon" - 不认识
    // "cotton 棉花" - 单词和意思
    
    bool hasCheck = false;
    bool hasCross = false;
    String cleanText = text;
    
    // 检测 ✓ 标记（可能有多种形式）
    if (text.contains('✓') || 
        text.contains('√') || 
        text.contains('✔') ||
        text.toLowerCase().contains('check') ||
        text.toLowerCase().contains('tick')) {
      hasCheck = true;
      cleanText = cleanText
          .replaceAll('✓', '')
          .replaceAll('√', '')
          .replaceAll('✔', '')
          .replaceAll(RegExp(r'(?i)check'), '')
          .replaceAll(RegExp(r'(?i)tick'), '')
          .trim();
    }
    
    // 检测 X 标记
    if (text.startsWith('X ') || 
        text.startsWith('x ') ||
        text.startsWith('×') ||
        text.startsWith('✗')) {
      hasCross = true;
      cleanText = cleanText
          .replaceFirst(RegExp(r'^[Xx×✗]\s*'), '')
          .trim();
    }
    
    // 尝试分离英文单词和中文意思
    String? word;
    String? meaning;
    
    // 匹配英文单词
    final englishRegex = RegExp(r'^([a-zA-Z\-]+)');
    final englishMatch = englishRegex.firstMatch(cleanText);
    
    if (englishMatch != null) {
      word = englishMatch.group(1)?.toLowerCase();
      
      // 剩余部分作为意思
      final remaining = cleanText.substring(englishMatch.end).trim();
      if (remaining.isNotEmpty) {
        meaning = remaining;
      }
    }
    
    return OCRLine(
      originalText: text,
      cleanText: cleanText,
      word: word,
      meaning: meaning,
      hasCheckMark: hasCheck,
      hasCrossMark: hasCross,
      boundingBox: boundingBox,
    );
  }

  /// 将识别结果转换为单词列表
  List<Word> convertToWords(List<OCRLine> lines) {
    final words = <Word>[];
    
    for (final line in lines) {
      if (line.word == null || line.word!.isEmpty) continue;
      
      words.add(Word(
        word: line.word!,
        meaning: line.meaning ?? '',
        checkCount: line.hasCheckMark ? 1 : 0,
        crossCount: line.hasCrossMark ? 1 : 0,
        familiarity: line.hasCheckMark ? 1 : 0,
      ));
    }
    
    return words;
  }

  /// 释放资源
  void dispose() {
    _textRecognizer.close();
  }
}

/// OCR识别结果
class OCRResult {
  final bool success;
  final String? error;
  final List<OCRLine> lines;
  final String rawText;

  OCRResult({
    required this.success,
    this.error,
    required this.lines,
    required this.rawText,
  });
}

/// OCR识别的单行数据
class OCRLine {
  final String originalText; // 原始识别文本
  final String cleanText; // 清理后的文本
  final String? word; // 识别出的英文单词
  final String? meaning; // 识别出的意思
  final bool hasCheckMark; // 是否有 ✓ 标记
  final bool hasCrossMark; // 是否有 X 标记
  final Rect? boundingBox; // 文字区域

  OCRLine({
    required this.originalText,
    required this.cleanText,
    this.word,
    this.meaning,
    required this.hasCheckMark,
    required this.hasCrossMark,
    this.boundingBox,
  });

  @override
  String toString() {
    return 'OCRLine(word: $word, meaning: $meaning, check: $hasCheckMark, cross: $hasCrossMark)';
  }
}

/// OCR识别对话框组件
class OCRResultDialog extends StatefulWidget {
  final OCRResult result;
  final Function(List<Word>) onConfirm;

  const OCRResultDialog({
    super.key,
    required this.result,
    required this.onConfirm,
  });

  @override
  State<OCRResultDialog> createState() => _OCRResultDialogState();
}

class _OCRResultDialogState extends State<OCRResultDialog> {
  late List<_EditableWord> _editableWords;

  @override
  void initState() {
    super.initState();
    _editableWords = widget.result.lines
        .where((line) => line.word != null && line.word!.isNotEmpty)
        .map((line) => _EditableWord(
              word: line.word ?? '',
              meaning: line.meaning ?? '',
              hasCheck: line.hasCheckMark,
              hasCross: line.hasCrossMark,
              selected: true,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.result.success) {
      return AlertDialog(
        title: const Text('识别失败'),
        content: Text('错误: ${widget.result.error}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('识别结果 (${_editableWords.length} 个单词)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _editableWords.isEmpty
            ? const Center(child: Text('未识别到单词'))
            : ListView.builder(
                itemCount: _editableWords.length,
                itemBuilder: (context, index) {
                  final item = _editableWords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.selected,
                            onChanged: (value) {
                              setState(() {
                                item.selected = value ?? false;
                              });
                            },
                          ),
                          // 标记按钮
                          IconButton(
                            icon: Icon(
                              Icons.check,
                              color: item.hasCheck ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                item.hasCheck = !item.hasCheck;
                                if (item.hasCheck) item.hasCross = false;
                              });
                            },
                            tooltip: '标记为认识',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: item.hasCross ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                item.hasCross = !item.hasCross;
                                if (item.hasCross) item.hasCheck = false;
                              });
                            },
                            tooltip: '标记为不认识',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: TextEditingController(text: item.word),
                                  decoration: const InputDecoration(
                                    labelText: '单词',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    item.word = value;
                                  },
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: TextEditingController(text: item.meaning),
                                  decoration: const InputDecoration(
                                    labelText: '意思',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    item.meaning = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final words = _editableWords
                .where((e) => e.selected && e.word.isNotEmpty)
                .map((e) => Word(
                      word: e.word,
                      meaning: e.meaning,
                      checkCount: e.hasCheck ? 1 : 0,
                      crossCount: e.hasCross ? 1 : 0,
                      familiarity: e.hasCheck ? 1 : 0,
                    ))
                .toList();
            
            widget.onConfirm(words);
            Navigator.pop(context);
          },
          child: const Text('导入'),
        ),
      ],
    );
  }
}

class _EditableWord {
  String word;
  String meaning;
  bool hasCheck;
  bool hasCross;
  bool selected;

  _EditableWord({
    required this.word,
    required this.meaning,
    required this.hasCheck,
    required this.hasCross,
    required this.selected,
  });
}
