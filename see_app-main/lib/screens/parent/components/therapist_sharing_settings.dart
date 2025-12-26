import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class TherapistSharingSettings extends StatefulWidget {
  final String therapistId;
  final String childId;
  
  const TherapistSharingSettings({
    Key? key,
    required this.therapistId,
    required this.childId,
  }) : super(key: key);
  
  @override
  State<TherapistSharingSettings> createState() => _TherapistSharingSettingsState();
}

class _TherapistSharingSettingsState extends State<TherapistSharingSettings> {
  late DatabaseService _databaseService;
  late AuthService _authService;
  
  AppUser? _therapist;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Sharing permission settings
  bool _shareEmotionData = true;
  bool _shareMissions = true;
  bool _shareDiagnosticResults = false;
  bool _shareReports = true;
  bool _allowRecommendations = true;
  
  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load therapist data
      _therapist = await _databaseService.getUser(widget.therapistId);
      
      // In a real app, load existing sharing settings from Firebase
      // For now, use default values
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading sharing settings: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sharing settings: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _saveSettings() async {
    if (_therapist == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // In a real app, save settings to Firebase
      // Create sharing settings object
      final sharingSettings = {
        'therapistId': widget.therapistId,
        'childId': widget.childId,
        'parentId': _authService.currentUser?.id,
        'shareEmotionData': _shareEmotionData,
        'shareMissions': _shareMissions,
        'shareDiagnosticResults': _shareDiagnosticResults,
        'shareReports': _shareReports,
        'allowRecommendations': _allowRecommendations,
        'updatedAt': DateTime.now(),
      };
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing settings saved')),
        );
      }
    } catch (e) {
      debugPrint('Error saving sharing settings: $e');
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sharing Settings'),
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
                      _buildSharingOptions(),
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
  
  Widget _buildSharingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What information do you want to share with this therapist?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Sharing options
        _buildSwitchTile(
          title: 'Emotion Data',
          subtitle: 'Share your child\'s emotions, triggers, and trends',
          value: _shareEmotionData,
          onChanged: (value) => setState(() => _shareEmotionData = value),
        ),
        
        _buildSwitchTile(
          title: 'Missions & Activities',
          subtitle: 'Share completed missions and activity progress',
          value: _shareMissions,
          onChanged: (value) => setState(() => _shareMissions = value),
        ),
        
        _buildSwitchTile(
          title: 'Diagnostic Results',
          subtitle: 'Share results from diagnostic assessments',
          value: _shareDiagnosticResults,
          onChanged: (value) => setState(() => _shareDiagnosticResults = value),
        ),
        
        _buildSwitchTile(
          title: 'Weekly Reports',
          subtitle: 'Share automatically generated progress reports',
          value: _shareReports,
          onChanged: (value) => setState(() => _shareReports = value),
        ),
        
        _buildSwitchTile(
          title: 'Allow Recommendations',
          subtitle: 'Let therapist suggest activities and strategies',
          value: _allowRecommendations,
          onChanged: (value) => setState(() => _allowRecommendations = value),
        ),
        
        const SizedBox(height: 24),
        
        // Data sharing policy
        Card(
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
                      Icons.privacy_tip,
                      color: theme_utils.SeeAppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Data Sharing Policy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You can change these settings at any time. Your child\'s data is always encrypted and securely stored. '
                  'Only therapists with whom you explicitly share data can access it.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Show privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy coming soon')),
                    );
                  },
                  child: const Text('View Privacy Policy'),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Revoke access button
        OutlinedButton.icon(
          onPressed: _showRevokeAccessDialog,
          icon: const Icon(Icons.block),
          label: const Text('Revoke All Access'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? theme_utils.SeeAppTheme.primaryColor : Colors.grey.shade300,
          width: value ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: theme_utils.SeeAppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }
  
  void _showRevokeAccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Are you sure you want to revoke all access for ${_therapist?.name}? '
          'This will prevent them from seeing any of your child\'s data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _revokeAccess();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _revokeAccess() async {
    setState(() => _isSaving = true);
    
    try {
      // In a real app, revoke access in Firebase
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Update local state
      setState(() {
        _shareEmotionData = false;
        _shareMissions = false;
        _shareDiagnosticResults = false;
        _shareReports = false;
        _allowRecommendations = false;
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access revoked for ${_therapist?.name}')),
        );
      }
    } catch (e) {
      debugPrint('Error revoking access: $e');
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error revoking access: ${e.toString()}')),
        );
      }
    }
  }
} 