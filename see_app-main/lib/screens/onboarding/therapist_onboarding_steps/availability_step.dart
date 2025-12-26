import 'package:flutter/material.dart';

class AvailabilityStep extends StatefulWidget {
  const AvailabilityStep({Key? key}) : super(key: key);

  @override
  State<AvailabilityStep> createState() => _AvailabilityStepState();
}

class _AvailabilityStepState extends State<AvailabilityStep> {
  final List<String> _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  final Set<String> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Availability', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Select your available days. You can set specific times later.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _days.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(day),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
                backgroundColor: Colors.white24,
                selectedColor: Colors.blue,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 