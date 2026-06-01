import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool_model.dart';
import '../models/rental_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── TOOLS ───────────────────────────────────────────────────────────────

  // Add a new tool
  Future<String> addTool(ToolModel tool) async {
    final docRef = await _firestore.collection('tools').add(tool.toMap());
    return docRef.id;
  }

  // Update a tool
  Future<void> updateTool(String toolId, Map<String, dynamic> data) async {
    await _firestore.collection('tools').doc(toolId).update(data);
  }

  // Delete a tool
  Future<void> deleteTool(String toolId) async {
    await _firestore.collection('tools').doc(toolId).delete();
  }

  // Get a single tool
  Future<ToolModel?> getTool(String toolId) async {
    final doc = await _firestore.collection('tools').doc(toolId).get();
    if (doc.exists) return ToolModel.fromFirestore(doc);
    return null;
  }

  // Stream all available tools
  Stream<List<ToolModel>> streamAvailableTools() {
    return _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList());
  }

  // Stream tools by category
  Stream<List<ToolModel>> streamToolsByCategory(ToolCategory category) {
    return _firestore
        .collection('tools')
        .where('category', isEqualTo: category.name)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList());
  }

  // Stream tools by owner
  Stream<List<ToolModel>> streamToolsByOwner(String ownerId) {
    return _firestore
        .collection('tools')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList());
  }

  // Search tools by name
  Future<List<ToolModel>> searchTools(String query) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .get();

    final tools =
        snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList();

    return tools
        .where((tool) =>
            tool.name.toLowerCase().contains(query.toLowerCase()) ||
            tool.description.toLowerCase().contains(query.toLowerCase()) ||
            tool.location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Toggle tool availability
  Future<void> toggleToolAvailability(String toolId, bool isAvailable) async {
    await _firestore
        .collection('tools')
        .doc(toolId)
        .update({'isAvailable': isAvailable});
  }

  // ─── RENTALS ─────────────────────────────────────────────────────────────

  // Create a rental request
  Future<String> createRental(RentalModel rental) async {
    final docRef = await _firestore.collection('rentals').add(rental.toMap());
    return docRef.id;
  }

  // Update rental status
  Future<void> updateRentalStatus(String rentalId, RentalStatus status) async {
    await _firestore
        .collection('rentals')
        .doc(rentalId)
        .update({'status': status.name});
  }

  // Stream rentals as renter
  Stream<List<RentalModel>> streamRentalsAsRenter(String renterId) {
    return _firestore
        .collection('rentals')
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalModel.fromFirestore(doc))
            .toList());
  }

  // Stream rentals as owner
  Stream<List<RentalModel>> streamRentalsAsOwner(String ownerId) {
    return _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalModel.fromFirestore(doc))
            .toList());
  }

  // Get rental by id
  Future<RentalModel?> getRental(String rentalId) async {
    final doc = await _firestore.collection('rentals').doc(rentalId).get();
    if (doc.exists) return RentalModel.fromFirestore(doc);
    return null;
  }

  // ─── USERS ───────────────────────────────────────────────────────────────

  // Get user by id
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  // Stream user
  Stream<UserModel?> streamUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Toggle favorite tool
  Future<void> toggleFavoriteTool(String userId, String toolId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final favorites = List<String>.from(data['favoriteTools'] ?? []);

    if (favorites.contains(toolId)) {
      favorites.remove(toolId);
    } else {
      favorites.add(toolId);
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .update({'favoriteTools': favorites});
  }

  // Stream favorite tools
  Stream<List<ToolModel>> streamFavoriteTools(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap(
      (userDoc) async {
        if (!userDoc.exists) return [];
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final favorites = List<String>.from(data['favoriteTools'] ?? []);
        if (favorites.isEmpty) return [];

        final toolSnapshots = await Future.wait(
          favorites.map((id) => _firestore.collection('tools').doc(id).get()),
        );

        return toolSnapshots
            .where((doc) => doc.exists)
            .map((doc) => ToolModel.fromFirestore(doc))
            .toList();
      },
    );
  }

  // ─── STATS ───────────────────────────────────────────────────────────────

  // Get tool stats
  Future<Map<String, int>> getToolStats(String ownerId) async {
    final toolsSnapshot = await _firestore
        .collection('tools')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    final rentalsSnapshot = await _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return {
      'totalTools': toolsSnapshot.docs.length,
      'totalRentals': rentalsSnapshot.docs.length,
      'activeRentals': rentalsSnapshot.docs
          .where((doc) =>
              (doc.data()['status'] as String?) == RentalStatus.active.name)
          .length,
    };
  }
}
