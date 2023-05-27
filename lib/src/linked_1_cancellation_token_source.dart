part of "cancellation_token_source.dart";

class Linked1CancellationTokenSource extends CancellationTokenSource {
  late CancellationTokenRegistration _reg;

  @internal
  Linked1CancellationTokenSource({
    required CancellationToken token,
  }) {
    _reg = token.register(
      callback: LinkedNCancellationTokenSource._linkedTokenCancelDelegate,
      state: this,
    );
  }

  @protected
  @override
  void dispose() {
    if (disposed) {
      return;
    }

    _reg.dispose();

    super.dispose();
  }
}
