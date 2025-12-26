import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;
import 'package:see_app/widgets/client_management_dashboard.dart';
import 'package:see_app/screens/therapist/client_profile_screen.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/services/auth_service.dart';

class ClientsTab extends StatefulWidget {
  final List<Child> patients;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(Child) onViewPatientDetails;
  final Function(List<Child>) onPatientsUpdated;
  final VoidCallback onAddClient;
  final String therapistId;

  const ClientsTab({
    Key? key,
    required this.patients,
    required this.isLoading,
    required this.onRefresh,
    required this.onViewPatientDetails,
    required this.onPatientsUpdated,
    required this.onAddClient,
    required this.therapistId,
  }) : super(key: key);

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  List<Child> _patients = [];
  bool _isLoadingAdditional = false;
  final TextEditingController _searchController = TextEditingController();
  late DatabaseService _databaseService;
  
  @override
  void initState() {
    super.initState();
    _patients = List.from(widget.patients);
    // Load any patients that may have been assigned but not in the initial list
    _loadAssignedPatients();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
  }
  
  @override
  void didUpdateWidget(ClientsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patients != widget.patients) {
      setState(() {
        _patients = List.from(widget.patients);
      });
    }
  }
  
  Future<void> _loadAssignedPatients() async {
    if (widget.therapistId.isEmpty) return;
    
    setState(() {
      _isLoadingAdditional = true;
    });
    
    try {
      // This will fetch children with this therapist ID in additionalInfo
      final assignedChildren = await Provider.of<DatabaseService>(context, listen: false)
          .getChildrenByTherapistId(widget.therapistId);
      
      if (assignedChildren.isNotEmpty) {
        // Add any children not already in the list
        final newPatients = [..._patients];
        bool changed = false;
        
        for (final child in assignedChildren) {
          if (!newPatients.any((p) => p.id == child.id)) {
            newPatients.add(child);
            changed = true;
          }
        }
        
        if (changed) {
          setState(() {
            _patients = newPatients;
          });
          // Notify parent widget
          widget.onPatientsUpdated(newPatients);
        }
      }
    } catch (e) {
      print('Error loading assigned patients: $e');
    } finally {
      setState(() {
        _isLoadingAdditional = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patients.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildClientSearch(context),
          if (_isLoadingAdditional)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: Text("Loading additional assigned patients...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          Expanded(
            child: ClientManagementDashboard(
              databaseService: Provider.of<DatabaseService>(context),
              patients: _patients,
              onPatientsUpdated: widget.onPatientsUpdated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme_utils.SeeAppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: widget.onAddClient,
              icon: const Icon(Icons.person_add, color: Colors.white),
              tooltip: 'Add Client',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.psychology_alt_rounded,
              size: 60,
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome, Therapist!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your client list is currently empty. You can add clients once they register with the system.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onAddClient,
            icon: const Icon(Icons.psychology),
            label: const Text('Set Up Client Management'),
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

  void _createTestClient(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final AppUser? therapist = authService.currentUser;

    if (therapist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Therapist not logged in.')),
      );
      return;
    }

    // Create a dummy child for testing
    final newChild = Child(
      id: 'test_child_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Child',
      age: 8,
      gender: 'Other',
      parentId: 'test_parent_id',
      concerns: ['Anxiety', 'Social Skills'],
      avatar: 'assets/images/avatars/other_avatar.png',
      therapistId: therapist.id,
    );

    try {
      await _databaseService.addChild(newChild);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test client created successfully.')),
      );

      // Refresh the client list
      _loadAssignedPatients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test client: $e')),
      );
    }
  }
}
