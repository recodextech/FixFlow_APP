/// A worker's rating summary from `GET /workers/{workerId}/rating`.
///
/// [rating] is 5 for a worker nobody has rated yet, so use [hasRatings]
/// (ratingCount > 0) to tell a real 5.0 from "no ratings".
class WorkerRating {
  final String workerId;
  final double rating;
  final int ratingCount;
  final String lastRatedAt;

  const WorkerRating({
    required this.workerId,
    this.rating = 5,
    this.ratingCount = 0,
    this.lastRatedAt = '',
  });

  bool get hasRatings => ratingCount > 0;

  factory WorkerRating.fromJson(Map<String, dynamic> json) {
    return WorkerRating(
      workerId: (json['workerId'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      lastRatedAt: (json['lastRatedAt'] ?? '').toString(),
    );
  }
}
