import "dart:async";

import "cancellation_token.dart";
import "registrations.dart";

class CallbackNode<TState> extends CallbackNodeBase {
  FutureOr<void> Function(
    TState? state,
    CancellationToken token,
  )? callback;
  TState? callbackState;

  CallbackNode({
    required super.registrations,
  });

  @override
  FutureOr<void> executeCallback() async {
    await callback?.call(
      callbackState,
      registrations.source.token,
    );
  }

  @override
  void clean() {
    id = 0;
    callback = null;
    callbackState = null;
  }
}

abstract class CallbackNodeBase {
  int id = 0;

  final Registrations registrations;

  CallbackNodeBase? prev;
  CallbackNodeBase? next;

  CallbackNodeBase({
    required this.registrations,
  });

  FutureOr<void> executeCallback();

  void clean();
}
