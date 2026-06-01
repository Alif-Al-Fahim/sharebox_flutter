import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/rental_model.dart';

class RentalProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<RentalModel> _myRentals = [];
  List<RentalModel> _rentalsAsOwner = [];
  bool _isLoading = false;
  String? _error;

  List<RentalModel> get myRentals => _myRentals;
  List<RentalModel> get rentalsAsOwner => _rentalsAsOwner;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RentalModel> get pendingRentals =>
      _rentalsAsOwner.where((r) => r.status == RentalStatus.pending).toList();

  List<RentalModel> get activeRentals =>
      _myRentals.where((r) => r.status == RentalStatus.active).toList();

  // Load rentals as renter
  void loadMyRentals(String userId) {
    _firestoreService.streamRentalsAsRenter(userId).listen((rentals) {
      _myRentals = rentals;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load rentals.';
      notifyListeners();
    });
  }

  // Load rentals as owner
  void loadRentalsAsOwner(String userId) {
    _firestoreService.streamRentalsAsOwner(userId).listen((rentals) {
      _rentalsAsOwner = rentals;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load rental requests.';
      notifyListeners();
    });
  }

  // Create rental request
  Future<bool> createRentalRequest({
    required String toolId,
    required String toolName,
    String? toolImage,
    required String ownerId,
    required String ownerName,
    required String renterId,
    required String renterName,
    required DateTime startDate,
    required DateTime endDate,
    required double pricePerDay,
    String? message,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final durationDays = endDate.difference(startDate).inDays + 1;
      final totalPrice = pricePerDay * durationDays;

      final rental = RentalModel(
        id: '',
        toolId: toolId,
        toolName: toolName,
        toolImage: toolImage,
        ownerId: ownerId,
        ownerName: ownerName,
        renterId: renterId,
        renterName: renterName,
        status: RentalStatus.pending,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        pricePerDay: pricePerDay,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createRental(rental);
      return true;
    } catch (e) {
      _error = 'Failed to send rental request.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Accept rental
  Future<bool> acceptRental(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.accepted);
  }

  // Mark as active
  Future<bool> markAsActive(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.active);
  }

  // Complete rental
  Future<bool> completeRental(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.completed);
  }

  // Cancel rental
  Future<bool> cancelRental(String rentalId) async {
    return await _updateRentalStatus(rentalId, RentalStatus.cancelled);
  }

  Future<bool> _updateRentalStatus(
      String rentalId, RentalStatus status) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService.updateRentalStatus(rentalId, status);
      return true;
    } catch (e) {
      _error = 'Failed to update rental status.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
