import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:see_app/models/emotion_data.dart';
import 'package:see_app/utils/theme.dart';

/// A high-contrast, icon-based emotion selector for improved accessibility
/// This widget provides large, easy-to-tap buttons with distinct colors and icons for each emotion
class VisualEmotionSelector extends StatelessWidget {
  /// Current selected emotion
  final EmotionType selectedEmotion;
  
  /// Callback when an emotion is selected
  final Function(EmotionType) onEmotionSelected;
  
  /// Size of the buttons (default is large)
  final EmotionButtonSize buttonSize;
  
  /// Whether to show labels under the buttons
  final bool showLabels;
  
  /// Whether to enable haptic feedback on selection
  final bool enableHaptics;
  
  /// Whether to animate the buttons
  final bool animate;
  
  const VisualEmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.onEmotionSelected,
    this.buttonSize = EmotionButtonSize.large,
    this.showLabels = true,
    this.enableHaptics = true,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use layout builder to determine available width
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        
        // Determine button spacing based on available width and button size
        final double spacing = (availableWidth > 450) 
            ? SeeAppTheme.spacing16 
            : SeeAppTheme.spacing8;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: SeeAppTheme.spacing16,
            horizontal: spacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLabels) ...[
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: SeeAppTheme.spacing16),
              ],
              
              // Emotion buttons in a row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmotionButton(
                    context,
                    EmotionType.joy,
                    'Happy',
                    availableWidth,
                  ),
                  _buildEmotionButton(
                    context,
                    EmotionType.sadness,
                    'Sad',
                    availableWidth,
                  ),
                  _buildEmotionButton(
                    context,
                    EmotionType.anger,
                    'Angry',
                    availableWidth,
                  ),
                  _buildEmotionButton(
                    context,
                    EmotionType.fear,
                    'Scared',
                    availableWidth,
                  ),
                  _buildEmotionButton(
                    context,
                    EmotionType.calm,
                    'Calm',
                    availableWidth,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Builds an individual emotion button
  Widget _buildEmotionButton(
    BuildContext context, 
    EmotionType emotion,
    String label,
    double availableWidth,
  ) {
    final bool isSelected = selectedEmotion == emotion;
    final Color color = SeeAppTheme.getEmotionColor(emotion);
    final IconData icon = SeeAppTheme.getEmotionIcon(emotion);
    
    // Determine button size dimensions
    final double buttonDimension = _getButtonDimension(availableWidth);
    final double iconSize = _getIconSize();
    
    // Container for the button
    Widget buttonContainer = Container(
      width: buttonDimension,
      height: buttonDimension,
      decoration: BoxDecoration(
        // Use a gradient background when selected for better visual contrast
        gradient: isSelected 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : null,
        color: isSelected ? null : color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: isSelected ? 3.0 : 2.0,
        ),
        // Add subtle shadow for depth
        boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] 
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          // Use white icon on selected button for better contrast
          color: isSelected ? Colors.white : color,
          size: iconSize,
        ),
      ),
    );
    
    // Apply animation if enabled
    if (animate && isSelected) {
      // Apply a subtle pulse animation when selected
      buttonContainer = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.05),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: buttonContainer,
      );
    }
    
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (enableHaptics) {
              HapticFeedback.mediumImpact();
            }
            onEmotionSelected(emotion);
          },
          borderRadius: BorderRadius.circular(buttonDimension / 2),
          child: buttonContainer,
        ),
        if (showLabels) ...[
          const SizedBox(height: SeeAppTheme.spacing8),
          Text(
            label,
            style: TextStyle(
              fontSize: _getLabelFontSize(),
              color: isSelected ? color : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }
  
  /// Returns the button dimension based on available width and button size
  double _getButtonDimension(double availableWidth) {
    // Adjust button size based on available width and button size preference
    switch (buttonSize) {
      case EmotionButtonSize.small:
        return availableWidth < 350 ? 40 : 48;
      case EmotionButtonSize.medium:
        return availableWidth < 350 ? 56 : 64;
      case EmotionButtonSize.large:
        return availableWidth < 350 ? 64 : 76;
      case EmotionButtonSize.extraLarge:
        return availableWidth < 350 ? 76 : 90;
    }
  }
  
  /// Returns the icon size based on button size
  double _getIconSize() {
    switch (buttonSize) {
      case EmotionButtonSize.small:
        return 24;
      case EmotionButtonSize.medium:
        return 32;
      case EmotionButtonSize.large:
        return 40;
      case EmotionButtonSize.extraLarge:
        return 48;
    }
  }
  
  /// Returns the label font size based on button size
  double _getLabelFontSize() {
    switch (buttonSize) {
      case EmotionButtonSize.small:
        return 12;
      case EmotionButtonSize.medium:
        return 14;
      case EmotionButtonSize.large:
        return 16;
      case EmotionButtonSize.extraLarge:
        return 18;
    }
  }
}

/// Enum for button sizes
enum EmotionButtonSize {
  small,
  medium,
  large,
  extraLarge,
}

/// A dialog that shows the emotion selector with intensity slider
class EmotionRecordingDialog extends StatefulWidget {
  /// Initial selected emotion
  final EmotionType initialEmotion;
  
  /// Initial intensity value (0.0 to 1.0)
  final double initialIntensity;
  
  /// Callback when recording is saved
  final Function(EmotionType emotion, double intensity, String? context) onSave;
  
  /// Title for the dialog
  final String title;
  
  const EmotionRecordingDialog({
    Key? key,
    this.initialEmotion = EmotionType.calm,
    this.initialIntensity = 0.5,
    required this.onSave,
    this.title = 'Record New Emotion',
  }) : super(key: key);

  @override
  State<EmotionRecordingDialog> createState() => _EmotionRecordingDialogState();
}

class _EmotionRecordingDialogState extends State<EmotionRecordingDialog> {
  late EmotionType _selectedEmotion;
  late double _intensity;
  final TextEditingController _contextController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _selectedEmotion = widget.initialEmotion;
    _intensity = widget.initialIntensity;
  }
  
  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(SeeAppTheme.spacing24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(SeeAppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: SeeAppTheme.spacing16),
              
              // Visual emotion selector
              VisualEmotionSelector(
                selectedEmotion: _selectedEmotion,
                onEmotionSelected: (emotion) {
                  setState(() {
                    _selectedEmotion = emotion;
                  });
                },
                buttonSize: EmotionButtonSize.large,
              ),
              
              const SizedBox(height: SeeAppTheme.spacing24),
              
              // Intensity slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How intense is this feeling? (${(_intensity * 100).toInt()}%)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: SeeAppTheme.spacing8),
                  
                  // Custom intensity slider with emoji indicators
                  Row(
                    children: [
                      // Low intensity indicator
                      Icon(
                        SeeAppTheme.getEmotionIcon(_selectedEmotion),
                        color: SeeAppTheme.getEmotionColor(_selectedEmotion).withOpacity(0.3),
                        size: 24,
                      ),
                      
                      // Slider
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: SeeAppTheme.getEmotionColor(_selectedEmotion),
                            inactiveTrackColor: SeeAppTheme.getEmotionColor(_selectedEmotion).withOpacity(0.2),
                            thumbColor: SeeAppTheme.getEmotionColor(_selectedEmotion),
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                          ),
                          child: Slider(
                            value: _intensity,
                            min: 0,
                            max: 1,
                            divisions: 10,
                            label: '${(_intensity * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _intensity = value;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // High intensity indicator
                      Icon(
                        SeeAppTheme.getEmotionIcon(_selectedEmotion),
                        color: SeeAppTheme.getEmotionColor(_selectedEmotion),
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: SeeAppTheme.spacing24),
              
              // Context input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Context (Optional)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: SeeAppTheme.spacing8),
                  TextField(
                    controller: _contextController,
                    decoration: InputDecoration(
                      hintText: 'What was happening when this emotion occurred?',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(SeeAppTheme.spacing16),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              
              const SizedBox(height: SeeAppTheme.spacing32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(
                      _selectedEmotion, 
                      _intensity, 
                      _contextController.text.isNotEmpty ? _contextController.text : null
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: SeeAppTheme.getEmotionColor(_selectedEmotion),
                    padding: const EdgeInsets.symmetric(vertical: SeeAppTheme.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SeeAppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Save Emotion Record',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}