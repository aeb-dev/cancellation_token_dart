import "package:meta/meta.dart";

import "callback_node.dart";
import "cancellation_token.dart";

@immutable
class CancellationTokenRegistration {
  final CallbackNodeBase? _node;

  CancellationToken get token => _node != null
      ? CancellationToken.internal(
          source: _node!.registrations.source,
        )
      : CancellationToken.none;

  @internal
  static const CancellationTokenRegistration zero =
      CancellationTokenRegistration.withoutNode();

  const CancellationTokenRegistration({
    required CallbackNodeBase node,
  }) : _node = node;

  @internal
  const CancellationTokenRegistration.withoutNode() : _node = null;

  void dispose() {
    unregister();
  }

  bool unregister() {
    CallbackNodeBase? node = _node;
    if (node == null) {
      return false;
    }

    bool unregistered = node.registrations.unregister(
      node: node,
    );

    return unregistered;
  }
}
