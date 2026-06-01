import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool_model.dart';
import '../models/rental_model.dart';

/// AI-Ready Recommendation Service
/// 
/// Currently implements rule-based recommendations using:
/// - Category matching from user's rental history
/// - Location-based filtering
/// - Recent activity patterns
///
/// Future integration points:
/// - Replace [_computeRecommendations] with ML model API call
/// - Add collaborative filtering (users with similar rentals)
/// - Add embedding-based semantic search
/// - Integrate with Vertex AI or OpenAI Embeddings API
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Main recommendation entry point
  Future<List<ToolModel>> getRecommendedTools(String userId) async {
    try {
      final userActivity = await _getUserActivity(userId);
      final userLocation = await _getUserLocation(userId);
      final allTools = await _getAvailableTools(userId);

      return _computeRecommendations(
        tools: allTools,
        userActivity: userActivity,
        userLocation: userLocation,
        userId: userId,
      );
    } catch (e) {
      // Fallback to recent tools on error
      return _getRecentTools(userId);
    }
  }

  // Get tools similar to a specific tool
  Future<List<ToolModel>> getSimilarTools(ToolModel tool, {int limit = 5}) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('category', isEqualTo: tool.category.name)
        .where('isAvailable', isEqualTo: true)
        .limit(10)
        .get();

    final tools = snapshot.docs
        .map((doc) => ToolModel.fromFirestore(doc))
        .where((t) => t.id != tool.id)
        .toList();

    // Sort by price similarity
    tools.sort((a, b) {
      final diffA = (a.pricePerDay - tool.pricePerDay).abs();
      final diffB = (b.pricePerDay - tool.pricePerDay).abs();
      return diffA.compareTo(diffB);
    });

    return tools.take(limit).toList();
  }

  // Get trending tools (most rented recently)
  Future<List<ToolModel>> getTrendingTools({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .orderBy('totalRentals', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList();
  }

  // Get tools by price range
  Future<List<ToolModel>> getToolsByPriceRange({
    required double minPrice,
    required double maxPrice,
    String? userId,
  }) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .where('pricePerDay', isGreaterThanOrEqualTo: minPrice)
        .where('pricePerDay', isLessThanOrEqualTo: maxPrice)
        .get();

    var tools = snapshot.docs.map((doc) => ToolModel.fromFirestore(doc)).toList();

    // Exclude user's own tools
    if (userId != null) {
      tools = tools.where((t) => t.ownerId != userId).toList();
    }

    return tools;
  }

  // ─── PRIVATE METHODS ─────────────────────────────────────────────────────

  /// Retrieve user's rental history to determine preferred categories
  Future<_UserActivity> _getUserActivity(String userId) async {
    final rentalsSnapshot = await _firestore
        .collection('rentals')
        .where('renterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final rentals = rentalsSnapshot.docs
        .map((doc) => RentalModel.fromFirestore(doc))
        .toList();

    // Extract preferred categories from rental history
    final categoryCount = <String, int>{};
    for (final rental in rentals) {
      final toolDoc = await _firestore.collection('tools').doc(rental.toolId).get();
      if (toolDoc.exists) {
        final category = toolDoc.data()?['category'] as String?;
        if (category != null) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }
    }

    // Sort categories by frequency
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _UserActivity(
      preferredCategories: sortedCategories.map((e) => e.key).toList(),
      recentRentalCount: rentals.length,
    );
  }

  /// Get user's location for proximity-based recommendations
  Future<String?> _getUserLocation(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['location'] as String?;
    }
    return null;
  }

  /// Get all available tools excluding user's own
  Future<List<ToolModel>> _getAvailableTools(String userId) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => ToolModel.fromFirestore(doc))
        .where((t) => t.ownerId != userId)
        .toList();
  }

  /// Core recommendation algorithm
  /// 
  /// Scoring system (0–100):
  /// - Category match:  40 pts
  /// - Same location:   30 pts
  /// - High rating:     20 pts
  /// - Recency:         10 pts
  ///
  /// TODO: Replace with vector similarity scoring when AI model is integrated
  List<ToolModel> _computeRecommendations({
    required List<ToolModel> tools,
    required _UserActivity userActivity,
    required String? userLocation,
    required String userId,
  }) {
    final scoredTools = tools.map((tool) {
      double score = 0;

      // Category match score (0–40)
      final catIndex = userActivity.preferredCategories.indexOf(tool.category.name);
      if (catIndex == 0) score += 40;
      else if (catIndex == 1) score += 30;
      else if (catIndex >= 2) score += 15;

      // Location match score (0–30)
      if (userLocation != null && userLocation.isNotEmpty) {
        final toolLoc = tool.location.toLowerCase();
        final userLoc = userLocation.toLowerCase();
        if (toolLoc == userLoc) {
          score += 30;
        } else if (toolLoc.contains(userLoc) || userLoc.contains(toolLoc)) {
          score += 15;
        }
      }

      // Rating score (0–20)
      if (tool.rating != null) {
        score += (tool.rating! / 5) * 20;
      }

      // Recency score (0–10) — newer tools get slight boost
      final daysSinceCreated = DateTime.now().difference(tool.createdAt).inDays;
      if (daysSinceCreated < 7) score += 10;
      else if (daysSinceCreated < 30) score += 5;

      return _ScoredTool(tool: tool, score: score);
    }).toList();

    scoredTools.sort((a, b) => b.score.compareTo(a.score));

    // If no activity history, return random sample
    if (userActivity.preferredCategories.isEmpty) {
      scoredTools.shuffle();
    }

    return scoredTools.map((s) => s.tool).take(20).toList();
  }

  /// Fallback: Get most recent available tools
  Future<List<ToolModel>> _getRecentTools(String userId) async {
    final snapshot = await _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => ToolModel.fromFirestore(doc))
        .where((t) => t.ownerId != userId)
        .toList();
  }
}

/// Internal model for user activity analysis
class _UserActivity {
  final List<String> preferredCategories;
  final int recentRentalCount;

  _UserActivity({
    required this.preferredCategories,
    required this.recentRentalCount,
  });
}

/// Internal model for scored tool recommendations
class _ScoredTool {
  final ToolModel tool;
  final double score;

  _ScoredTool({required this.tool, required this.score});
}
