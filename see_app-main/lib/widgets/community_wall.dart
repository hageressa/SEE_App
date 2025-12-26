import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/community_post.dart';
import 'package:see_app/models/mission.dart';
import 'package:see_app/models/mission_category.dart';
import 'package:see_app/services/community_service.dart';
import 'package:see_app/utils/theme.dart' as theme_utils;

/// A widget that displays a community wall of anonymous parent posts
class CommunityWall extends StatefulWidget {
  final String? title;
  final bool showHeader;
  final String? missionFilter;
  final String? categoryFilter;
  final ScrollPhysics? physics;
  final bool showCreatePost;
  final bool showCreatePostOnly;
  final Mission? completedMission;

  const CommunityWall({
    Key? key,
    this.title = 'Parent Community',
    this.showHeader = true,
    this.missionFilter,
    this.categoryFilter,
    this.physics,
    this.showCreatePost = false,
    this.showCreatePostOnly = false,
    this.completedMission,
  }) : super(key: key);

  @override
  State<CommunityWall> createState() => _CommunityWallState();
}

class _CommunityWallState extends State<CommunityWall> {
  final TextEditingController _postController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityService>(
      builder: (context, communityService, child) {
        // Apply filters based on props
        List<CommunityPost> filteredPosts = communityService.posts;
        if (widget.missionFilter != null) {
          filteredPosts = filteredPosts
              .where((post) => post.missionId == widget.missionFilter)
              .toList();
        }
        if (widget.categoryFilter != null) {
          filteredPosts = filteredPosts
              .where((post) => post.missionCategory == widget.categoryFilter)
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            if (widget.showHeader && !widget.showCreatePostOnly)
              _buildHeader(context, communityService),
            
            // Create post section
            if (widget.showCreatePost || widget.showCreatePostOnly)
              _buildCreatePost(context, communityService),
            
            // Posts list
            if (!widget.showCreatePostOnly && communityService.isLoading)
              _buildLoadingState()
            else if (!widget.showCreatePostOnly && communityService.error != null)
              _buildErrorState(communityService.error!)
            else if (!widget.showCreatePostOnly && filteredPosts.isEmpty)
              _buildEmptyState()
            else if (!widget.showCreatePostOnly)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    return _buildPostCard(context, post, communityService);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CommunityService communityService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.forum_rounded,
                color: theme_utils.SeeAppTheme.joyColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!communityService.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => communityService.fetchPosts(),
              color: theme_utils.SeeAppTheme.primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildCreatePost(BuildContext context, CommunityService communityService) {
    // If we're showing create post due to a completed mission or in "only" mode
    final bool hasCompletedMission = widget.completedMission != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with mission info
          Row(
            children: [
              if (hasCompletedMission) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.completedMission!.getCategoryColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.completedMission!.getCategoryIcon(),
                    color: widget.completedMission!.getCategoryColor(),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  hasCompletedMission
                      ? 'Share about "${widget.completedMission!.title}"'
                      : 'Share your experience',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description of completed mission
          if (hasCompletedMission) ...[
            Text(
              widget.completedMission!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Text field for post
          TextField(
            controller: _postController,
            decoration: InputDecoration(
              hintText: hasCompletedMission
                  ? 'What did you notice about your child during this activity?'
                  : 'Share a parenting challenge, success, or question...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              errorText: _errorMessage,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          
          // Bottom info about anonymity
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Your post will be anonymous and visible to other parents',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          // Post button
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitPost(context, communityService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme_utils.SeeAppTheme.joyColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: _isSubmitting
                    ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(4),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_isSubmitting ? 'Posting...' : 'Post'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
      BuildContext context, CommunityPost post, CommunityService communityService) {
    final reactions = post.reactions;
    final categoryColor = post.getCategoryColor();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme_utils.SeeAppTheme.cardBackground.withOpacity(0.7),
            theme_utils.SeeAppTheme.cardBackground.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(
          color: categoryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with mission info
            if (post.missionTitle != null && post.missionCategory != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: post.getCategoryColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      post.getCategoryIcon(),
                      color: post.getCategoryColor(),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.missionTitle!,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Mission: ${_categoryToDisplay(post.missionCategory!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme_utils.SeeAppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    post.getTimeAgo(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme_utils.SeeAppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // Post content
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Reactions and actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display current reactions
                if (reactions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusSmall),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: reactions.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: post.getCategoryColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '${entry.key} ${entry.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Reaction buttons and flag option
                Row(
                  children: [
                    const Text(
                      'React:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Show a few common reactions
                    for (final emoji in ['❤️', '👍', '👏', '🙌'].take(4))
                      InkWell(
                        onTap: () => communityService.addReaction(post.id, emoji),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(right: 4),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    
                    // More reactions dropdown
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.add_reaction,
                        size: 20,
                        color: Colors.grey,
                      ),
                      itemBuilder: (context) {
                        return CommunityPost.getAvailableReactions()
                            .map((emoji) => PopupMenuItem(
                                  value: emoji,
                                  child: Text(emoji),
                                ))
                            .toList();
                      },
                      onSelected: (emoji) => 
                          communityService.addReaction(post.id, emoji),
                    ),
                    
                    const Spacer(),
                    
                    // Flag inappropriate content
                    IconButton(
                      icon: const Icon(
                        Icons.flag,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () => _showFlagDialog(context, post, communityService),
                      tooltip: 'Report inappropriate content',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: 50.ms)
      .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 50.ms);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme_utils.SeeAppTheme.joyColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Loading posts...',
              style: TextStyle(
                color: theme_utils.SeeAppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(
          color: Colors.red.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load posts',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme_utils.SeeAppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: TextButton(
                    onPressed: () => Provider.of<CommunityService>(context, listen: false).fetchPosts(),
                    child: Text('Try Again', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: theme_utils.SeeAppTheme.joyColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(60, 20),
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

  Widget _buildEmptyState() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme_utils.SeeAppTheme.joyColor.withOpacity(0.05),
            theme_utils.SeeAppTheme.joyColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(theme_utils.SeeAppTheme.radiusMedium),
        border: Border.all(
          color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 18,
              color: theme_utils.SeeAppTheme.joyColor.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'No community posts yet. Share your experience!',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme_utils.SeeAppTheme.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  void _showFlagDialog(
      BuildContext context, CommunityPost post, CommunityService communityService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: theme_utils.SeeAppTheme.cardBackground,
        title: Row(
          children: [
            Icon(
              Icons.flag,
              color: Colors.red.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Report Content', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to report this post as inappropriate?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: theme_utils.SeeAppTheme.textSecondary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade300,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade300.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                communityService.flagPost(post.id).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post reported. Thank you for helping keep our community safe.'),
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                });
              },
              child: const Text('Report', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ).animate()
        .fade(duration: 200.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 200.ms),
    );
  }

  Future<void> _submitPost(BuildContext context, CommunityService communityService) async {
    final content = _postController.text.trim();
    
    if (content.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter some text to share';
      });
      return;
    }
    
    if (content.length < 5) {
      setState(() {
        _errorMessage = 'Please enter at least 5 characters';
      });
      return;
    }
    
    // Update UI to show loading state
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    // Call the service to create a post
    communityService.createPost(
      content: content,
      mission: widget.completedMission, // Can be null, service should handle this
    ).then((success) {
      if (mounted) {
        if (success) {
          _postController.clear();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Posted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          setState(() {
            _isSubmitting = false;
          });
        } else {
          setState(() {
            _isSubmitting = false;
            _errorMessage = communityService.error ?? 'Failed to post. Please try again.';
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Error: $error';
        });
      }
    });
  }

  String _categoryToDisplay(String category) {
    return category.substring(0, 1).toUpperCase() + category.substring(1);
  }
}

/// A dialog to create a new community post after completing a mission
class CreatePostDialog extends StatefulWidget {
  final Mission mission;

  const CreatePostDialog({
    Key? key,
    required this.mission,
  }) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.mission.getCategoryIcon(),
                  color: widget.mission.getCategoryColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share Your Experience',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mission: ${widget.mission.title}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'What did your child do or say that surprised you?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text(
              'Your post will be anonymous to help build our supportive community',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme_utils.SeeAppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme_utils.SeeAppTheme.joyColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Share with Community'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitPost() async {
    final content = _controller.text.trim();
    
    if (content.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter some text to share';
      });
      return;
    }
    
    if (content.length < 5) {
      setState(() {
        _errorMessage = 'Please enter at least 5 characters';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    final success = await Provider.of<CommunityService>(context, listen: false)
        .createPost(
      content: content,
      mission: widget.mission,
    );
    
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = Provider.of<CommunityService>(context, listen: false).error ?? 
              'Failed to post. Please try again.';
        });
      }
    }
  }
}

/// Extension for Mission to get icon and color
extension MissionDisplayExtension on Mission {
  IconData getCategoryIcon() {
    switch (category) {
      case MissionCategory.mimicry:
        return Icons.face;
      case MissionCategory.storytelling:
        return Icons.book;
      case MissionCategory.labeling:
        return Icons.label;
      case MissionCategory.bonding:
        return Icons.favorite;
      case MissionCategory.routines:
        return Icons.calendar_today;
      default:
        return Icons.article;
    }
  }

  Color getCategoryColor() {
    switch (category) {
      case MissionCategory.mimicry:
        return Colors.orange;
      case MissionCategory.storytelling:
        return Colors.blue;
      case MissionCategory.labeling:
        return Colors.green;
      case MissionCategory.bonding:
        return Colors.red;
      case MissionCategory.routines:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}