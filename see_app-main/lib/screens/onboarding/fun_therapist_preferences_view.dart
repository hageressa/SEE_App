import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FunTherapistPreferencesView extends StatefulWidget {
  final void Function(Map<String, dynamic> preferences) onNext;
  const FunTherapistPreferencesView({Key? key, required this.onNext}) : super(key: key);

  @override
  State<FunTherapistPreferencesView> createState() => _FunTherapistPreferencesViewState();
}

class _FunTherapistPreferencesViewState extends State<FunTherapistPreferencesView> {
  String _preferredAgeGroup = 'All Ages';
  final List<String> _ageGroups = [
    'Toddlers (2-4)',
    'Children (5-12)',
    'Teenagers (13-18)',
    'All Ages',
  ];
  
  String _approachStyle = 'Balanced';
  final List<String> _approaches = [
    'Play-based',
    'Structured',
    'Balanced',
    'Family-centered',
  ];
  
  int _experienceYears = 3; // Default to 3 years
  String _bio = '';

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
              const SizedBox(height: 20),
              Text(
                "Tell us about your practice",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                height: 80,
                child: Lottie.asset('assets/lottie/emotion.json', repeat: true),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    // Preferred age group
                    _buildSectionTitle('Preferred Age Group'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ageGroups.map((age) => _buildChip(
                        age,
                        isSelected: _preferredAgeGroup == age,
                        onTap: () => setState(() => _preferredAgeGroup = age),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Approach style
                    _buildSectionTitle('Treatment Approach'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _approaches.map((approach) => _buildChip(
                        approach,
                        isSelected: _approachStyle == approach,
                        onTap: () => setState(() => _approachStyle = approach),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Experience years
                    _buildSectionTitle('Years of Experience'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_experienceYears years',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _experienceYears.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      label: '$_experienceYears years',
                      onChanged: (value) {
                        setState(() {
                          _experienceYears = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Bio
                    _buildSectionTitle('Brief Bio (Optional)'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Tell parents a bit about yourself...",
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16, fontFamily: 'ComicNeue'),
                        onChanged: (value) => setState(() => _bio = value),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
                onPressed: () {
                  widget.onNext({
                    'preferredAgeGroup': _preferredAgeGroup,
                    'approachStyle': _approachStyle,
                    'experienceYears': _experienceYears,
                    'bio': _bio.trim(),
                  });
                },
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }

  Widget _buildChip(String label, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[300] : Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.indigo[900],
            fontFamily: 'ComicNeue',
          ),
        ),
      ),
    );
  }
}
