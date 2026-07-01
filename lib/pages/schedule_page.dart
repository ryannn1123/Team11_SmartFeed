import 'package:flutter/material.dart';
import '../main.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _loading = true);

    try {
      final res = await supabase
          .from('schedule')
          .select()
          .order('feed_time', ascending: true);

      setState(() {
        _schedules = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addSchedule() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AddScheduleDialog(),
    );

    if (result == null) return;

    try {
      await supabase.from('schedule').insert({
        'feed_time': result['feed_time'],
        'angle': result['angle'],
        'enabled': true,
      });

      _fetchSchedules();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editSchedule(Map<String, dynamic> schedule) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AddScheduleDialog(existing: schedule),
    );

    if (result == null) return;

    try {
      await supabase
          .from('schedule')
          .update({
            'feed_time': result['feed_time'],
            'angle': result['angle'],
          })
          .eq('id', schedule['id'] as int);

      _fetchSchedules();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleSchedule(int id, bool enabled) async {
    await supabase.from('schedule').update({'enabled': enabled}).eq('id', id);
    _fetchSchedules();
  }

  Future<void> _deleteSchedule(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete feeding time?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('This feeding schedule will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('schedule').delete().eq('id', id);
      _fetchSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 125),
        child: FloatingActionButton.extended(
          onPressed: _addSchedule,
          backgroundColor: const Color(0xFFFF8A4C),
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add feeding time',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7EF),
              Color(0xFFE8F4FD),
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF8A4C),
                  ),
                )
              : _schedules.isEmpty
                  ? const _EmptyScheduleState()
                  : RefreshIndicator(
                      color: const Color(0xFFFF8A4C),
                      onRefresh: _fetchSchedules,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 190),
                        itemCount: _schedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final s = _schedules[index];
                          final time = s['feed_time'].toString().substring(0, 5);
                          final enabled = s['enabled'] as bool;
                          final angle = s['angle'] as int? ?? 90;

                          return _ScheduleCard(
                            time: time,
                            angle: angle,
                            enabled: enabled,
                            onEdit: () => _editSchedule(s),
                            onDelete: () => _deleteSchedule(s['id'] as int),
                            onToggle: (val) =>
                                _toggleSchedule(s['id'] as int, val),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time;
  final int angle;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _ScheduleCard({
    required this.time,
    required this.angle,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  static const Color _orange = Color(0xFFFF8A4C);
  static const Color _dark = Color(0xFF172033);
  static const Color _muted = Color(0xFF7A8292);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: enabled
                ? _orange.withOpacity(0.25)
                : Colors.grey.withOpacity(0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: enabled
                          ? const [Color(0xFFFF9A62), Color(0xFFFFC36C)]
                          : [Colors.grey.shade300, Colors.grey.shade200],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: _dark,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Scheduled feeding time',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeColor: _orange,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.rotate_right_rounded,
                        size: 16,
                        color: _orange,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Servo $angle°',
                        style: const TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: angle / 180,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFFFE2D3),
                      color: _orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      side: BorderSide(color: _orange.withOpacity(0.45)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEEF0),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.84),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_meals_rounded,
                size: 70,
                color: Color(0xFFFF8A4C),
              ),
              SizedBox(height: 18),
              Text(
                'No meals scheduled',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap “Add feeding time” to create your pet’s next meal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7A8292),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _AddScheduleDialog({this.existing});

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  TimeOfDay? _selectedTime;
  double _angle = 90;

  static const Color _orange = Color(0xFFFF8A4C);
  static const Color _dark = Color(0xFF172033);
  static const Color _muted = Color(0xFF7A8292);

  final List<Map<String, dynamic>> _presets = [
    {'label': 'Closed', 'angle': 0},
    {'label': 'Small', 'angle': 45},
    {'label': 'Medium', 'angle': 90},
    {'label': 'Large', 'angle': 135},
    {'label': 'Full', 'angle': 180},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existing != null) {
      final time = widget.existing!['feed_time'].toString().substring(0, 5);
      final parts = time.split(':');

      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );

      _angle = (widget.existing!['angle'] as int? ?? 90).toDouble();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: _orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: const Color(0xFFFFFDF9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        isEdit ? 'Edit feeding time' : 'Add feeding time',
        style: const TextStyle(
          color: _dark,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feeding Time',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2D3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _orange.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: _orange),
                    const SizedBox(width: 10),
                    Text(
                      _selectedTime == null
                          ? 'Tap to pick time'
                          : _selectedTime!.format(context),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _selectedTime == null ? _muted : _dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portion Angle',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_angle.round()}°',
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _orange,
                inactiveTrackColor: const Color(0xFFFFE2D3),
                thumbColor: Colors.white,
                overlayColor: _orange.withOpacity(0.18),
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _angle,
                min: 0,
                max: 180,
                divisions: 180,
                label: '${_angle.round()}°',
                onChanged: (val) {
                  setState(() => _angle = val.roundToDouble());
                },
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Portion presets',
              style: TextStyle(
                fontSize: 12,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final presetAngle = p['angle'] as int;
                final isSelected = _angle.round() == presetAngle;

                return InkWell(
                  onTap: () => setState(() => _angle = presetAngle.toDouble()),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _orange : const Color(0xFFFFE2D3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${p['label']} $presetAngle°',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : _orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _muted),
          ),
        ),
        FilledButton(
          onPressed: _selectedTime == null
              ? null
              : () {
                  final timeStr =
                      '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
                      '${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

                  Navigator.pop(context, {
                    'feed_time': timeStr,
                    'angle': _angle.round(),
                  });
                },
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}