part of "cancellation_token_source.dart";

class LinkedNCancellationTokenSource extends CancellationTokenSource {
  static Future<void> _linkedTokenCancelDelegate(
    CancellationTokenSource? state,
    CancellationToken _,
  ) async {
    await state!._notifyCancellation();
  }

  final List<CancellationTokenRegistration?> _linkingRegistrations;

  @internal
  LinkedNCancellationTokenSource({
    required List<CancellationToken> tokens,
  }) : _linkingRegistrations = List<CancellationTokenRegistration?>.filled(
          tokens.length,
          null,
        ) {
    for (int index = 0; index < tokens.length; ++index) {
      CancellationToken token = tokens[index];
      if (token.canBeCancelled) {
        _linkingRegistrations[index] = token.register<CancellationTokenSource>(
          callback: _linkedTokenCancelDelegate,
          state: this,
        );
      }
    }
  }

  @protected
  @override
  void dispose() {
    if (disposed) {
      return;
    }

    for (CancellationTokenRegistration? registration in _linkingRegistrations) {
      registration?.dispose();
    }

    super.dispose();
  }
}
