import 'package:flutter/material.dart';

import '../../domain/models/habit.dart'; // adjust path to match your project

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  bool isWeekView = false; // false = Month, true = Week

  Color get accentColor {
    var hex = widget.habit.colorHex
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .replaceFirst('0X', '');
    if (hex.length == 6) hex = 'FF$hex'; // add alpha if missing
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.habit.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeatmap(),
            const SizedBox(height: 12),
            _buildToggle(),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Adjust'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final shades = [
      accentColor.withValues(alpha: .15),
      accentColor.withValues(alpha: .35),
      accentColor.withValues(alpha: .55),
      accentColor.withValues(alpha: .75),
      accentColor,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 35,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final shade = shades[index % shades.length];
        return Container(
          decoration: BoxDecoration(
            color: shade,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildToggle() {
    return Row(
      children: [
        Expanded(
          child: _toggleButton('Week', isWeekView, () {
            setState(() => isWeekView = true);
          }),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _toggleButton('Month', !isWeekView, () {
            setState(() => isWeekView = false);
          }),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.transparent,
          border: Border.all(
            color: selected ? accentColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    // Replace hardcoded values with real calculations from your logs provider
    final stats = [
      _StatData(Icons.local_fire_department, 'Current streak', '1 day'),
      _StatData(Icons.access_time, 'Time since started', '366 days'),
      _StatData(Icons.check_circle, 'Completions', '25 times'),
      _StatData(Icons.event_busy, 'Missed days', '6 days'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat.label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(stat.icon, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  _StatData(this.icon, this.label, this.value);
}
