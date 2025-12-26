import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/screens/subscription_screen.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// Therapists tab for discovering and booking therapists
class TherapistsTab extends StatefulWidget {
  final Future<List<AppUser>> therapistsFuture;
  final bool isLoadingTherapists;
  final Function() onRefreshTherapists;
  final Function(AppUser) onAddTherapistToFavorites;
  final Function(AppUser) onViewTherapistProfile;
  final Function(AppUser) onBookAppointment;
  final Function() onViewAllTherapists;

  const TherapistsTab({
    super.key,
    required this.therapistsFuture,
    required this.isLoadingTherapists,
    required this.onRefreshTherapists,
    required this.onAddTherapistToFavorites,
    required this.onViewTherapistProfile,
    required this.onBookAppointment,
    required this.onViewAllTherapists,
  });

  @override
  State<TherapistsTab> createState() => _TherapistsTabState();
}

class _TherapistsTabState extends State<TherapistsTab> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildTherapistSearchBar(),
              const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
              _buildSpecialtySection(),
              const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
              
              // Display real therapist data
              FutureBuilder<List<AppUser>>(
                future: widget.therapistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || widget.isLoadingTherapists) {
                    return const _LoadingPlaceholder(
                      title: 'Therapists',
                      subtitle: 'Loading available therapists...',
                      height: 300,
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return _ErrorView(
                      title: 'Therapists',
                      message: 'Failed to load therapists. Please try again.',
                      onRetry: widget.onRefreshTherapists,
                    );
                  }
                  
                  final therapists = snapshot.data!;
                  
                  if (therapists.isEmpty) {
                    return _buildNoTherapistsView();
                  }
                  
                  return _buildTherapistsListView(therapists);
                },
              ),
              
              const SizedBox(height: 80), // Bottom padding for FAB
            ]),
          ),
        ),
      ],
    );
  }
  
  /// Builds a view when no therapists are available
  Widget _buildNoTherapistsView() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusLarge),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_outlined,
                size: 40,
                color: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
            Text(
              'No Therapists Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
            Text(
              'We couldn\'t find any therapists at the moment. Please check back later or adjust your search criteria.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
            OutlinedButton.icon(
              onPressed: widget.onRefreshTherapists,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }
  
  /// Builds the list view of therapists
  Widget _buildTherapistsListView(List<AppUser> therapists) {
    // Convert AppUser objects to the map format expected by existing UI components
    final therapistMaps = therapists.map((therapist) {
      // Generate a consistent color based on therapist name
      final nameHash = therapist.name.hashCode;
      final colors = [
        theme_utils.SeeAppTheme.primaryColor,
        theme_utils.SeeAppTheme.secondaryColor,
        theme_utils.SeeAppTheme.joyColor,
        theme_utils.SeeAppTheme.calmColor,
      ];
      final colorIndex = nameHash.abs() % colors.length;
      
      // Get initials for the avatar
      final nameParts = therapist.name.split(' ');
      final initials = nameParts.length > 1 
          ? '${nameParts[0][0]}${nameParts[1][0]}' 
          : nameParts[0].substring(0, math.min(2, nameParts[0].length));
          
      return {
        'id': therapist.id,
        'name': therapist.name,
        'specialty': therapist.additionalInfo?['specialty'] ?? 'Therapist',
        'rating': therapist.additionalInfo?['rating'] ?? '4.8',
        'reviews': therapist.additionalInfo?['reviews'] ?? '24',
        'availability': 'Available Next Week',
        'image': initials,
        'color': colors[colorIndex],
        'isOnline': false,
        'rawData': therapist, // Keep the original data for reference
      };
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Therapists',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: widget.onRefreshTherapists,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
        _buildTopRatedTherapistsSection(therapistMaps),
      ],
    );
  }
  
  /// Builds the search bar for therapists
  Widget _buildTherapistSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: theme_utils.SeeAppTheme.spacing16, 
        vertical: theme_utils.SeeAppTheme.spacing8
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(color: theme_utils.SeeAppTheme.primaryColor),
        boxShadow: [
          BoxShadow(
            color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme_utils.SeeAppTheme.primaryColor),
          const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search therapists',
                hintStyle: TextStyle(color: theme_utils.SeeAppTheme.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                // Filter therapists (implemented in a full app)
                HapticFeedback.selectionClick();
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              // Show filter options
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter options will be shown here'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
              ),
              child: Icon(
                Icons.tune,
                size: 18,
                color: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the specialty filter section
  Widget _buildSpecialtySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialty',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildSpecialtyChip('All', true),
              _buildSpecialtyChip('Speech', false),
              _buildSpecialtyChip('Occupational', false),
              _buildSpecialtyChip('Physical', false),
              _buildSpecialtyChip('Psychology', false),
              _buildSpecialtyChip('Behavioral', false),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Builds the top rated therapists section
  Widget _buildTopRatedTherapistsSection(List<Map<String, dynamic>> therapists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Rated Therapists',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAllTherapists,
              child: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: theme_utils.SeeAppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
        
        // Therapist cards
        ...therapists.asMap().entries.map((entry) {
          final index = entry.key;
          final therapist = entry.value;
          return _buildTherapistCard(therapist, index).animate(
            delay: Duration(milliseconds: 100 * index)
          )
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
        }).toList(),
      ],
    );
  }
  
  /// Builds a specialty filter chip
  Widget _buildSpecialtyChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: theme_utils.SeeAppTheme.spacing8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Filter therapists by specialty
          HapticFeedback.selectionClick();
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: theme_utils.SeeAppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: theme_utils.SeeAppTheme.spacing8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
          side: BorderSide(
            color: isSelected ? theme_utils.SeeAppTheme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
      ),
    );
  }
  
  /// Builds a specialization chip for therapist profiles
  Widget _buildSpecializationChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: theme_utils.SeeAppTheme.primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: TextStyle(
        fontSize: 12,
        color: theme_utils.SeeAppTheme.primaryColor,
      ),
    );
  }
  
  /// Builds a therapist card
  Widget _buildTherapistCard(Map<String, dynamic> therapist, int index) {
    final rawTherapist = therapist['rawData'] as AppUser;
    final parentState = context.findAncestorStateOfType<ParentDashboardState>();
    Child? assignedChild;
    if (parentState != null) {
      try {
        assignedChild = parentState.getChildren().firstWhere(
          (child) => child.additionalInfo['assignedTherapistId'] == rawTherapist.id,
        );
      } catch (e) {
        // No child is assigned to this therapist
        assignedChild = null;
      }
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
      ),
      margin: const EdgeInsets.only(bottom: theme_utils.SeeAppTheme.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(theme_utils.SeeAppTheme.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: (therapist['color'] as Color).withOpacity(0.2),
              child: Text(
                therapist['image'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: therapist['color'] as Color,
                ),
              ),
            ),
            const SizedBox(width: theme_utils.SeeAppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    therapist['name'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    therapist['specialty'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme_utils.SeeAppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing4),
                      Text(
                        '${therapist['rating']} (${therapist['reviews']} reviews)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing4),
                  Text(
                    therapist['availability'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: therapist['availability'] == 'Available Today'
                          ? Colors.green
                          : Colors.grey.shade700,
                      fontWeight: therapist['availability'] == 'Available Today'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onViewTherapistProfile(rawTherapist);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme_utils.SeeAppTheme.primaryColor,
                            side: BorderSide(color: theme_utils.SeeAppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: theme_utils.SeeAppTheme.spacing8),
                          ),
                          child: const Text('View Profile'),
                        ),
                      ),
                      const SizedBox(width: theme_utils.SeeAppTheme.spacing8),
                      Expanded(
                        child: assignedChild != null
                            ? ElevatedButton(
                                onPressed: () {
                                  final parentState = context.findAncestorStateOfType<ParentDashboardState>();
                                  if (parentState != null && assignedChild != null) {
                                    parentState.navigateToMessages(
                                      therapistId: rawTherapist.id,
                                      childId: assignedChild!.id,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Opening chat with ${rawTherapist.name} for ${assignedChild!.name}.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: theme_utils.SeeAppTheme.spacing8),
                                ),
                                child: const Text('Message Therapist'),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  final parentContext = context;
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      Child? selectedChild;
                                      return AlertDialog(
                                        title: const Text('Assign Therapist to Child'),
                                        content: StatefulBuilder(
                                          builder: (context, setState) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                DropdownButtonFormField<Child>(
                                              value: selectedChild,
                                              hint: const Text('Select Child'),
                                                  items: parentState?.getChildren().map((child) {
                                                return DropdownMenuItem<Child>(
                                                  value: child,
                                                  child: Text(child.name),
                                                );
                                                  })?.toList() ?? [],
                                              onChanged: (child) {
                                                setState(() {
                                                  selectedChild = child;
                                                });
                                              },
                                                ),
                                                const SizedBox(height: 16),
                                                Text('Therapist Fee: ' +
                                                  (rawTherapist.additionalInfo?['fee'] != null
                                                    ? '\$24${rawTherapist.additionalInfo?['fee'].toString()}'
                                                    : 'Not specified'),
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              if (selectedChild == null) {
                                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Please select a child.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                return;
                                              }
                                              Navigator.pop(context);
                                              try {
                                                final databaseService = Provider.of<DatabaseService>(parentContext, listen: false);
                                                final authService = Provider.of<AuthService>(parentContext, listen: false);
                                                final parentId = authService.currentUser?.id ?? '';
                                                if (parentId.isEmpty) {
                                                  throw Exception('Parent ID not found. Please log in again.');
                                                }
                                                final feeRaw = rawTherapist.additionalInfo?['fee'];
                                                num therapistFee = 0;
                                                if (feeRaw is num) {
                                                  therapistFee = feeRaw;
                                                } else if (feeRaw is String) {
                                                  therapistFee = num.tryParse(feeRaw) ?? 0;
                                                }
                                                await databaseService.assignTherapistToChild(
                                                  childId: selectedChild!.id,
                                                  therapistId: rawTherapist.id,
                                                  therapistFee: therapistFee,
                                                  parentId: parentId,
                                                );
                                                
                                                // Navigate to subscription screen for payment
                                                if (parentContext.mounted) {
                                                  Navigator.of(parentContext).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => SubscriptionScreen(
                                                        therapist: rawTherapist,
                                                        childId: selectedChild!.id,
                                                        childName: selectedChild!.name,
                                                        therapistFee: therapistFee,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to assign therapist: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                                            ),
                                            child: const Text('Assign'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: theme_utils.SeeAppTheme.spacing8),
                                ),
                                child: const Text('Assign to Child'),
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
    );
  }
}

/// Loading placeholder widget for async data
class _LoadingPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  
  const _LoadingPlaceholder({
    required this.title,
    required this.subtitle,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: theme_utils.SeeAppTheme.spacing8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme_utils.SeeAppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme_utils.SeeAppTheme.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme_utils.SeeAppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view widget for failed data loads
class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  
  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: theme_utils.SeeAppTheme.spacing24),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: theme_utils.SeeAppTheme.spacing16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: theme_utils.SeeAppTheme.spacing16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}