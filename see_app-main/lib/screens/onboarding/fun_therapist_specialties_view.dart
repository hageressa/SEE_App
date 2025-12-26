import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FunTherapistSpecialtiesView extends StatefulWidget {
  final void Function(List<String> selectedSpecialties) onNext;
  const FunTherapistSpecialtiesView({Key? key, required this.onNext}) : super(key: key);

  @override
  State<FunTherapistSpecialtiesView> createState() => _FunTherapistSpecialtiesViewState();
}

class _FunTherapistSpecialtiesViewState extends State<FunTherapistSpecialtiesView> {
  final List<_SpecialtyCardData> _specialties = [
    _SpecialtyCardData('Speech Therapy', 'assets/lottie/speech_bubble.json'),
    _SpecialtyCardData('Behavioral Therapy', 'assets/lottie/attention.json'),
    _SpecialtyCardData('Cognitive Development', 'assets/lottie/learning.json'),
    _SpecialtyCardData('Emotional Support', 'assets/lottie/emotion.json'),
    _SpecialtyCardData('Social Skills', 'assets/lottie/social.json'),
    _SpecialtyCardData('Special Education', 'assets/lottie/other.json'),
  ];
  final Set<String> _selected = {};

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
                "What are your specialties?",
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
                "Select all areas you specialize in",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: _specialties.map((s) => _buildSpecialtyCard(s)).toList(),
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
                onPressed: _selected.isEmpty ? null : () => widget.onNext(_selected.toList()),
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

  Widget _buildSpecialtyCard(_SpecialtyCardData specialty) {
    final isSelected = _selected.contains(specialty.label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selected.remove(specialty.label);
          } else {
            _selected.add(specialty.label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[200] : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.indigo.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
          ],
          border: Border.all(
            color: isSelected ? Colors.indigo[700]! : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60,
              child: Lottie.asset(specialty.lottiePath, repeat: true),
            ),
            const SizedBox(height: 8),
            Text(
              specialty.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.indigo[900] : Colors.black87,
                fontFamily: 'ComicNeue',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyCardData {
  final String label;
  final String lottiePath;
  _SpecialtyCardData(this.label, this.lottiePath);
}
