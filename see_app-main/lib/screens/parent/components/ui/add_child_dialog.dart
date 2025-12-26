import 'package:flutter/material.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  String _selectedGender = 'Not specified';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  /// Validate required fields
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate age field
  String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 0 || age > 18) {
      return 'Age must be between 0 and 18';
    }
    return null;
  }

  Map<String, dynamic>? _validateAndGetData() {
    if (!_formKey.currentState!.validate()) return null;

    return {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': _selectedGender,
      'additionalInfo': {'notes': _additionalInfoController.text.trim()},
      'concerns': <String>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Child'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Child Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => validateRequired(value, 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: validateAge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Not specified'].map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _additionalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Additional Information (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final data = _validateAndGetData();
            if (data != null) {
              Navigator.pop(context, data);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme_utils.SeeAppTheme.primaryColor,
          ),
          child: const Text('Add Child'),
        ),
      ],
    );
  }
} 