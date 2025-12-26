import 'package:flutter/material.dart';
import 'package:see_app/models/child.dart';

class ClientProgressTab extends StatelessWidget {
  final Child client;

  const ClientProgressTab({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Progress for ${client.name}'),
    );
  }
} 