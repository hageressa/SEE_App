import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/services/gemini_service.dart';
import 'package:see_app/services/ai_therapist_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  bool _isLoading = false;
  String _geminiResults = '';
  String _therapistResults = '';
  Map<String, dynamic> _databaseResults = {};
  bool _geminiTested = false;
  bool _therapistTested = false;
  bool _databaseTested = false;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    // Check if user is authenticated
    _isAuthenticated = FirebaseAuth.instance.currentUser != null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Diagnostics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diagnostic Tools',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Gemini API Test
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gemini API Test',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testGeminiAPI,
                        child: Text(_isLoading ? 'Testing...' : 'Test Gemini API'),
                      ),
                      const SizedBox(height: 10),
                      if (_geminiTested)
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _geminiResults,
                            style: const TextStyle(fontFamily: 'monospace', color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // AI Therapist API Test
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Therapist API Test',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testTherapistAPI,
                        child: Text(_isLoading ? 'Testing...' : 'Test AI Therapist'),
                      ),
                      const SizedBox(height: 10),
                      if (_therapistTested)
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _therapistResults,
                            style: const TextStyle(fontFamily: 'monospace', color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Firebase Test
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Firebase Permissions Test',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: (_isLoading || !_isAuthenticated) ? null : _testFirebasePermissions,
                        child: Text(_isAuthenticated 
                            ? (_isLoading ? 'Testing...' : 'Test Firebase')
                            : 'Must be logged in'),
                      ),
                      if (!_isAuthenticated)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'You need to be logged in to test Firebase permissions',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (_databaseTested)
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _databaseResults.entries.map((entry) {
                              return Text(
                                "${entry.key}: ${entry.value}",
                                style: const TextStyle(fontFamily: 'monospace', color: Colors.black87),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (_geminiTested || _therapistTested || _databaseTested)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suggested Fixes:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        const SizedBox(height: 10),
                        if (_geminiTested && _geminiResults.contains('failed') || _geminiResults.contains('ERROR'))
                          const Text('• Check if the Gemini API key is correct\n• Try updating to a different model version\n• Verify API quota and billing in Google Cloud',
                            style: TextStyle(color: Colors.indigo)),
                        if (_therapistTested && _therapistResults.contains('failed') || _therapistResults.contains('ERROR'))
                          const Text('• Check if the AI Therapist API key is correct\n• Verify the model exists and is accessible\n• Check network connectivity',
                            style: TextStyle(color: Colors.indigo)),
                        if (_databaseTested && _databaseResults.values.any((v) => v.toString().contains('failed')))
                          const Text('• Update Firebase security rules to allow read/write operations\n• Check if Firebase project is properly configured\n• Verify authentication setup',
                            style: TextStyle(color: Colors.indigo)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _testGeminiAPI() async {
    setState(() {
      _isLoading = true;
      _geminiResults = 'Testing Gemini API...';
      _geminiTested = true;
    });
    
    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final directResult = await geminiService.testDirectApiRequest('Say hello and confirm the API is working properly.');
      
      if (directResult.isNotEmpty) {
        setState(() {
          _geminiResults = 'SUCCESS: API responded with: "${directResult.substring(0, directResult.length > 100 ? 100 : directResult.length)}..."';
        });
      } else {
        setState(() {
          _geminiResults = 'FAILED: API did not return a response.';
        });
      }
    } catch (e) {
      setState(() {
        _geminiResults = 'ERROR: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testTherapistAPI() async {
    setState(() {
      _isLoading = true;
      _therapistResults = 'Testing AI Therapist API...';
      _therapistTested = true;
    });
    
    try {
      final therapistService = Provider.of<AITherapistService>(context, listen: false);
      final directResult = await therapistService.testDirectApiRequest('Say hello and confirm the API is working properly.');
      
      if (directResult.isNotEmpty) {
        setState(() {
          _therapistResults = 'SUCCESS: API responded with: "${directResult.substring(0, directResult.length > 100 ? 100 : directResult.length)}..."';
        });
      } else {
        setState(() {
          _therapistResults = 'FAILED: API did not return a response.';
        });
      }
    } catch (e) {
      setState(() {
        _therapistResults = 'ERROR: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testFirebasePermissions() async {
    if (!_isAuthenticated) {
      setState(() {
        _databaseResults = {'error': 'Not authenticated! Please log in before testing Firebase permissions.'};
        _databaseTested = true;
        return;
      });
    }
    
    setState(() {
      _isLoading = true;
      _databaseResults = {'status': 'Testing Firebase permissions...'};
      _databaseTested = true;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final results = await databaseService.testDatabasePermissions();
      
      setState(() {
        _databaseResults = results;
      });
    } catch (e) {
      setState(() {
        _databaseResults = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 