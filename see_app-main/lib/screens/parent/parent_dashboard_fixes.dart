// This file contains fixes for the parent dashboard to properly handle child registration
// Copy these methods into the _ParentDashboardState class in parent_dashboard.dart

// Replace the existing _loadRealData method with this improved version
Future<void> _loadRealData() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
    });
  }
  
  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    // Get current user
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      debugPrint('No user logged in');
      return;
    }
    
    // Get user's children
    final children = await databaseService.getChildrenForUser(currentUser.id);
    debugPrint('Loaded ${children.length} children for user ${currentUser.id}');
    
    // If no children found, check if we need to show the message
    if (children.isEmpty && !widget.suppressNoChildrenMessage && mounted) {
      // Only show the message if not coming from onboarding
      _showNoChildrenMessage();
    }
    
    if (mounted) {
      setState(() {
        _children = children;
        _selectedChild = children.isNotEmpty ? children.first : null;
        _isLoading = false;
      });
    }
    
    // If we have a selected child, load their emotion data
    if (_selectedChild != null) {
      _loadEmotionData();
    }
  } catch (e) {
    debugPrint('Error loading real data: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Add this new method to show a message when no children are found
void _showNoChildrenMessage() {
  // Wait a bit to ensure the UI is built
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Child Profiles Found'),
          content: const Text(
            'It looks like you haven\'t added any child profiles yet. '
            'Would you like to add a child profile now?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addNewChild();
              },
              child: const Text('Add Child'),
            ),
          ],
        ),
      );
    }
  });
}
