import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/screens/therapist/components/client_profile/tabs/client_overview_tab.dart';
import 'package:see_app/screens/therapist/components/client_profile/tabs/client_progress_tab.dart';
import 'package:see_app/screens/therapist/components/client_profile/tabs/client_notes_tab.dart';

class ClientProfileScreen extends StatefulWidget {
  final String clientId;

  const ClientProfileScreen({
    Key? key,
    required this.clientId,
  }) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Child? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final client = await databaseService.getChild(widget.clientId);
      setState(() {
        _client = client;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading client data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_client == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Client Profile'),
        ),
        body: const Center(
          child: Text('Client not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_client!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Progress'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClientOverviewTab(client: _client!),
          ClientProgressTab(client: _client!),
          ClientNotesTab(client: _client!),
        ],
      ),
    );
  }
} 