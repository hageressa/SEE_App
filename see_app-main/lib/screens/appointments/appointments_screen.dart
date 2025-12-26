import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

// Simplified appointment model
class Appointment {
  final String id;
  final String parentId;
  final String therapistId;
  final DateTime dateTime;
  final String duration;
  final String type;
  String status; // pending, confirmed, completed, cancelled
  final String? notes;
  final DateTime createdAt;
  
  // These would be fetched separately
  AppUser? parent;
  AppUser? therapist;

  Appointment({
    required this.id,
    required this.parentId,
    required this.therapistId,
    required this.dateTime,
    required this.duration,
    required this.type,
    required this.status,
    this.notes,
    required this.createdAt,
    this.parent,
    this.therapist,
  });
  
  // Mock data generator
  static List<Appointment> getMockAppointments() {
    return [
      Appointment(
        id: '1',
        parentId: 'parent1',
        therapistId: 'therapist1',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        duration: '45 min',
        type: 'Video Consultation',
        status: 'confirmed',
        notes: 'First session to discuss child\'s progress',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Appointment(
        id: '2',
        parentId: 'parent1',
        therapistId: 'therapist2',
        dateTime: DateTime.now().add(const Duration(days: 5)),
        duration: '30 min',
        type: 'Phone Call',
        status: 'pending',
        notes: 'Quick follow-up on previous recommendations',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Appointment(
        id: '3',
        parentId: 'parent1',
        therapistId: 'therapist1',
        dateTime: DateTime.now().subtract(const Duration(days: 7)),
        duration: '60 min',
        type: 'In-Person',
        status: 'completed',
        notes: 'Initial assessment session',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Appointment(
        id: '4',
        parentId: 'parent1',
        therapistId: 'therapist3',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        duration: '45 min',
        type: 'Video Consultation',
        status: 'confirmed',
        notes: 'Discuss new strategies for emotional regulation',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);
  
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late DatabaseService _databaseService;
  late AuthService _authService;
  late TabController _tabController;
  
  List<Appointment> _appointments = [];
  Map<String, AppUser> _userCache = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, fetch appointments from Firebase
      // For now, use mock data
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      final appointments = Appointment.getMockAppointments();
      
      // Fetch user data for appointments
      await _loadUserData(appointments);
      
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _loadUserData(List<Appointment> appointments) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    
    final userIds = <String>{};
    
    for (final appointment in appointments) {
      if (currentUser.role == UserRole.parent) {
        userIds.add(appointment.therapistId);
      } else if (currentUser.role == UserRole.therapist) {
        userIds.add(appointment.parentId);
      }
    }
    
    for (final userId in userIds) {
      if (!_userCache.containsKey(userId)) {
        try {
          final user = await _databaseService.getUser(userId);
          if (user != null) {
            _userCache[userId] = user;
          }
        } catch (e) {
          debugPrint('Error loading user $userId: $e');
        }
      }
    }
    
    // Attach user objects to appointments
    for (final appointment in appointments) {
      if (currentUser.role == UserRole.parent) {
        appointment.therapist = _userCache[appointment.therapistId];
      } else if (currentUser.role == UserRole.therapist) {
        appointment.parent = _userCache[appointment.parentId];
      }
    }
  }
  
  List<Appointment> _getFilteredAppointments(String filter) {
    final now = DateTime.now();
    
    switch (filter) {
      case 'upcoming':
        return _appointments
            .where((a) => a.dateTime.isAfter(now) && 
                         (a.status == 'confirmed' || a.status == 'pending'))
            .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case 'pending':
        return _appointments
            .where((a) => a.status == 'pending')
            .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case 'past':
        return _appointments
            .where((a) => a.dateTime.isBefore(now) || a.status == 'completed' || a.status == 'cancelled')
            .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Most recent first
      default:
        return _appointments;
    }
  }
  
  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildAppointmentDetailsSheet(appointment),
    );
  }
  
  Widget _buildAppointmentDetailsSheet(Appointment appointment) {
    final isParent = _authService.currentUser?.role == UserRole.parent;
    final otherUser = isParent ? appointment.therapist : appointment.parent;
    
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Appointment Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          if (otherUser != null) ...[
            Text(
              isParent ? 'Therapist' : 'Parent',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                child: Text(
                  otherUser.name.isNotEmpty
                      ? otherUser.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(otherUser.name),
              subtitle: Text(otherUser.roleName),
            ),
            const Divider(),
          ],
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(appointment.dateTime),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeFormat.format(appointment.dateTime),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.duration,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.type,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          
          const SizedBox(height: 24),
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          _buildStatusChip(appointment.status),
          
          const SizedBox(height: 32),
          Row(
            children: [
              if (appointment.status == 'confirmed' && appointment.type == 'Video Consultation') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _initiateVideoCall(),
                    icon: const Icon(Icons.video_call),
                    label: const Text('Join Video Call'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (appointment.status == 'pending' && _authService.currentUser?.role == UserRole.therapist) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateAppointmentStatus(appointment, 'confirmed'),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (appointment.status != 'cancelled' && appointment.status != 'completed') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancellationDialog(appointment),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  void _initiateVideoCall() {
    // Placeholder for video call functionality
    Navigator.pop(context); // Close the bottom sheet
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Consultation'),
        content: const Text(
          'Video consultation feature will be available in a future update. This placeholder is for UI demonstration purposes.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateAppointmentStatus(Appointment appointment, String newStatus) async {
    Navigator.pop(context); // Close the bottom sheet
    
    try {
      setState(() => _isLoading = true);
      
      // In a real app, update the status in Firebase
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Update local data
      setState(() {
        for (final appt in _appointments) {
          if (appt.id == appointment.id) {
            appt.status = newStatus;
            break;
          }
        }
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment ${newStatus.toLowerCase()}')),
        );
      }
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating appointment: ${e.toString()}')),
        );
      }
    }
  }
  
  void _showCancellationDialog(Appointment appointment) {
    Navigator.pop(context); // Close the bottom sheet
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointment, 'cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'completed':
        color = theme_utils.SeeAppTheme.primaryColor;
        icon = Icons.task_alt;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Chip(
      label: Text(
        status.characters.first.toUpperCase() + status.substring(1),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      avatar: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList('upcoming'),
                _buildAppointmentsList('pending'),
                _buildAppointmentsList('past'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentUser = _authService.currentUser;
          if (currentUser?.role == UserRole.parent) {
            // For parents, navigate to a therapist directory first
            Navigator.pushNamed(context, '/therapists');
          } else {
            // For therapists, show message that parents initiate appointments
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Parents initiate appointment requests'),
              ),
            );
          }
        },
        tooltip: 'Book Appointment',
        backgroundColor: theme_utils.SeeAppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildAppointmentsList(String filter) {
    final appointments = _getFilteredAppointments(filter);
    
    if (appointments.isEmpty) {
      return _buildEmptyState(filter);
    }
    
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }
  
  Widget _buildEmptyState(String filter) {
    String message;
    
    switch (filter) {
      case 'upcoming':
        message = 'No upcoming appointments scheduled';
        break;
      case 'pending':
        message = 'No pending appointment requests';
        break;
      case 'past':
        message = 'No past appointments';
        break;
      default:
        message = 'No appointments found';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentCard(Appointment appointment) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    
    final isParent = _authService.currentUser?.role == UserRole.parent;
    final otherUser = isParent ? appointment.therapist : appointment.parent;
    
    final now = DateTime.now();
    final isUpcoming = appointment.dateTime.isAfter(now) && 
                      (appointment.status == 'confirmed' || appointment.status == 'pending');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: appointment.status == 'confirmed' && isUpcoming
              ? Colors.green.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAppointmentTypeIcon(appointment.type),
                    color: theme_utils.SeeAppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appointment.type,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(appointment.status),
                ],
              ),
              const Divider(height: 24),
              if (otherUser != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                      child: Text(
                        otherUser.name.isNotEmpty
                            ? otherUser.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          isParent ? 'Therapist' : 'Parent',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme_utils.SeeAppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(appointment.dateTime),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme_utils.SeeAppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(appointment.dateTime),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: theme_utils.SeeAppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.duration,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (appointment.status == 'confirmed' && isUpcoming) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (appointment.type == 'Video Consultation')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _initiateVideoCall,
                          icon: const Icon(Icons.video_call),
                          label: const Text('Join Video Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getAppointmentTypeIcon(String type) {
    switch (type) {
      case 'Video Consultation':
        return Icons.video_call;
      case 'In-Person':
        return Icons.people;
      case 'Phone Call':
        return Icons.phone;
      default:
        return Icons.event;
    }
  }
} 