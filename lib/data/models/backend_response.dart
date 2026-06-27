class BackendResponse<T> {
  final T data;
  final String? message;
  final bool success;

  BackendResponse({
    required this.data,
    this.message,
    this.success = true,
  });

  factory BackendResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return BackendResponse(
      data: fromJsonT(json['data']),
      message: json['message'] as String?,
      success: json['success'] as bool? ?? true,
    );
  }
}

class PaginationResponse<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  PaginationResponse({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory PaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PaginationResponse(
      data: (json['data'] as List<dynamic>).map((e) => fromJsonT(e)).toList(),
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 20,
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }

  bool get hasMore => currentPage < lastPage;
}
