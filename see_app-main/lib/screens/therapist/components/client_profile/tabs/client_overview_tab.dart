import 'package:flutter/material.dart';
import 'package:see_app/models/child.dart';

class ClientOverviewTab extends StatelessWidget {
  final Child client;

  const ClientOverviewTab({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Overview for ${client.name}'),
    );
  }
} 