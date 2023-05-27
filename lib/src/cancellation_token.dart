import "dart:async";

import "package:meta/meta.dart";

import "cancellation_token_registration.dart";
import "cancellation_token_source.dart";
import "exceptions/operation_cancelled_exception.dart";

@immutable
class CancellationToken {
  final CancellationTokenSource? _source;

  bool get isCancellationRequested =>
      _source != null && _source!.isCancellationRequested;

  bool get canBeCancelled => _source != null;

  static const CancellationToken none = CancellationToken.internal(
    source: null,
  );

  CancellationToken({
    bool cancelled = false,
  }) : this.internal(
          source: cancelled ? CancellationTokenSource.cancelled : null,
        );

  @internal
  const CancellationToken.internal({
    required CancellationTokenSource? source,
  }) : _source = source;

  CancellationTokenRegistration register<TState>({
    required FutureOr<void> Function(TState? state, CancellationToken token)
        callback,
    TState? state,
  }) {
    CancellationTokenSource? source = _source;
    if (source == null) {
      return CancellationTokenRegistration.zero;
    }

    return source.register(
      callback: callback,
      state: state,
    );
  }

  void throwIfCancellationRequested() {
    if (isCancellationRequested) {
      throw OperationCancelledException(
        reason: "The operation was canceled",
        cancellationToken: this,
      );
    }
  }

  @override
  int get hashCode =>
      (_source ?? CancellationTokenSource.neverCancelled).hashCode;

  @override
  bool operator ==(Object other) =>
      other is CancellationToken && other._source == _source;
}
