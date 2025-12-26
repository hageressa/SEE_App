import 'package:flutter/material.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class ClientManagementDashboard extends StatefulWidget {
  final DatabaseService databaseService;
  final List<Child> patients;
  final Function(List<Child>) onPatientsUpdated;

  const ClientManagementDashboard({
    Key? key,
    required this.databaseService,
    required this.patients,
    required this.onPatientsUpdated,
  }) : super(key: key);

  @override
  State<ClientManagementDashboard> createState() => _ClientManagementDashboardState();
}

class _ClientManagementDashboardState extends State<ClientManagementDashboard> {
  List<Child> _patients = [];
  List<String> _availableTags = [
    'Anxiety', 'Depression', 'ADHD', 'Autism', 'Behavioral', 
    'Trauma', 'Family Issues', 'New Patient', 'Progress Review',
    'Elementary', 'Middle School', 'High School'
  ];
  Map<String, List<String>> _patientTags = {};
  Map<String, String> _patientGroups = {};
  List<String> _groups = ['Unassigned', 'Group A', 'Group B', 'Individual', 'Family Therapy', 'Crisis Support'];
  String _filterTag = '';
  String _filterGroup = '';
  bool _isLoading = false;
  
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _newGroupController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patients = List.from(widget.patients);
    _loadTagsAndGroups();
  }

  Future<void> _loadTagsAndGroups() async {
    setState(() => _isLoading = true);
    
    try {
      // Load existing tags and groups for each patient
      for (final patient in _patients) {
        final patientData = await widget.databaseService.getPatientMetadata(patient.id);
        
        if (patientData.containsKey('tags') && patientData['tags'] is List) {
          _patientTags[patient.id] = List<String>.from(patientData['tags']);
        } else {
          _patientTags[patient.id] = [];
        }
        
        if (patientData.containsKey('group') && patientData['group'] is String) {
          _patientGroups[patient.id] = patientData['group'];
        } else {
          _patientGroups[patient.id] = 'Unassigned';
        }
      }
      
      // Load any custom tags from database
      final customTagsData = await widget.databaseService.getTherapistCustomTags();
      if (customTagsData.isNotEmpty) {
        for (final tag in customTagsData) {
          if (!_availableTags.contains(tag)) {
            _availableTags.add(tag);
          }
        }
      }
      
      // Load any custom groups from database
      final customGroupsData = await widget.databaseService.getTherapistCustomGroups();
      if (customGroupsData.isNotEmpty) {
        for (final group in customGroupsData) {
          if (!_groups.contains(group)) {
            _groups.add(group);
          }
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading tags and groups: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _savePatientTag(String patientId, List<String> tags) async {
    try {
      await widget.databaseService.updatePatientMetadata(patientId, {'tags': tags});
      setState(() {
        _patientTags[patientId] = tags;
      });
    } catch (e) {
      print('Error saving tags: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tags: $e')),
        );
      }
    }
  }

  Future<void> _savePatientGroup(String patientId, String group) async {
    try {
      await widget.databaseService.updatePatientMetadata(patientId, {'group': group});
      setState(() {
        _patientGroups[patientId] = group;
      });
    } catch (e) {
      print('Error saving group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving group: $e')),
        );
      }
    }
  }

  void _addNewTag() {
    final newTag = _newTagController.text.trim();
    if (newTag.isNotEmpty && !_availableTags.contains(newTag)) {
      setState(() {
        _availableTags.add(newTag);
        _newTagController.clear();
      });
      widget.databaseService.saveTherapistCustomTag(newTag);
    }
  }

  void _addNewGroup() {
    final newGroup = _newGroupController.text.trim();
    if (newGroup.isNotEmpty && !_groups.contains(newGroup)) {
      setState(() {
        _groups.add(newGroup);
        _newGroupController.clear();
      });
      widget.databaseService.saveTherapistCustomGroup(newGroup);
    }
  }

  List<Child> get _filteredPatients {
    if (_filterTag.isEmpty && _filterGroup.isEmpty && _searchController.text.isEmpty) {
      return _patients;
    }
    
    return _patients.where((patient) {
      bool matchesTag = _filterTag.isEmpty || 
          _patientTags[patient.id]?.contains(_filterTag) == true;
      
      bool matchesGroup = _filterGroup.isEmpty || 
          _patientGroups[patient.id] == _filterGroup;
      
      bool matchesSearch = _searchController.text.isEmpty || 
          patient.name.toLowerCase().contains(_searchController.text.toLowerCase());
      
      return matchesTag && matchesGroup && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTagsAndGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilterBar(),
                Expanded(
                  child: _buildClientList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _showManageTagsAndGroupsDialog,
        tooltip: 'Manage Tags & Groups',
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Filter by Tag',
                  _filterTag,
                  ['', ..._availableTags],
                  (value) {
                    setState(() {
                      _filterTag = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Filter by Group',
                  _filterGroup,
                  ['', ..._groups],
                  (value) {
                    setState(() {
                      _filterGroup = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hint,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint),
          value: value.isEmpty ? null : value,
          isExpanded: true,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option.isEmpty ? 'All' : option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildClientList() {
    final filteredPatients = _filteredPatients;
    
    if (filteredPatients.isEmpty) {
      return const Center(
        child: Text('No clients match the current filters'),
      );
    }
    
    return ListView.builder(
      itemCount: filteredPatients.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        return _buildClientCard(patient);
      },
    );
  }

  Widget _buildClientCard(Child patient) {
    final tags = _patientTags[patient.id] ?? [];
    final group = _patientGroups[patient.id] ?? 'Unassigned';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: patient.avatar != null
                      ? NetworkImage(patient.avatar!)
                      : null,
                  child: patient.avatar == null
                      ? Text(patient.name[0],
                          style: const TextStyle(fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${patient.age} years old · ${patient.gender}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditPatientDialog(patient),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group: $group',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showChangeGroupDialog(patient),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(group),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tags:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            backgroundColor: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.1),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              final updatedTags = List<String>.from(tags)..remove(tag);
                              _savePatientTag(patient.id, updatedTags);
                            },
                          )),
                          ActionChip(
                            label: const Icon(Icons.add, size: 16),
                            onPressed: () => _showAddTagDialog(patient),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog(Child patient) {
    final currentTags = _patientTags[patient.id] ?? [];
    final availableTags = _availableTags.where((tag) => !currentTags.contains(tag)).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Tags for ${patient.name}'),
        content: availableTags.isEmpty
            ? const Text('No more tags available. Create new tags first.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableTags.length,
                  itemBuilder: (context, index) {
                    final tag = availableTags[index];
                    return ListTile(
                      title: Text(tag),
                      onTap: () {
                        final updatedTags = List<String>.from(currentTags)..add(tag);
                        _savePatientTag(patient.id, updatedTags);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showChangeGroupDialog(Child patient) {
    String selectedGroup = _patientGroups[patient.id] ?? 'Unassigned';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Group for ${patient.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return RadioListTile<String>(
                title: Text(group),
                value: group,
                groupValue: selectedGroup,
                onChanged: (value) {
                  setState(() {
                    selectedGroup = value!;
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              _savePatientGroup(patient.id, selectedGroup);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(Child patient) {
    // This would be a more comprehensive edit dialog
    // Not fully implemented in this example
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${patient.name}'),
        content: const Text('Full patient editing functionality would be implemented here.'),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showManageTagsAndGroupsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Manage Tags & Groups'),
            content: SizedBox(
              width: double.maxFinite,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Tags'),
                        Tab(text: 'Groups'),
                      ],
                      labelColor: Colors.black,
                    ),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          // Tags tab
                          Column(
                            children: [
                              TextField(
                                controller: _newTagController,
                                decoration: const InputDecoration(
                                  labelText: 'New Tag',
                                  hintText: 'Enter a new tag',
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                child: const Text('Add Tag'),
                                onPressed: () {
                                  _addNewTag();
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _availableTags.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(_availableTags[index]),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          // Delete tag functionality would be here
                                          // Need to ensure it's not in use first
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Groups tab
                          Column(
                            children: [
                              TextField(
                                controller: _newGroupController,
                                decoration: const InputDecoration(
                                  labelText: 'New Group',
                                  hintText: 'Enter a new group',
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                child: const Text('Add Group'),
                                onPressed: () {
                                  _addNewGroup();
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _groups.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(_groups[index]),
                                      trailing: index < 2
                                          ? null // Protect default groups
                                          : IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                // Delete group functionality would be here
                                                // Need to ensure it's not in use first
                                              },
                                            ),
                                    );
                                  },
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
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
