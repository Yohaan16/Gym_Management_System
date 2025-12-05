/// API response wrapper for standardized responses
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Success',
    );
  }

  factory ApiResponse.error(String message, {dynamic error}) {
    return ApiResponse(
      success: false,
      message: message,
      error: error,
    );
  }

  factory ApiResponse.loading() {
    return ApiResponse(
      success: false,
      message: 'Loading',
    );
  }
}

/// Repository interface for consistency
abstract class BaseRepository {
  /// Get single item
  Future<ApiResponse<T>> getItem<T>(String id);

  /// Get all items
  Future<ApiResponse<List<T>>> getItems<T>();

  /// Create item
  Future<ApiResponse<T>> createItem<T>(T item);

  /// Update item
  Future<ApiResponse<T>> updateItem<T>(T item);

  /// Delete item
  Future<ApiResponse<bool>> deleteItem<T>(String id);
}
