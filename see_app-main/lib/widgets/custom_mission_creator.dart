import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/difficulty_level.dart';
import 'package:see_app/models/mission_category.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class CustomMissionCreator extends StatefulWidget {
  final DatabaseService databaseService;
  final List<Child> patients;
  final Function(Mission) onMissionCreated;
  final Mission? missionToEdit;

  const CustomMissionCreator({
    Key? key,
    required this.databaseService,
    required this.patients,
    required this.onMissionCreated,
    this.missionToEdit,
  }) : super(key: key);

  @override
  State<CustomMissionCreator> createState() => _CustomMissionCreatorState();
}

class _CustomMissionCreatorState extends State<CustomMissionCreator> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardPointsController = TextEditingController();
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<String> _selectedPatientIds = [];
  List<EmotionType> _targetEmotions = [];
  DifficultyLevel _difficultyLevel = DifficultyLevel.medium;
  MissionCategory _missionCategory = MissionCategory.mindfulness;
  bool _isForAllPatients = false;
  bool _isCreatingMission = false;

  @override
  void initState() {
    super.initState();
    if (widget.missionToEdit != null) {
      _loadMissionData();
    } else {
      _rewardPointsController.text = '50'; // Default reward points
    }
  }

  void _loadMissionData() {
    final mission = widget.missionToEdit!;
    _titleController.text = mission.title;
    _descriptionController.text = mission.description;
    _rewardPointsController.text = mission.rewardPoints.toString();
    _dueDate = mission.dueDate;
    _selectedPatientIds = mission.assignedTo != null ? [mission.assignedTo!] : [];
    _targetEmotions = mission.targetEmotions ?? [];
    _difficultyLevel = mission.difficultyLevel;
    _missionCategory = mission.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardPointsController.dispose();
    super.dispose();
  }

  Future<void> _createMission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientIds.isEmpty && !_isForAllPatients) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one patient')),
      );
      return;
    }

    setState(() => _isCreatingMission = true);

    try {
      final now = DateTime.now();
      List<String> patientIds = _isForAllPatients
          ? widget.patients.map((p) => p.id).toList()
          : _selectedPatientIds;

      // If editing, create updated mission
      if (widget.missionToEdit != null) {
        final updatedMission = widget.missionToEdit!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          rewardPoints: int.parse(_rewardPointsController.text),
          difficultyLevel: _difficultyLevel,
          category: _missionCategory,
          dueDate: _dueDate,
          targetEmotions: _targetEmotions,
        );
        
        await widget.databaseService.updateMission(updatedMission);
        widget.onMissionCreated(updatedMission);
      } else {
        // Create missions for all selected patients
        for (final patientId in patientIds) {
          final newMission = Mission(
            id: 'mission_${now.millisecondsSinceEpoch}_$patientId',
            title: _titleController.text,
            description: _descriptionController.text,
            assignedTo: patientId,
            isCompleted: false,
            dueDate: _dueDate,
            difficulty: _difficultyLevel.index + 1,
            category: _missionCategory,
            targetEmotions: _targetEmotions,
            evidenceSource: 'Custom therapist mission',
          );
          
          await widget.databaseService.createMission(newMission);
          
          // Notify parent widget about creation
          if (patientId == patientIds.last) {
            widget.onMissionCreated(newMission);
          }
        }
      }

      setState(() => _isCreatingMission = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.missionToEdit != null 
                ? 'Mission updated successfully'
                : 'Mission created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreatingMission = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.missionToEdit != null 
            ? 'Edit Mission' 
            : 'Create Custom Mission'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _isCreatingMission ? null : _createMission,
          ),
        ],
      ),
      body: _isCreatingMission
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildAssignees(),
                    const SizedBox(height: 24),
                    _buildEmotionTagging(),
                    const SizedBox(height: 24),
                    _buildDifficultyAndCategorySection(),
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _createMission,
                          child: Text(
                            widget.missionToEdit != null
                                ? 'Update Mission'
                                : 'Create Mission',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Mission Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a mission title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mission Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a mission description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rewardPointsController,
                    decoration: const InputDecoration(
                      labelText: 'Reward Points',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _dueDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM d, y').format(_dueDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignees() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign To Patients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Assign to all patients'),
              value: _isForAllPatients,
              onChanged: (value) {
                setState(() {
                  _isForAllPatients = value ?? false;
                  if (_isForAllPatients) {
                    _selectedPatientIds = [];
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),
            if (!_isForAllPatients) ...[
              const SizedBox(height: 8),
              const Text(
                'Select specific patients:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.patients.map((patient) {
                return CheckboxListTile(
                  title: Text(patient.name),
                  subtitle: Text('${patient.age} years old'),
                  value: _selectedPatientIds.contains(patient.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedPatientIds.add(patient.id);
                      } else {
                        _selectedPatientIds.remove(patient.id);
                      }
                    });
                  },
                  secondary: CircleAvatar(
                    backgroundImage: patient.avatar != null
                        ? NetworkImage(patient.avatar!)
                        : null,
                    child: patient.avatar == null
                        ? Text(patient.name[0])
                        : null,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionTagging() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Emotions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select emotions this mission helps with:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmotionType.values.map((emotion) {
                final isSelected = _targetEmotions.contains(emotion);
                return FilterChip(
                  label: Text(emotion.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _targetEmotions.add(emotion);
                      } else {
                        _targetEmotions.remove(emotion);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: _getEmotionColor(emotion).withOpacity(0.2),
                  checkmarkColor: _getEmotionColor(emotion),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _getEmotionColor(emotion)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.joy:
        return Colors.yellow.shade800;
      case EmotionType.sadness:
        return Colors.blue;
      case EmotionType.anger:
        return Colors.red;
      case EmotionType.fear:
        return Colors.purple;
      case EmotionType.disgust:
        return Colors.green;
      case EmotionType.surprise:
        return Colors.orange;
      default:
        return theme_utils.SeeAppTheme.primaryColor;
    }
  }

  Widget _buildDifficultyAndCategorySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Difficulty Level:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: DifficultyLevel.values.map((level) {
                final isSelected = _difficultyLevel == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(level.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _difficultyLevel = level;
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? theme_utils.SeeAppTheme.primaryColor
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Category:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MissionCategory.values.map((category) {
                final isSelected = _missionCategory == category;
                return ChoiceChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _missionCategory = category;
                      });
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: theme_utils.SeeAppTheme.secondaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme_utils.SeeAppTheme.secondaryColor
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
