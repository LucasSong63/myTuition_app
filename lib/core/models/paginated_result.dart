// lib/core/models/paginated_result.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// A generic class to represent paginated results from Firestore.
class PaginatedResult<T> {
  /// The items returned in this page.
  final List<T> items;

  /// The last document in the current batch, used for pagination.
  final DocumentSnapshot? lastDocument;

  /// Whether there are more items to load.
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });
}
