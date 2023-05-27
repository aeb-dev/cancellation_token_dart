part of "cancellation_token_source.dart";

class Linked2CancellationTokenSource extends CancellationTokenSource {
  late CancellationTokenRegistration _reg1;
  late CancellationTokenRegistration _reg2;

  @internal
  Linked2CancellationTokenSource({
    required CancellationToken token1,
    required CancellationToken token2,
  }) {
    _reg1 = token1.register(
      callback: LinkedNCancellationTokenSource._linkedTokenCancelDelegate,
      state: this,
    );
    _reg2 = token2.register(
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

    _reg1.dispose();
    _reg2.dispose();

    super.dispose();
  }
}
