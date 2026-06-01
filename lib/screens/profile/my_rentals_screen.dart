import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rental_provider.dart';
import '../../models/rental_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_indicator.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: const Text(
            'My Rentals',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'As Renter'),
            Tab(text: 'As Owner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Renter view
          rentalProvider.myRentals.isEmpty
              ? const EmptyState(
                  title: 'No Rentals Yet',
                  subtitle: 'Tools you rent will appear here.',
                  icon: Icons.receipt_long_outlined,
                )
              : _RentalList(
                  rentals: rentalProvider.myRentals,
                  isOwner: false,
                ),
          // Owner view
          rentalProvider.rentalsAsOwner.isEmpty
              ? const EmptyState(
                  title: 'No Requests Yet',
                  subtitle: 'Rental requests for your tools will appear here.',
                  icon: Icons.inbox_outlined,
                )
              : _RentalList(
                  rentals: rentalProvider.rentalsAsOwner,
                  isOwner: true,
                ),
        ],
      ),
    );
  }
}

class _RentalList extends StatelessWidget {
  final List<RentalModel> rentals;
  final bool isOwner;

  const _RentalList({required this.rentals, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rentals.length,
      itemBuilder: (ctx, i) => _RentalCard(rental: rentals[i], isOwner: isOwner),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final RentalModel rental;
  final bool isOwner;

  const _RentalCard({required this.rental, required this.isOwner});

  Color get _statusColor {
    switch (rental.status) {
      case RentalStatus.pending:
        return AppTheme.warningColor;
      case RentalStatus.accepted:
        return AppTheme.primaryColor;
      case RentalStatus.active:
        return AppTheme.secondaryColor;
      case RentalStatus.completed:
        return AppTheme.successColor;
      case RentalStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final rentalProvider = context.read<RentalProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rental.toolName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    '${rental.status.emoji} ${rental.status.displayName}',
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _InfoRow(
                  label: isOwner ? 'Renter' : 'Owner',
                  value: isOwner ? rental.renterName : rental.ownerName,
                  icon: Icons.person_outlined,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Dates',
                  value:
                      '${fmt.format(rental.startDate)} → ${fmt.format(rental.endDate)}',
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Duration',
                  value: '${rental.durationDays} day${rental.durationDays > 1 ? 's' : ''}',
                  icon: Icons.timelapse_rounded,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Total Amount',
                  value: rental.formattedTotalPrice,
                  icon: Icons.currency_exchange_rounded,
                  valueStyle: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (rental.message != null && rental.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Message',
                    value: rental.message!,
                    icon: Icons.message_outlined,
                  ),
                ],

                // Owner action buttons
                if (isOwner && rental.status == RentalStatus.pending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await rentalProvider.cancelRental(rental.id);
                          },
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: AppTheme.errorColor),
                          label: const Text('Decline',
                              style: TextStyle(color: AppTheme.errorColor)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await rentalProvider.acceptRental(rental.id);
                          },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],

                // Renter cancel button
                if (!isOwner && rental.status == RentalStatus.pending) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await rentalProvider.cancelRental(rental.id);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.errorColor),
                        foregroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
