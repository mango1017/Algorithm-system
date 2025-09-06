/// ───────────────────────────────────────────
/// 資料結構視覺化：只同步顯示已走訪的節點
/// ───────────────────────────────────────────
import 'package:flutter/material.dart';

class DSVisualizer extends StatelessWidget {
  final bool isQueue;
  final List<int> items;

  const DSVisualizer({
    Key? key,
    required this.isQueue,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arrow = isQueue ? Icons.arrow_forward : Icons.arrow_back;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${items[i]}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (i < items.length - 1)
              Icon(arrow, size: 16),
          ],
        ],
      ),
    );
  }
}
