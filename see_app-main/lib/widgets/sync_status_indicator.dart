import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart';

/// A widget that displays the current network connectivity and data synchronization status.
/// 
/// This widget shows different visual indicators based on whether the app is:
/// - Online: Shows a green indicator
/// - Offline: Shows a red indicator with a message that the app is working offline
/// - Syncing: Shows an animated indicator when data is being synchronized
class SyncStatusIndicator extends StatefulWidget {
  final DatabaseService databaseService;
  final String userId;
  
  const SyncStatusIndicator({
    Key? key, 
    required this.databaseService,
    required this.userId,
  }) : super(key: key);

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for syncing state
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    // Check initial online status
    _isOnline = widget.databaseService.isOnline;
    
    // Subscribe to online status changes
    widget.databaseService.onlineStatusStream.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
        if (isOnline) {
          _isSyncing = true;
          _fetchLastSyncTime();
          
          // Simulate syncing finished after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isSyncing = false;
              });
            }
          });
        }
      });
    });
    
    // Get initial last sync time
    _fetchLastSyncTime();
  }
  
  Future<void> _fetchLastSyncTime() async {
    final lastSyncTime = await widget.databaseService.getLastSyncTime();
    if (mounted) {
      setState(() {
        _lastSyncTime = lastSyncTime;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  String _formatSyncTime() {
    if (_lastSyncTime == null) {
      return "Never synced";
    }
    
    return "Last sync: ${DateFormat('MMM d, h:mm a').format(_lastSyncTime!)}";
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return _buildSyncingIndicator();
    } else if (_isOnline) {
      return _buildOnlineIndicator();
    } else {
      return _buildOfflineIndicator();
    }
  }
  
  Widget _buildOnlineIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Online",
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatSyncTime(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOfflineIndicator() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You're working offline. Changes will be synchronized when you reconnect to the internet.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: SeeAppTheme.secondaryColor,
            duration: Duration(seconds: 5),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Offline",
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatSyncTime(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyncingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: _animationController.drive(
              ColorTween(begin: Colors.blue, end: SeeAppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Syncing...",
          style: TextStyle(
            color: SeeAppTheme.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}