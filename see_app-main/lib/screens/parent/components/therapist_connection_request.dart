import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class TherapistConnectionRequest extends StatefulWidget {
  final String therapistId;
  final List<Child> children;
  final Function(String, String) onConnectionRequestSent;
  
  const TherapistConnectionRequest({
    Key? key,
    required this.therapistId,
    required this.children,
    required this.onConnectionRequestSent,
  }) : super(key: key);
  
  @override
  State<TherapistConnectionRequest> createState() => _TherapistConnectionRequestState();
}

class _TherapistConnectionRequestState extends State<TherapistConnectionRequest> {
  late DatabaseService _databaseService;
  late AuthService _authService;
  
  AppUser? _therapist;
  Child? _selectedChild;
  bool _isLoading = true;
  bool _isSending = false;
  String _message = '';
  
  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadTherapistData();
    
    // Pre-select child if only one is available
    if (widget.children.length == 1) {
      _selectedChild = widget.children.first;
    }
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
  
  Future<void> _sendConnectionRequest() async {
    if (_therapist == null || _selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child for this connection')),
      );
      return;
    }
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send a connection request')),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      // In a real app, save connection request to Firebase
      // Create connection request object
      final connectionRequest = {
        'therapistId': widget.therapistId,
        'parentId': currentUser.id,
        'childId': _selectedChild!.id,
        'message': _message,
        'status': 'pending',
        'createdAt': DateTime.now(),
      };
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _isSending = false);
      
      // Notify parent about successful request
      widget.onConnectionRequestSent(_therapist!.id, _selectedChild!.id);
      
      // Close the dialog
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error sending connection request: $e');
      setState(() => _isSending = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : _therapist == null
                  ? const Center(
                      child: Text('Therapist not found'),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Connect with Therapist',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        _buildTherapistInfo(),
                        const SizedBox(height: 24),
                        _buildChildSelector(),
                        const SizedBox(height: 24),
                        _buildMessageInput(),
                        const SizedBox(height: 24),
                        _buildConnectionInfo(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
        ),
      ),
    );
  }
  
  Widget _buildTherapistInfo() {
    return Row(
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
    );
  }
  
  Widget _buildChildSelector() {
    if (widget.children.isEmpty) {
      return const Text('No children available to connect');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a child to connect with this therapist:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: widget.children.map((child) {
              final isSelected = _selectedChild?.id == child.id;
              
              return RadioListTile<Child>(
                title: Text(
                  child.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('Age: ${child.age}'),
                value: child,
                groupValue: _selectedChild,
                activeColor: theme_utils.SeeAppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _selectedChild = value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Include a message (optional):',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Briefly explain why you\'d like to connect',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          maxLength: 250,
          onChanged: (value) => setState(() => _message = value),
        ),
      ],
    );
  }
  
  Widget _buildConnectionInfo() {
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme_utils.SeeAppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'What happens next?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Your request will be sent to the therapist',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '2. Once they accept, you can message each other',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '3. You\'ll need to set data sharing permissions separately',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSending ? null : _sendConnectionRequest,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }
} 