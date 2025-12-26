import 'package:flutter/material.dart';

class SpecialtiesStep extends StatefulWidget {
  const SpecialtiesStep({Key? key}) : super(key: key);

  @override
  State<SpecialtiesStep> createState() => _SpecialtiesStepState();
}

class _SpecialtiesStepState extends State<SpecialtiesStep> {
  final List<String> _allSpecialties = [
    'Speech Therapy',
    'Occupational Therapy',
    'Physical Therapy',
    'Behavioral Therapy',
    'Music Therapy',
    'Art Therapy',
    'Early Intervention',
    'Social Skills',
    'Parent Training',
    'Assistive Technology',
  ];
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Your Specialties', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Select all that apply. You can change this later.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _allSpecialties.map((specialty) {
              final isSelected = _selected.contains(specialty);
              return FilterChip(
                label: Text(specialty),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(specialty);
                    } else {
                      _selected.remove(specialty);
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