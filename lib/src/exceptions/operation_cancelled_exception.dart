import "../cancellation_token.dart";

class OperationCancelledException implements Exception {
  final String? reason;

  final CancellationToken cancellationToken;

  const OperationCancelledException({
    required this.cancellationToken,
    this.reason,
  });
}
