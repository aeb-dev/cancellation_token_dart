import "dart:async";

import "package:meta/meta.dart";

import "callback_node.dart";
import "cancellation_token.dart";
import "cancellation_token_registration.dart";
import "exceptions/aggregate_exception.dart";
import "exceptions/object_disposed_exception.dart";
import "registrations.dart";

part "linked_1_cancellation_token_source.dart";
part "linked_2_cancellation_token_source.dart";
part "linked_n_cancellation_token_source.dart";

class CancellationTokenSource {
  @internal
  static CancellationTokenSource cancelled = CancellationTokenSource()
    .._state = _CancellationTokenSourceState.notifyingCompleted;

  @internal
  static CancellationTokenSource neverCancelled = CancellationTokenSource();

  _CancellationTokenSourceState _state =
      _CancellationTokenSourceState.notCancelled;

  @protected
  bool disposed = false;
  Registrations? registrations;
  Timer? _timer;

  bool get isCancellationRequested =>
      _state != _CancellationTokenSourceState.notCancelled;

  bool get isCancellationCompleted =>
      _state == _CancellationTokenSourceState.notifyingCompleted;

  CancellationToken get token {
    _throwIfDisposed();

    return CancellationToken.internal(
      source: this,
    );
  }

  CancellationTokenSource();

  CancellationTokenSource.withDuration({
    required Duration duration,
  }) {
    _initializeWithTimer(duration);
  }

  factory CancellationTokenSource.createLinkedTokenSource({
    required List<CancellationToken> tokens,
  }) {
    CancellationTokenSource result;
    switch (tokens.length) {
      case 0:
        throw ArgumentError("Token size can not be empty");
      case 1:
        CancellationToken token = tokens[0];
        if (token.canBeCancelled) {
          result = Linked1CancellationTokenSource(
            token: token,
          );
        } else {
          result = CancellationTokenSource();
        }
      case 2:
        CancellationToken token1 = tokens[0];
        CancellationToken token2 = tokens[1];

        if (!token1.canBeCancelled) {
          result = Linked1CancellationTokenSource(
            token: token2,
          );
        }

        if (!token2.canBeCancelled) {
          result = Linked1CancellationTokenSource(
            token: token1,
          );
        }

        result = Linked2CancellationTokenSource(
          token1: token1,
          token2: token2,
        );
      default:
        result = LinkedNCancellationTokenSource(
          tokens: tokens,
        );
    }

    return result;
  }

  void _initializeWithTimer(Duration duration) {
    if (duration.inMilliseconds == 0) {
      _state = _CancellationTokenSourceState.notifyingCompleted;
    } else {
      _timer = Timer(duration, _timerCallback);
    }
  }

  Future<void> _timerCallback() async {
    await _notifyCancellation();
  }

  Future<void> cancel({
    bool throwOnFirstException = false,
  }) async {
    _throwIfDisposed();
    await _notifyCancellation(
      throwOnFirstException: throwOnFirstException,
    );
  }

  void cancelAfter({
    required Duration duration,
  }) {
    _throwIfDisposed();

    if (isCancellationRequested) {
      return;
    }

    if (_timer == null) {
      _timer = Timer(
        duration,
        _timerCallback,
      );

      return;
    }

    if (_timer!.isActive) {
      _timer!.cancel();
      _timer = Timer(
        duration,
        _timerCallback,
      );

      return;
    }
  }

  @internal
  CancellationTokenRegistration register<TState>({
    required FutureOr<void> Function(
      TState? state,
      CancellationToken token,
    ) callback,
    TState? state,
  }) {
    if (disposed) {
      return CancellationTokenRegistration.zero;
    }

    registrations ??= Registrations(
      source: this,
    );

    Registrations registrations_ = registrations!;

    CallbackNode<TState> node = CallbackNode<TState>(
      registrations: registrations_,
    )
      ..id = registrations_.nextAvailableId++
      ..next = registrations_.callbacks
      ..callback = callback
      ..callbackState = state;

    node.next?.prev = node;
    registrations_.callbacks = node;

    if (isCancellationRequested) {
      bool unregistered = registrations_.unregister(node: node);
      if (unregistered) {
        Future<void>.sync(() async => callback.call(state, token));
        return CancellationTokenRegistration.zero;
      }
    }

    return CancellationTokenRegistration(
      node: node,
    );
  }

  Future<void> _notifyCancellation({
    bool throwOnFirstException = false,
  }) async {
    if (_state == _CancellationTokenSourceState.notCancelled) {
      _state = _CancellationTokenSourceState.notifying;

      if (_timer != null) {
        if (_timer!.isActive) {
          _timer!.cancel();
        }

        _timer = null;
      }

      await _executeCallbackHandlers(
        throwOnFirstException: throwOnFirstException,
      );
    }
  }

  Future<void> _executeCallbackHandlers({
    bool throwOnFirstException = false,
  }) async {
    Registrations? registrations_ = registrations;
    if (registrations_ == null) {
      _state = _CancellationTokenSourceState.notifyingCompleted;
      return;
    }

    List<Object>? exceptionList;
    while (true) {
      CallbackNodeBase? node = registrations_.callbacks;
      if (node == null) {
        break;
      }

      registrations_
        ..callbacks = node.next
        ..executingCallbackId = node.id;

      node.id = 0;
      node.next?.prev = null;

      try {
        await node.executeCallback();
      } on Object catch (e) {
        if (throwOnFirstException) {
          rethrow;
        }

        exceptionList ??= List<Object>.empty(growable: true);
        exceptionList.add(e);
      }
    }

    _state = _CancellationTokenSourceState.notifyingCompleted;

    if (exceptionList != null) {
      throw AggregateException(exceptionList);
    }
  }

  bool tryReset() {
    _throwIfDisposed();
    if (_state != _CancellationTokenSourceState.notCancelled) {
      return false;
    }

    if (_timer != null) {
      if (_timer!.isActive) {
        _timer!.cancel();
      }
      _timer = null;
    }

    registrations?.unregisterAll();

    return true;
  }

  void dispose() {
    if (_timer != null) {
      if (_timer!.isActive) {
        _timer!.cancel();
      }
      _timer = null;
    }

    registrations = null;
    disposed = true;
  }

  void _throwIfDisposed() {
    if (disposed) {
      throw const ObjectDisposedException();
    }
  }
}

enum _CancellationTokenSourceState {
  notCancelled,
  notifying,
  notifyingCompleted,
}
