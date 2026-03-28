import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('穿搭记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // 日历视图
            },
          ),
        ],
      ),
      body: Consumer<WardrobeProvider>(
        builder: (context, provider, child) {
          if (provider.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有穿搭记录',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '记录每天的穿搭，追踪穿衣习惯',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.records.length,
            itemBuilder: (context, index) {
              final record = provider.records[index];
              return _buildRecordCard(context, record);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 添加记录
        },
        icon: const Icon(Icons.add),
        label: const Text('记录今天'),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, dynamic record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    '${record.date.day}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(record.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (record.occasion != null)
                        Text(
                          record.occasion,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (record.weather != null)
                  Chip(
                    label: Text(record.weather),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: record.clothingIds.map<Widget>((id) {
                return Chip(
                  label: Text('单品'),
                  avatar: const Icon(Icons.checkroom, size: 16),
                );
              }).toList(),
            ),
            if (record.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                record.notes,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.year}年${date.month}月${date.day}日 周${weekdays[date.weekday - 1]}';
  }
}
