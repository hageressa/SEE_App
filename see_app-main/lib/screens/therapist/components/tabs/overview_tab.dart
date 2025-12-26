import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class OverviewTab extends StatelessWidget {
  final List<Child> patients;
  final List<Map<String, dynamic>> upcomingSessions;
  final List<dynamic> recentAlerts;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(Child) onViewPatientDetails;
  final Function(Map<String, dynamic>) onPrepareForSession;
  final Function(dynamic) onViewAlertDetails;
  final VoidCallback onCreateRecommendation;
  final VoidCallback onCreateMission;

  const OverviewTab({
    Key? key,
    required this.patients,
    required this.upcomingSessions,
    required this.recentAlerts,
    required this.isLoading,
    required this.onRefresh,
    required this.onViewPatientDetails,
    required this.onPrepareForSession,
    required this.onViewAlertDetails,
    required this.onCreateRecommendation,
    required this.onCreateMission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 20),
            
            _buildSectionTitle('Today\'s Sessions'),
            const SizedBox(height: 12),
            _buildSessionsList(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Recent Alerts'),
            const SizedBox(height: 12),
            _buildAlertsList(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 24),
            
            _buildPatientOverviewSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTodayDate(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatBubble(
                            '${upcomingSessions.length}',
                            'Sessions Today',
                            Icons.calendar_today,
                          ),
                          const SizedBox(width: 12),
                          _buildStatBubble(
                            '${recentAlerts.length}',
                            'New Alerts',
                            Icons.notifications_active,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/therapist_welcome.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology_alt,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatBubble(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildSessionsList() {
    if (upcomingSessions.isEmpty) {
      return _buildEmptyState(
        'No sessions scheduled for today',
        'Your upcoming sessions will appear here.',
        Icons.calendar_today,
      );
    }

    return Column(
      children: upcomingSessions.map((session) {
        final timeString = session['time'] as String?;
        final DateTime sessionTime = timeString != null 
            ? DateTime.parse(timeString) 
            : DateTime.now();
        final time = DateFormat('h:mm a').format(sessionTime);
        
        final childId = session['patientId'] as String?;
        final child = patients.firstWhere(
          (c) => c.id == childId,
          orElse: () => Child(
            id: '',
            name: 'Unknown',
            age: 0,
            gender: 'Unknown',
            parentId: '',
            concerns: [],
          ),
        );

        // Handle duration which can be either String or int
        String durationText;
        final durationValue = session['duration'];
        if (durationValue is String) {
          durationText = durationValue;
        } else if (durationValue is int) {
          durationText = '$durationValue min';
        } else {
          durationText = '50 min'; // Default
        }
        
        final notes = session['notes'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: child.avatar != null
                  ? NetworkImage(child.avatar!)
                  : null,
              child: child.avatar == null
                  ? Text(
                      child.name.isNotEmpty ? child.name[0] : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            title: Text(
              child.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$time · $durationText'),
                if (notes != null && notes.isNotEmpty)
                  Text(
                    notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.assignment),
              onPressed: () => onPrepareForSession(session),
              tooltip: 'Prepare for session',
            ),
            onTap: () => onViewPatientDetails(child),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
      }).toList(),
    );
  }

  Widget _buildAlertsList() {
    if (recentAlerts.isEmpty) {
      return _buildEmptyState(
        'No recent alerts',
        'Distress alerts from your patients will appear here.',
        Icons.notifications_none,
      );
    }

    return Column(
      children: recentAlerts.map((alert) {
        // Handle both DistressAlert object and Map<String, dynamic>
        final isMapType = alert is Map<String, dynamic>;
        
        final timestampStr = isMapType ? alert['timestamp'] as String? : null;
        final timestamp = isMapType && timestampStr != null 
            ? DateTime.parse(timestampStr) 
            : isMapType ? DateTime.now() : (alert.timestamp as DateTime);
        final timeAgo = _getTimeAgo(timestamp);
        
        final severity = isMapType 
            ? (alert['severity'] as String? ?? 'medium')
            : alert.severity.toString().split('.').last;
        
        final childId = isMapType 
            ? (alert['patientId'] as String?)
            : alert.childId;
        final child = patients.firstWhere(
          (c) => c.id == childId,
          orElse: () => Child(
            id: '',
            name: 'Unknown',
            age: 0,
            gender: 'Unknown',
            parentId: '',
            concerns: [],
          ),
        );

        final message = isMapType 
            ? (alert['message'] as String? ?? 'Distress alert')
            : 'Distress alert for ${alert.triggerEmotion.toString().split('.').last}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: child.avatar != null
                      ? NetworkImage(child.avatar!)
                      : null,
                  child: child.avatar == null
                      ? Text(
                          child.name.isNotEmpty ? child.name[0] : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    width: 16,
                    height: 16,
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      color: _getSeverityColor(severity),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onViewAlertDetails(alert),
            ),
            onTap: () => onViewAlertDetails(alert),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
      }).toList(),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Create Recommendation',
        'icon': Icons.lightbulb,
        'color': Colors.orange,
        'onTap': onCreateRecommendation,
      },
      {
        'title': 'Create Mission',
        'icon': Icons.assignment,
        'color': Colors.green,
        'onTap': onCreateMission,
      },
      {
        'title': 'View Schedule',
        'icon': Icons.calendar_month,
        'color': Colors.blue,
        'onTap': () {},
      },
      {
        'title': 'Resources',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'onTap': () {},
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((action) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: action['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: (action['color'] as Color).withOpacity(0.1),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    action['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
      }).toList(),
    );
  }

  Widget _buildPatientOverviewSection() {
    if (patients.isEmpty) {
      return _buildEmptyState(
        'No patients yet',
        'Add your first patient to get started.',
        Icons.person_off,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Patient Overview'),
        const SizedBox(height: 12),
        _buildPatientStats(),
        const SizedBox(height: 16),
        _buildRecentPatientsRow(),
      ],
    );
  }

  Widget _buildPatientStats() {
    return Row(
      children: [
        _buildStatCard(
          'Total Patients',
          '${patients.length}',
          Icons.people,
          theme_utils.SeeAppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Active Sessions',
          '${upcomingSessions.length}',
          Icons.video_call,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPatientsRow() {
    // Show only the most recent 4 patients
    final recentPatients = patients.length > 4 ? patients.sublist(0, 4) : patients;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: recentPatients.map((patient) {
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: patient.avatar != null
                      ? NetworkImage(patient.avatar!)
                      : null,
                  child: patient.avatar == null
                      ? Text(
                          patient.name[0],
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  patient.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: Icon(icon, color: Colors.grey[600], size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, y').format(now);
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.orange; // Default to medium if null or unknown
    }
  }
}
