import 'package:flutter/material.dart';
import '../models/word.dart';

/// 单词卡片组件
class WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WordCard({
    super.key,
    required this.word,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 熟悉度指示器
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _getFamiliarityColor(word.familiarity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // 单词信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (word.phonetic != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            word.phonetic!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.meaning,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 统计信息
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green[400]),
                      Text(
                        '${word.checkCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[400],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.close, size: 16, color: Colors.red[400]),
                      Text(
                        '${word.crossCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getFamiliarityColor(word.familiarity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lv.${word.familiarity}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getFamiliarityColor(word.familiarity),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFamiliarityColor(int familiarity) {
    switch (familiarity) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.green;
      case 5:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
