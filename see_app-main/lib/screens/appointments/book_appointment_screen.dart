import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class BookAppointmentScreen extends StatefulWidget {
  final String therapistId;
  
  const BookAppointmentScreen({
    Key? key,
    required this.therapistId,
  }) : super(key: key);
  
  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late DatabaseService _databaseService;
  late AuthService _authService;
  
  AppUser? _therapist;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09:00 AM';
  String _selectedDuration = '45 min';
  String _selectedType = 'Video Consultation';
  String _notes = '';
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  final List<String> _availableTimes = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];
  
  final List<String> _sessionDurations = [
    '30 min',
    '45 min',
    '60 min',
  ];
  
  final List<String> _sessionTypes = [
    'Video Consultation',
    'In-Person',
    'Phone Call',
  ];
  
  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadTherapistData();
  }
  
  Future<void> _loadTherapistData() async {
    setState(() => _isLoading = true);
    
    try {
      _therapist = await _databaseService.getUser(widget.therapistId);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading therapist data: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading therapist data: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _submitAppointment() async {
    if (_therapist == null) return;
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book an appointment')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      // Parse the selected time
      final timeFormat = DateFormat('hh:mm a');
      final selectedTimeObj = timeFormat.parse(_selectedTime);
      
      // Create a datetime with the selected date and time
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        selectedTimeObj.hour,
        selectedTimeObj.minute,
      );
      
      // Create appointment data
      final appointmentData = {
        'parentId': currentUser.id,
        'therapistId': _therapist!.id,
        'dateTime': appointmentDateTime,
        'duration': _selectedDuration,
        'type': _selectedType,
        'notes': _notes,
        'status': 'pending',
        'createdAt': DateTime.now(),
      };
      
      // In a real app, this would save to Firebase
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // For now, show success dialog
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: ${e.toString()}')),
        );
      }
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Request Sent'),
        content: const Text(
          'Your appointment request has been sent to the therapist. '
          'You will be notified when they confirm the appointment.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _therapist == null
              ? Center(
                  child: Text(
                    'Therapist not found',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTherapistHeader(),
                      const SizedBox(height: 24),
                      _buildAppointmentForm(),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildTherapistHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
              child: Text(
                _therapist!.name.isNotEmpty
                    ? _therapist!.name.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _therapist!.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _therapist!.additionalInfo?['specialty'] ?? 'Therapist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _therapist!.additionalInfo?['rating'] ?? '4.8',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_therapist!.additionalInfo?['reviews'] ?? '24'} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppointmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildDatePicker(),
        const SizedBox(height: 24),
        
        Text(
          'Select Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTimeSelector(),
        const SizedBox(height: 24),
        
        Text(
          'Session Duration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildDurationSelector(),
        const SizedBox(height: 24),
        
        Text(
          'Session Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSessionTypeSelector(),
        const SizedBox(height: 24),
        
        Text(
          'Notes (optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Add any details or questions for the therapist',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          onChanged: (value) => setState(() => _notes = value),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: theme_utils.SeeAppTheme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (selected != null) {
          setState(() => _selectedDate = selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableTimes.length,
        itemBuilder: (context, index) {
          final time = _availableTimes[index];
          final isSelected = _selectedTime == time;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(time),
              selected: isSelected,
              selectedColor: theme_utils.SeeAppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDurationSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sessionDurations.length,
        itemBuilder: (context, index) {
          final duration = _sessionDurations[index];
          final isSelected = _selectedDuration == duration;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(duration),
              selected: isSelected,
              selectedColor: theme_utils.SeeAppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedDuration = duration);
                }
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSessionTypeSelector() {
    return Column(
      children: _sessionTypes.map((type) {
        final isSelected = _selectedType == type;
        
        return RadioListTile<String>(
          title: Text(type),
          value: type,
          groupValue: _selectedType,
          activeColor: theme_utils.SeeAppTheme.primaryColor,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
              
              // Show video consultation placeholder message
              if (value == 'Video Consultation') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video consultation functionality will be implemented in a future update'),
                  ),
                );
              }
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAppointment,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Request Appointment',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }
} 