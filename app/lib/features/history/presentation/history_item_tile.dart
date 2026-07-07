import 'package:flutter/material.dart';

import '../../analysis/domain/analysis.dart';

class HistoryItemTile extends StatelessWidget {
  const HistoryItemTile({
    required this.analysis,
    required this.onTap,
    super.key,
  });

  final Analysis analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _scoreColor(context, analysis.score.value),
          foregroundColor: Colors.white,
          child: Text(analysis.score.value.toString()),
        ),
        title: Text('Barcode ${analysis.barcode}'),
        subtitle: Text(
          '${analysis.score.label} • ${analysis.createdAt.toLocal()}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color _scoreColor(BuildContext context, int value) {
    if (value >= 80) {
      return const Color(0xFF1F7A4D);
    }
    if (value >= 55) {
      return const Color(0xFFB7791F);
    }
    return Theme.of(context).colorScheme.error;
  }
}
