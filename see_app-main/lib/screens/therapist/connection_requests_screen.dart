import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/connection_request.dart';
import 'package:see_app/services/connection_service.dart';
import 'package:see_app/services/auth_service.dart';

class ConnectionRequestsScreen extends StatelessWidget {
  const ConnectionRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final therapistId = Provider.of<AuthService>(context, listen: false).currentUser!.id;
    final connectionService = Provider.of<ConnectionService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
      ),
      body: StreamBuilder<List<ConnectionRequest>>(
        stream: connectionService.getConnectionRequests(therapistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No new connection requests.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Request from ${request.parentName}'),
                  subtitle: Text('For child: ${request.childName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => connectionService.acceptConnectionRequest(request.id),
                        tooltip: 'Accept',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => connectionService.declineConnectionRequest(request.id),
                        tooltip: 'Decline',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 