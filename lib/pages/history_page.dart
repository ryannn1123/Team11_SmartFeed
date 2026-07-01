import 'package:flutter/material.dart';
import '../main.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filter = 'All';

  final List<String> _filters = ['All', 'Manual', 'Scheduled'];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    try {
      var query = supabase
          .from('feeding_logs')
          .select()
          .order('fed_at', ascending: false);

      final res = await query;
      setState(() {
        _logs = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filter == 'All') return _logs;
    return _logs.where((log) {
      final type = (log['trigger_type'] as String? ?? 'manual').toLowerCase();
      return type == _filter.toLowerCase();
    }).toList();
  }

  String _portionLabel(int? angle) {
    if (angle == null) return 'Unknown';
    if (angle == 0) return 'Closed';
    if (angle <= 45) return 'Small';
    if (angle <= 90) return 'Medium';
    if (angle <= 135) return 'Large';
    return 'Full';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '—';
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $hour:$min $ampm';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '—';
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '—';
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  // Group logs by date
  Map<String, List<Map<String, dynamic>>> get _groupedLogs {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final log in _filteredLogs) {
      final date = _formatDate(log['fed_at'] as String?);
      grouped.putIfAbsent(date, () => []).add(log);
    }
    return grouped;
  }

  // Stats
  int get _totalFeedings => _logs.length;
  int get _todayFeedings {
    final today = DateTime.now();
    return _logs.where((log) {
      final dt = DateTime.tryParse(log['fed_at'] as String? ?? '')?.toLocal();
      if (dt == null) return false;
      return dt.day == today.day &&
          dt.month == today.month &&
          dt.year == today.year;
    }).length;
  }

  String get _mostCommonPortion {
    if (_logs.isEmpty) return '—';
    final counts = <String, int>{};
    for (final log in _logs) {
      final label = log['portion_label'] as String? ??
          _portionLabel(log['angle'] as int?);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Future<void> _deleteLog(int id) async {
    try {
      await supabase.from('feeding_logs').delete().eq('id', id);
      setState(() {
        _logs.removeWhere((log) => log['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Log deleted'),
            backgroundColor: Color(0xFFFF9E89),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Color(0xFFFF6F61)),
            SizedBox(width: 8),
            Text('Delete All Logs?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all feeding history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F61),
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('feeding_logs')
          .delete()
          .neq('id', 0); // delete all rows
      setState(() => _logs = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All logs deleted'),
            backgroundColor: Color(0xFFFF9E89),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9E89),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Feeding History',
          style: TextStyle(
            color: Color(0xFF5B3A29),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5B3A29)),
            onPressed: _fetchLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF5B3A29)),
            tooltip: 'Delete all logs',
            onPressed: _deleteAllLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: CustomScrollView(
                slivers: [
                  // Stats Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Total Feedings',
                                  value: '$_totalFeedings',
                                  icon: Icons.history,
                                  color: const Color(0xFFFF9E89),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Today',
                                  value: '$_todayFeedings',
                                  icon: Icons.today,
                                  color: const Color(0xFFFFBFA3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Common Portion',
                                  value: _mostCommonPortion,
                                  icon: Icons.pie_chart,
                                  color: const Color(0xFFFFEFC4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Filter chips
                          Row(
                            children: _filters.map((f) {
                              final selected = _filter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _filter = f),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFFF9E89)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFFF9E89),
                                      ),
                                    ),
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFFFF9E89),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Empty state
                  if (_filteredLogs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.no_meals,
                              size: 64,
                              color: const Color(0xFFFF9E89).withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No feeding logs yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B3A29),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Logs appear after the feeder feeds your pet',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF5B3A29).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Grouped logs
                  for (final entry in grouped.entries) ...[
                    // Date header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9E89).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5B3A29),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                color: const Color(0xFFFF9E89).withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Log items
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final log = entry.value[index];
                          final angle = log['angle'] as int?;
                          final portion = log['portion_label'] as String? ??
                              _portionLabel(angle);
                          final triggerType =
                              log['trigger_type'] as String? ?? 'manual';
                          final isScheduled =
                              triggerType.toLowerCase() == 'scheduled';

                          return Dismissible(
                            key: Key('log_${log['id']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red, size: 26),
                                  SizedBox(height: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Delete this log?'),
                                  content: const Text(
                                      'This feeding record will be removed.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF6F61),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) =>
                                _deleteLog(log['id'] as int),
                            child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isScheduled
                                    ? const Color(0xFFFFBFA3)
                                    : const Color(0xFFFF9E89).withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isScheduled
                                          ? const Color(0xFFFFBFA3).withOpacity(0.25)
                                          : const Color(0xFFFF9E89).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isScheduled
                                          ? Icons.schedule
                                          : Icons.touch_app,
                                      color: isScheduled
                                          ? const Color(0xFFFF8C6B)
                                          : const Color(0xFFFF6F61),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _formatTime(
                                                  log['fed_at'] as String?),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF5B3A29),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isScheduled
                                                    ? const Color(0xFFFFBFA3).withOpacity(0.3)
                                                    : const Color(0xFFFF9E89).withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isScheduled
                                                    ? 'Scheduled'
                                                    : 'Manual',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isScheduled
                                                      ? const Color(0xFFFF8C6B)
                                                      : const Color(0xFFFF6F61),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.rotate_right,
                                              size: 14,
                                              color: const Color(0xFF5B3A29)
                                                  .withOpacity(0.5),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$portion portion${angle != null ? ' ($angle°)' : ''}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: const Color(0xFF5B3A29)
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (log['notes'] != null &&
                                            (log['notes'] as String)
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            log['notes'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF5B3A29)
                                                  .withOpacity(0.4),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Angle progress
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        angle != null ? '$angle°' : '—',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFF9E89),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 48,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: angle != null
                                                ? angle / 180
                                                : 0,
                                            backgroundColor:
                                                Colors.grey.withOpacity(0.15),
                                            color: const Color(0xFFFF9E89),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ), // close Container (Dismissible child)
                          ); // close Dismissible
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ],

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color.darken(0.15)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5B3A29),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF5B3A29).withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}