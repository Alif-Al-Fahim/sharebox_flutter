import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/tool_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tool_provider.dart';
import '../../providers/rental_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../chat/chat_screen.dart';

class ToolDetailScreen extends StatefulWidget {
  final ToolModel tool;

  const ToolDetailScreen({super.key, required this.tool});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  int _currentImageIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _totalPrice => _durationDays * widget.tool.pricePerDay;

  Future<void> _requestRental() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.userId == widget.tool.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot rent your own tool.')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates first.')),
      );
      return;
    }

    final success = await context.read<RentalProvider>().createRentalRequest(
          toolId: widget.tool.id,
          toolName: widget.tool.name,
          toolImage: widget.tool.images.isNotEmpty ? widget.tool.images.first : null,
          ownerId: widget.tool.ownerId,
          ownerName: widget.tool.ownerName,
          renterId: auth.userId,
          renterName: auth.userName,
          startDate: _startDate!,
          endDate: _endDate!,
          pricePerDay: widget.tool.pricePerDay,
          message: _messageCtrl.text.trim().isNotEmpty
              ? _messageCtrl.text.trim()
              : null,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Rental request sent successfully!'
              : '❌ Failed to send request.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  Future<void> _openChat() async {
    final auth = context.read<AppAuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final roomId = await chatProvider.createOrGetChatRoom(
      currentUserId: auth.userId,
      currentUserName: auth.userName,
      currentUserImage: auth.userModel?.profileImage,
      otherUserId: widget.tool.ownerId,
      otherUserName: widget.tool.ownerName,
      otherUserImage: widget.tool.ownerImage,
      toolId: widget.tool.id,
      toolName: widget.tool.name,
    );

    if (roomId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: roomId,
            otherUserId: widget.tool.ownerId,
            otherUserName: widget.tool.ownerName,
            otherUserImage: widget.tool.ownerImage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolProvider = context.watch<ToolProvider>();
    final authProvider = context.watch<AppAuthProvider>();
    final isFavorite = toolProvider.isFavorite(widget.tool.id);
    final isOwner = authProvider.userId == widget.tool.ownerId;
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Image Sliver App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
                color: AppTheme.lightTextPrimary,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () {
                    toolProvider.toggleFavorite(authProvider.userId, widget.tool.id);
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Images
                  widget.tool.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: widget.tool.images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: widget.tool.images[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade100),
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFEEF2F7),
                          child: const Center(
                            child: Icon(Icons.construction_rounded,
                                size: 80, color: Colors.grey),
                          ),
                        ),
                  // Image indicators
                  if (widget.tool.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.tool.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.circular),
                        ),
                        child: Text(
                          '${widget.tool.category.emoji} ${widget.tool.category.displayName}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.tool.isAvailable
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.circular),
                        ),
                        child: Text(
                          widget.tool.isAvailable ? '✅ Available' : '🔴 Rented',
                          style: TextStyle(
                            color: widget.tool.isAvailable
                                ? AppTheme.successColor
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tool name
                  Text(
                    widget.tool.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppTheme.secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.tool.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Rate',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              widget.tool.formattedPrice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (widget.tool.rating != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFFD700), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.tool.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${widget.tool.reviewCount} reviews',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('About this Tool',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    widget.tool.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Owner info
                  Text('Tool Owner',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: widget.tool.ownerImage != null
                              ? CachedNetworkImageProvider(
                                  widget.tool.ownerImage!)
                              : null,
                          child: widget.tool.ownerImage == null
                              ? Text(
                                  widget.tool.ownerName.isNotEmpty
                                      ? widget.tool.ownerName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tool.ownerName,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                widget.tool.location,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (!isOwner)
                          OutlinedButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 16),
                            label: const Text('Chat'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (!isOwner && widget.tool.isAvailable) ...[
                    const SizedBox(height: 24),

                    // Date picker
                    Text('Select Rental Dates',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: _startDate != null
                                ? AppTheme.primaryColor.withOpacity(0.5)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _startDate == null
                                  ? Text(
                                      'Tap to select start & end date',
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${fmt.format(_startDate!)}  →  ${fmt.format(_endDate!)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(
                                          '$_durationDays day${_durationDays > 1 ? 's' : ''} · Total: ৳${_totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: AppTheme.secondaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optional message
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Message to owner (optional)...',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Total summary
                    if (_startDate != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '৳${widget.tool.pricePerDay.toStringAsFixed(0)} × $_durationDays days',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(
                              '৳${_totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Bar ─────────────────────────────────────────────
      bottomNavigationBar: !isOwner && widget.tool.isAvailable
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GradientButton(
                text: 'Request to Rent',
                onPressed: _requestRental,
                isLoading: context.watch<RentalProvider>().isLoading,
                icon: const Icon(Icons.handshake_rounded,
                    color: Colors.white, size: 20),
              ),
            )
          : isOwner
              ? Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.primaryColor, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'This is your tool listing',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
    );
  }
}
