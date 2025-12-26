import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/pattern_detection_dashboard.dart';
import 'package:provider/provider.dart';

class AnalyticsTab extends StatefulWidget {
  final List<Child> patients;
  final bool isLoading;
  final VoidCallback onRefresh;
  
  const AnalyticsTab({
    Key? key,
    required this.patients,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  Child? _selectedPatient;
  bool _showingPatternDetection = false;

  @override
  void initState() {
    super.initState();
    if (widget.patients.isNotEmpty) {
      _selectedPatient = widget.patients.first;
    }
  }

  @override
  void didUpdateWidget(AnalyticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patients != oldWidget.patients && widget.patients.isNotEmpty) {
      if (_selectedPatient == null || 
          !widget.patients.any((p) => p.id == _selectedPatient!.id)) {
        setState(() {
          _selectedPatient = widget.patients.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.patients.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (!_showingPatternDetection) ...[  
          _buildPatientSelector(),
          Expanded(child: _buildAnalyticsOverview()),
        ] else if (_selectedPatient != null) ...[  
          _buildPatternDetectionHeader(),
          Expanded(
            child: PatternDetectionDashboard(
              patient: _selectedPatient!,
              databaseService: Provider.of<DatabaseService>(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPatientSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedPatient?.id,
                hint: const Text('Select a patient'),
                items: widget.patients.map((patient) {
                  return DropdownMenuItem<String>(
                    value: patient.id,
                    child: Text(
                      '${patient.name} (${patient.age} years)',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPatient = widget.patients.firstWhere(
                        (p) => p.id == value,
                      );
                      _showingPatternDetection = false;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternDetectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showingPatternDetection = false;
              });
            },
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundImage: _selectedPatient?.avatar != null
                ? NetworkImage(_selectedPatient!.avatar!)
                : null,
            child: _selectedPatient?.avatar == null
                ? Text(_selectedPatient?.name[0] ?? '?')
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            _selectedPatient?.name ?? 'Patient',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    if (_selectedPatient == null) {
      return const Center(
        child: Text('Select a patient to view analytics'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Analytics Tools'),
          const SizedBox(height: 16),
          _buildAnalyticsToolsGrid(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Recent Emotional Trends'),
          const SizedBox(height: 16),
          _buildEmotionTrendsPreview(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Progress Overview'),
          const SizedBox(height: 16),
          _buildProgressOverview(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    final patient = _selectedPatient!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme_utils.SeeAppTheme.primaryColor,
              theme_utils.SeeAppTheme.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white.withOpacity(0.9),
              backgroundImage: patient.avatar != null
                  ? NetworkImage(patient.avatar!)
                  : null,
              child: patient.avatar == null
                  ? Text(
                      patient.name[0],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme_utils.SeeAppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${patient.age} years old ${patient.gender != null ? "• ${patient.gender}" : ""}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showingPatternDetection = true;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Pattern Analysis'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme_utils.SeeAppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsToolsGrid() {
    final tools = [
      {
        'title': 'Pattern Detection',
        'description': 'Identify emotional patterns and triggers',
        'icon': Icons.analytics,
        'color': Colors.blue,
        'onTap': () {
          setState(() {
            _showingPatternDetection = true;
          });
        },
      },
      {
        'title': 'Emotion Timeline',
        'description': 'View emotional journey over time',
        'icon': Icons.timeline,
        'color': Colors.purple,
        'onTap': () {
          // TODO: Show emotion timeline
        },
      },
      {
        'title': 'Mission Progress',
        'description': 'Track therapeutic mission completion',
        'icon': Icons.assignment_turned_in,
        'color': Colors.green,
        'onTap': () {
          // TODO: Show mission progress
        },
      },
      {
        'title': 'Comparative Analysis',
        'description': 'Compare progress to baselines',
        'icon': Icons.compare_arrows,
        'color': Colors.orange,
        'onTap': () {
          // TODO: Show comparative analysis
        },
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tools.map((tool) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: tool['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (tool['color'] as Color).withOpacity(0.2),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: tool['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tool['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool['description'] as String,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
      }).toList(),
    );
  }

  Widget _buildEmotionTrendsPreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Image.asset(
                'assets/images/emotion_chart_preview.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Emotion data visualization will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Most Common Emotions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildEmotionChip('Joy', Colors.yellow.shade700),
                        const SizedBox(width: 8),
                        _buildEmotionChip('Anxiety', Colors.purple),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showingPatternDetection = true;
                    });
                  },
                  child: const Row(
                    children: [
                      Text('View Full Analysis'),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildEmotionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Widget _buildProgressOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Therapeutic Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text('Last 30 Days'),
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              'Emotional Awareness',
              0.75,
              theme_utils.SeeAppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Coping Skills',
              0.6,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Treatment Plan Goals',
              0.45,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: View progress report
                  },
                  child: const Text('View Progress Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 60,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Patients Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add patients to see their analytics and insights',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add),
            label: const Text('Add Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }
}
