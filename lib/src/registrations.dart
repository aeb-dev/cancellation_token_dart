import "callback_node.dart";
import "cancellation_token_source.dart";

class Registrations {
  final CancellationTokenSource source;
  CallbackNodeBase? callbacks;
  int nextAvailableId = 1;
  int executingCallbackId = 0;

  Registrations({
    required this.source,
  });

  bool unregister({
    required CallbackNodeBase node,
  }) {
    if (node.id == 0) {
      return false;
    }

    if (callbacks == node) {
      callbacks = node.next;
    } else {
      node.prev!.next = node.next;
    }

    if (node.next != null) {
      node.next!.prev = node.prev;
    }

    node.clean();

    return true;
  }

  void unregisterAll() {
    CallbackNodeBase? node = callbacks;
    callbacks = null;

    while (node != null) {
      CallbackNodeBase? next = node.next;
      node.clean();
      node = next;
    }
  }
}
