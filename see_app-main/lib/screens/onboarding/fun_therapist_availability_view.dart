import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FunTherapistAvailabilityView extends StatefulWidget {
  final void Function(Map<String, List<String>> availability) onNext;
  const FunTherapistAvailabilityView({Key? key, required this.onNext}) : super(key: key);

  @override
  State<FunTherapistAvailabilityView> createState() => _FunTherapistAvailabilityViewState();
}

class _FunTherapistAvailabilityViewState extends State<FunTherapistAvailabilityView> {
  final Map<String, bool> _daysSelected = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  
  final Map<String, List<String>> _dayTimeSlots = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };
  
  final List<String> _timeSlots = [
    'Morning (8am-12pm)',
    'Afternoon (12pm-4pm)',
    'Evening (4pm-8pm)',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF303F9F), Color(0xFF1A237E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                "When are you available?",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Tap days and select time slots",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                child: Lottie.asset('assets/lottie/other.json', repeat: true),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: _daysSelected.keys.map((day) => _buildDaySelector(day)).toList(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
                onPressed: _isAnyDaySelected() ? () {
                  // Filter to only include days with slots selected
                  final Map<String, List<String>> filteredAvailability = {};
                  _dayTimeSlots.forEach((day, slots) {
                    if (slots.isNotEmpty) {
                      filteredAvailability[day] = slots;
                    }
                  });
                  widget.onNext(filteredAvailability);
                } : null,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'ComicNeue',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _isAnyDaySelected() {
    for (var slots in _dayTimeSlots.values) {
      if (slots.isNotEmpty) return true;
    }
    return false;
  }

  Widget _buildDaySelector(String day) {
    final isSelected = _daysSelected[day] ?? false;
    
    return Column(
      children: [
        // Day toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _daysSelected[day] = !isSelected;
              // Clear time slots if deselecting day
              if (!_daysSelected[day]!) {
                _dayTimeSlots[day] = [];
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo[300] : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white70,
                    fontFamily: 'ComicNeue',
                  ),
                ),
                Icon(
                  isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ],
            ),
          ),
        ),
        
        // Time slots (only show if day is selected)
        if (isSelected)
          ..._timeSlots.map((timeSlot) {
            final isTimeSelected = _dayTimeSlots[day]!.contains(timeSlot);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isTimeSelected) {
                    _dayTimeSlots[day]!.remove(timeSlot);
                  } else {
                    _dayTimeSlots[day]!.add(timeSlot);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(left: 30, right: 10, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isTimeSelected ? Colors.indigo[200] : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTimeSelected ? Colors.indigo[400]! : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeSlot,
                      style: TextStyle(
                        fontSize: 16,
                        color: isTimeSelected ? Colors.indigo[900] : Colors.black87,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                    if (isTimeSelected)
                      Icon(Icons.check_circle, color: Colors.indigo[800], size: 24),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
