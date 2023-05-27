// ignore_for_file: prefer_function_declarations_over_variables

import "dart:async";

import "package:cancellation_token_dotnet/cancellation_token_dotnet.dart";
import "package:test/test.dart";

void main() {
  group(
    "cancellation token equality",
    () {
      test("simple empty token comparisons", () {
        CancellationToken token1 = CancellationToken();
        CancellationToken token2 = CancellationToken();

        expect(token1, equals(token2));
      });

      test("inflated empty token comparisons", () {
        CancellationToken inflatedEmptyCt1 = CancellationToken();
        // ignore: unused_local_variable
        bool temp1 = inflatedEmptyCt1.canBeCancelled;

        CancellationToken inflatedEmptyCt2 = CancellationToken();
        // ignore: unused_local_variable
        bool temp2 = inflatedEmptyCt2.canBeCancelled;

        expect(inflatedEmptyCt1, equals(CancellationToken()));
        expect(CancellationToken(), equals(inflatedEmptyCt1));
        expect(inflatedEmptyCt1, equals(inflatedEmptyCt2));
      });

      test("inflated pre-set token comparisons", () {
        CancellationToken inflatedDefaultsetCt1 =
            CancellationToken(cancelled: true);

        // ignore: unused_local_variable
        bool temp1 = inflatedDefaultsetCt1.canBeCancelled;
        CancellationToken inflatedDefaultsetCt2 =
            CancellationToken(cancelled: true);
        // ignore: unused_local_variable
        bool temp2 = inflatedDefaultsetCt2.canBeCancelled;

        expect(
          inflatedDefaultsetCt1,
          equals(CancellationToken(cancelled: true)),
        );
        expect(inflatedDefaultsetCt1, equals(inflatedDefaultsetCt2));
      });

      test("things that are not equal", () {
        CancellationToken inflatedEmptyCt1 = CancellationToken();
        // ignore: unused_local_variable
        bool temp1 = inflatedEmptyCt1.canBeCancelled;
        CancellationToken inflatedDefaultsetCt2 =
            CancellationToken(cancelled: true);
        // ignore: unused_local_variable
        bool temp2 = inflatedDefaultsetCt2.canBeCancelled;

        expect(inflatedEmptyCt1, isNot(equals(inflatedDefaultsetCt2)));
        expect(
          inflatedEmptyCt1,
          isNot(equals(CancellationToken(cancelled: true))),
        );
        expect(
          CancellationToken(cancelled: true),
          isNot(equals(inflatedEmptyCt1)),
        );
      });
    },
  );

  group(
    "cancellation token get hash code",
    () {
      test("", () {
        CancellationTokenSource cts = CancellationTokenSource();
        CancellationToken ct = cts.token;
        int hash1 = cts.hashCode;
        int hash2 = cts.token.hashCode;
        int hash3 = ct.hashCode;

        expect(hash1, hash2);
        expect(hash2, hash3);

        CancellationToken defaultUnsetToken1 = CancellationToken();
        CancellationToken defaultUnsetToken2 = CancellationToken();
        int hashDefaultUnset1 = defaultUnsetToken1.hashCode;
        int hashDefaultUnset2 = defaultUnsetToken2.hashCode;
        expect(hashDefaultUnset1, hashDefaultUnset2);

        CancellationToken defaultSetToken1 = CancellationToken(cancelled: true);
        CancellationToken defaultSetToken2 = CancellationToken(cancelled: true);
        int hashDefaultSet1 = defaultSetToken1.hashCode;
        int hashDefaultSet2 = defaultSetToken2.hashCode;
        expect(hashDefaultSet1, hashDefaultSet2);

        expect(hash1, isNot(equals(hashDefaultUnset1)));
        expect(hash1, isNot(equals(hashDefaultSet1)));
        expect(hashDefaultUnset1, isNot(equals(hashDefaultSet1)));
      });
    },
  );

  group(
    "cancellation token equality and dispose",
    () {
      late CancellationTokenSource cts;
      setUp(() {
        cts = CancellationTokenSource()..dispose();
      });

      test("hash code", () {
        expect(
          () => cts.token.hashCode,
          throwsA(isA<ObjectDisposedException>()),
        );
      });

      test("==", () {
        expect(
          () => cts.token == CancellationToken(),
          throwsA(isA<ObjectDisposedException>()),
        );
        expect(
          () => cts.token != CancellationToken(),
          throwsA(isA<ObjectDisposedException>()),
        );

        expect(
          () => CancellationToken() == cts.token,
          throwsA(isA<ObjectDisposedException>()),
        );
        expect(
          () => CancellationToken() != cts.token,
          throwsA(isA<ObjectDisposedException>()),
        );
      });
    },
  );

  group(
    "token source dispose",
    () {
      test("", () {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        CancellationTokenRegistration preDisposeRegistration =
            token.register(callback: (_, __) {});

        tokenSource.dispose();

        expect(() => preDisposeRegistration.dispose(), returnsNormally);
        expect(() => tokenSource.isCancellationRequested, returnsNormally);
        expect(() => tokenSource.dispose(), returnsNormally);
      });

      test("negative", () {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        CancellationTokenRegistration preDisposeRegistration =
            token.register(callback: (_, __) {});

        tokenSource.dispose();

        expect(
          () => tokenSource.token,
          throwsA(isA<ObjectDisposedException>()),
        );
        expect(() => token.register(callback: (_, __) {}), returnsNormally);
        expect(() => preDisposeRegistration.dispose(), returnsNormally);
        expect(
          () => CancellationTokenSource.createLinkedTokenSource(
            tokens: <CancellationToken>[
              token,
            ],
          ),
          returnsNormally,
        );
      });
    },
  );

  group(
    "cancellation token passive listening",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        expect(token.isCancellationRequested, isFalse);
        await tokenSource.cancel();
        expect(token.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "cancellation token active listening",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        bool signalReceived = false;
        token.register(callback: (_, __) => signalReceived = true);

        expect(signalReceived, isFalse);
        await tokenSource.cancel();
        expect(signalReceived, isTrue);
      });
    },
  );

  group(
    "add and remove delegates",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;
        List<String> output = List<String>.empty(growable: true);

        void Function(Object? state, CancellationToken token) action1 =
            (_, __) => output.add("action1");
        void Function(Object? state, CancellationToken token) action2 =
            (_, __) => output.add("action2");

        // ignore: unused_local_variable
        CancellationTokenRegistration reg1 = token.register(callback: action1);
        CancellationTokenRegistration reg2 = token.register(callback: action2);
        CancellationTokenRegistration reg3 = token.register(callback: action2);
        CancellationTokenRegistration reg4 = token.register(callback: action1);

        reg2.dispose();
        reg3.dispose();
        reg4.dispose();
        await tokenSource.cancel();

        expect(1, equals(output.length));
        expect("action1", equals(output[0]));
      });
    },
  );

  group(
    "cancellation token late enlistment",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;
        bool signalReceived = false;
        await tokenSource.cancel(); //Signal

        //Late enlist.. should fire the delegate synchronously
        token.register(callback: (_, __) => signalReceived = true);

        expect(signalReceived, isTrue);
      });
    },
  );

  group(
    "create linked token source one token",
    () {
      test("", () async {
        CancellationTokenSource original = CancellationTokenSource();

        CancellationTokenSource linked =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            original.token,
          ],
        );
        expect(linked.token.isCancellationRequested, isFalse);
        await original.cancel();
        expect(linked.token.isCancellationRequested, isTrue);

        original = CancellationTokenSource();
        linked = CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            original.token,
          ],
        );
        expect(linked.token.isCancellationRequested, isFalse);
        await linked.cancel();
        expect(linked.token.isCancellationRequested, isTrue);
        expect(original.isCancellationRequested, isFalse);

        original = CancellationTokenSource();
        linked = CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            original.token,
          ],
        );
        expect(linked.token.isCancellationRequested, isFalse);
        original.dispose();
        expect(linked.token.isCancellationRequested, isFalse);
      });
    },
  );

  group(
    "create linked token source simple two token",
    () {
      test("", () async {
        CancellationTokenSource signal1 = CancellationTokenSource();
        CancellationTokenSource signal2 = CancellationTokenSource();

        // Neither token is signalled.
        CancellationTokenSource combined =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            signal1.token,
            signal2.token,
          ],
        );
        expect(combined.isCancellationRequested, isFalse);

        await signal1.cancel();
        expect(combined.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "create linked token source simple multi token",
    () {
      test("", () async {
        CancellationTokenSource signal1 = CancellationTokenSource();
        CancellationTokenSource signal2 = CancellationTokenSource();
        CancellationTokenSource signal3 = CancellationTokenSource();

        // Neither token is signalled.
        CancellationTokenSource combined =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            signal1.token,
            signal2.token,
            signal3.token,
          ],
        );
        expect(combined.isCancellationRequested, isFalse);

        await signal1.cancel();
        expect(combined.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "create linked token source token already signalled one token",
    () {
      test("", () async {
        //creating a combined token, when a source token is already signaled.
        CancellationTokenSource signal = CancellationTokenSource();

        await signal.cancel(); //early signal.

        CancellationTokenSource combined =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            signal.token,
          ],
        );
        expect(combined.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "create linked token source token already signalled two tokens",
    () {
      test("", () async {
        //creating a combined token, when a source token is already signaled.
        CancellationTokenSource signal1 = CancellationTokenSource();
        CancellationTokenSource signal2 = CancellationTokenSource();

        await signal1.cancel(); //early signal.

        CancellationTokenSource combined =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            signal1.token,
            signal2.token,
          ],
        );
        expect(combined.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "create linked token multistep composition source token already signalled",
    () {
      test("", () async {
        //two-step composition
        CancellationTokenSource signal1 = CancellationTokenSource();
        await signal1.cancel(); //early signal.

        CancellationTokenSource signal2 = CancellationTokenSource();
        CancellationTokenSource combined1 =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            signal1.token,
            signal2.token,
          ],
        );

        CancellationTokenSource signal3 = CancellationTokenSource();
        CancellationTokenSource combined2 =
            CancellationTokenSource.createLinkedTokenSource(
          tokens: <CancellationToken>[
            signal3.token,
            combined1.token,
          ],
        );

        expect(combined2.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "callback order is lifo",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        List<String> callbackOutput = List<String>.empty(growable: true);
        token
          ..register(callback: (_, __) => callbackOutput.add("Callback1"))
          ..register(callback: (_, __) => callbackOutput.add("Callback2"));

        await tokenSource.cancel();
        expect("Callback2", equals(callbackOutput[0]));
        expect("Callback1", equals(callbackOutput[1]));
      });
    },
  );

  group(
    "enlist early and late",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        CancellationTokenSource earlyEnlistedTokenSource =
            CancellationTokenSource();

        token.register(callback: (_, __) => earlyEnlistedTokenSource.cancel());
        await tokenSource.cancel();

        expect(earlyEnlistedTokenSource.isCancellationRequested, isTrue);

        CancellationTokenSource lateEnlistedTokenSource =
            CancellationTokenSource();
        token.register(callback: (_, __) => lateEnlistedTokenSource.cancel());
        expect(lateEnlistedTokenSource.isCancellationRequested, isTrue);
      });
    },
  );

  group(
    "cancel throw on first exception",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        FormatException? caughtException;
        token
          ..register(callback: (_, __) => throw TimeoutException(""))
          ..register(
            callback: (_, __) => throw const FormatException(),
          ); // !!NOTE: Due to LIFO ordering, this delegate should be the only one to run.

        Future<void> f = Future<void>.microtask(() async {
          try {
            await tokenSource.cancel(throwOnFirstException: true);
          } on FormatException catch (ex) {
            caughtException = ex;
          } on Object catch (_) {
            expect(false, isTrue); // should not come here
          }
        });

        await f;

        expect(caughtException, isNotNull);
      });
    },
  );

  group(
    "cancel don't throw on first exception",
    () {
      test("", () async {
        CancellationTokenSource tokenSource = CancellationTokenSource();
        CancellationToken token = tokenSource.token;

        AggregateException? caughtException;
        token
          ..register(callback: (_, __) => throw TimeoutException(""))
          ..register(
            callback: (_, __) => throw const FormatException(),
          );

        Future<void> f = Future<void>.microtask(() async {
          try {
            await tokenSource.cancel();
          } on AggregateException catch (ex) {
            caughtException = ex;
          }
        });

        await f;

        expect(caughtException, isNotNull);
        expect(2, equals(caughtException!.exceptionList.length));
        expect(
          caughtException!.exceptionList[0],
          isA<FormatException>(),
        );
        expect(
          caughtException!.exceptionList[1],
          isA<TimeoutException>(),
        );
      });
    },
  );

  group(
    "cancellation registration repeat dispose",
    () {
      test(
        "",
        () {
          Exception? caughtException;

          CancellationTokenSource cts = CancellationTokenSource();
          CancellationToken ct = cts.token;

          CancellationTokenRegistration registration =
              ct.register(callback: (_, __) {});
          try {
            registration
              ..dispose()
              ..dispose();
          } on Exception catch (ex) {
            caughtException = ex;
          }

          expect(caughtException, isNull);
        },
      );
    },
  );

  group(
    "cancellation token registration equality and hash code",
    () {
      late CancellationTokenSource outerCts;
      setUp(() {
        outerCts = CancellationTokenSource();
      });

      test(
        "different registrations on 'different' default tokens",
        () {
          CancellationToken ct1 = CancellationToken();
          CancellationToken ct2 = CancellationToken();

          CancellationTokenRegistration ctr1 =
              ct1.register(callback: (_, __) async => outerCts.cancel());
          CancellationTokenRegistration ctr2 =
              ct2.register(callback: (_, __) async => outerCts.cancel());

          expect(ctr1 == ctr2, isTrue);
          expect(ctr1 != ctr2, isFalse);
          expect(ctr1.hashCode == ctr2.hashCode, isTrue);
        },
      );

      test(
        "different registrations on the same already cancelled token",
        () async {
          CancellationTokenSource cts = CancellationTokenSource();
          await cts.cancel();
          CancellationToken ct = cts.token;

          CancellationTokenRegistration ctr1 =
              ct.register(callback: (_, __) => outerCts.cancel());
          CancellationTokenRegistration ctr2 =
              ct.register(callback: (_, __) => outerCts.cancel());

          expect(ctr1 == ctr2, isTrue);
          expect(ctr1 != ctr2, isFalse);
          expect(ctr1.hashCode == ctr2.hashCode, isTrue);
        },
      );

      test(
        "different registrations on one real token",
        () {
          CancellationTokenSource cts1 = CancellationTokenSource();

          CancellationTokenRegistration ctr1 =
              cts1.token.register(callback: (_, __) async => outerCts.cancel());
          CancellationTokenRegistration ctr2 =
              cts1.token.register(callback: (_, __) async => outerCts.cancel());

          expect(ctr1 == ctr2, isFalse);
          expect(ctr1 != ctr2, isTrue);
          expect(ctr1.hashCode == ctr2.hashCode, isFalse);

          CancellationTokenRegistration ctr1copy = ctr1;
          expect(ctr1 == ctr1copy, isTrue);
        },
      );

      test(
        "registrations on different real tokens",
        () {
          CancellationTokenSource cts1 = CancellationTokenSource();
          CancellationTokenSource cts2 = CancellationTokenSource();

          CancellationTokenRegistration ctr1 =
              cts1.token.register(callback: (_, __) async => outerCts.cancel());
          CancellationTokenRegistration ctr2 =
              cts2.token.register(callback: (_, __) async => outerCts.cancel());

          expect(ctr1 == ctr2, isFalse);
          expect(ctr1 != ctr2, isTrue);
          expect(ctr1.hashCode == ctr2.hashCode, isFalse);

          CancellationTokenRegistration ctr1copy = ctr1;
          expect(ctr1 == ctr1copy, isTrue);
        },
      );
    },
  );

  group(
    "cancellation token registration linking object disposed exception in target",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts1 = CancellationTokenSource();
          CancellationTokenSource cts2 =
              CancellationTokenSource.createLinkedTokenSource(
            tokens: <CancellationToken>[
              cts1.token,
              CancellationToken(),
            ],
          );
          Exception? caughtException;

          cts2.token.register(
            callback: (_, __) => throw const ObjectDisposedException(),
          );

          try {
            await cts1.cancel(throwOnFirstException: true);
          } on AggregateException catch (ex) {
            caughtException = ex;
          }

          expect(
            caughtException is AggregateException &&
                caughtException.exceptionList[0] is ObjectDisposedException,
            isTrue,
          );
        },
      );
    },
  );

  group(
    "throw if cancellation requested",
    () {
      test(
        "",
        () async {
          OperationCancelledException? caughtEx;

          CancellationTokenSource cts = CancellationTokenSource();
          CancellationToken ct = cts.token..throwIfCancellationRequested();

          await cts.cancel();

          try {
            ct.throwIfCancellationRequested();
          } on OperationCancelledException catch (oce) {
            caughtEx = oce;
          }

          expect(caughtEx, isNotNull);
          expect(ct == caughtEx!.cancellationToken, isTrue);
        },
      );
    },
  );

  group(
    "deregister from within a callback is safe basic test",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts = CancellationTokenSource();
          CancellationToken ct = cts.token;

          CancellationTokenRegistration ctr1 =
              ct.register(callback: (_, __) {});
          ct.register(callback: (_, __) => ctr1.dispose());

          await cts.cancel();
        },
      );
    },
  );

  group(
    "object disposed exception when disposing linked cts",
    () {
      test(
        "",
        () async {
          CancellationTokenSource userTokenSource = CancellationTokenSource();
          CancellationToken userToken = userTokenSource.token;

          CancellationTokenSource cts2 = CancellationTokenSource();
          CancellationToken cts2Token = cts2.token;

          // Component A creates a linked token source representing the CT from the user and the "timeout" CT.
          CancellationTokenSource linkedTokenSource =
              CancellationTokenSource.createLinkedTokenSource(
            tokens: <CancellationToken>[
              cts2Token,
              userToken,
            ],
          );

          // User calls Cancel() on their CTS and then Dispose()
          await userTokenSource.cancel();
          userTokenSource.dispose();

          expect(() => linkedTokenSource.dispose(), returnsNormally);
        },
      );
    },
  );

  group(
    "cancellation token source with timer",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts = CancellationTokenSource.withDuration(
            duration: const Duration(days: 2000),
          );

          CancellationToken token = cts.token;
          bool cont = false;
          // ignore: unused_local_variable
          CancellationTokenRegistration ctr =
              token.register(callback: (_, __) => cont = true);

          expect(token.isCancellationRequested, isFalse);

          cts.cancelAfter(duration: const Duration(milliseconds: 1000000));

          expect(token.isCancellationRequested, isFalse);

          cts.cancelAfter(duration: const Duration(milliseconds: 10));

          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(cont, isTrue);

          cts.dispose();
        },
      );
    },
  );

  group(
    "cancellation token source try reset returns false if already cancelled",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts = CancellationTokenSource();
          await cts.cancel();
          expect(cts.tryReset(), isFalse);
          expect(cts.isCancellationRequested, isTrue);
        },
      );
    },
  );

  group(
    "cancellation token source try reset returns true if not cancelled and no timer",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts = CancellationTokenSource();
          expect(cts.tryReset(), isTrue);
          expect(cts.tryReset(), isTrue);
        },
      );
    },
  );

  group(
    "cancellation token source try reset returns true if not cancelled and timer has not fired",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts = CancellationTokenSource()
            ..cancelAfter(duration: const Duration(days: 1));
          expect(cts.tryReset(), isTrue);
        },
      );
    },
  );

  group(
    "cancellation token source try reset unregister all",
    () {
      test(
        "",
        () async {
          bool registration1Invoked = false;
          bool registration2Invoked = false;

          CancellationTokenSource cts = CancellationTokenSource();
          CancellationTokenRegistration ctr1 = cts.token.register(
            callback: (_, __) => registration1Invoked = true,
          );

          expect(cts.tryReset(), isTrue);

          CancellationTokenRegistration ctr2 = cts.token.register(
            callback: (_, __) => registration2Invoked = true,
          );

          await cts.cancel();

          expect(registration1Invoked, isFalse);
          expect(registration2Invoked, isTrue);

          expect(ctr1.unregister(), isFalse);
          expect(ctr2.unregister(), isFalse);

          expect(cts.token, equals(ctr1.token));
          expect(cts.token, equals(ctr2.token));
        },
      );
    },
  );

  group(
    "cancellation token registration dispose during cancellation succesfully removed if not yet invoked",
    () {
      test(
        "",
        () async {
          Completer<void> ctr0running = Completer<void>();
          Completer<void> ctr2blocked = Completer<void>();
          Completer<void> ctr2running = Completer<void>();
          CancellationTokenSource cts = CancellationTokenSource();

          // ignore: unused_local_variable
          CancellationTokenRegistration ctr0 =
              cts.token.register(callback: (_, __) => ctr0running.complete());

          bool ctr1Invoked = false;
          CancellationTokenRegistration ctr1 = cts.token.register(
            callback: (_, __) {
              ctr1Invoked = true;
            },
          );

          // ignore: unused_local_variable
          CancellationTokenRegistration ctr2 = cts.token.register(
            callback: (_, __) async {
              ctr2running.complete();
              await ctr2blocked.future;
            },
          );

          // Cancel.  This will trigger ctr2 to run, then ctr1, then ctr0.
          unawaited(Future<void>.microtask(() => cts.cancel()));

          await ctr2running.future; // wait for ctr2 to start running

          // Now that ctr2 is running, dispose ctr1. This should succeed
          // and ctr1 should not run.
          ctr1.dispose();

          // Allow ctr2 to continue.  ctr1 should not run.  ctr0 should, so wait for it.
          ctr2blocked.complete();
          await ctr0running.future;

          expect(ctr1Invoked, isFalse);
        },
      );
    },
  );

  group(
    "cancellation token registration token matches expected value",
    () {
      test(
        "",
        () {
          expect(
            CancellationToken.none,
            equals(CancellationTokenRegistration.zero.token),
          );

          CancellationTokenSource cts = CancellationTokenSource();
          expect(CancellationToken.none, isNot(equals(cts.token)));

          CancellationTokenRegistration ctr =
              cts.token.register(callback: (_, __) {});
          expect(cts.token, equals(ctr.token));
        },
      );
    },
  );

  group(
    "cancellation token registration token accessible after cts dispose",
    () {
      test(
        "",
        () {
          CancellationTokenSource cts = CancellationTokenSource();
          CancellationToken ct = cts.token;
          CancellationTokenRegistration ctr = ct.register(callback: (_, __) {});

          cts.dispose();
          expect(() => cts.token, throwsA(isA<ObjectDisposedException>()));

          expect(ct, equals(ctr.token));
          ctr.dispose();
          expect(ct, equals(ctr.token));
        },
      );
    },
  );

  group(
    "cancellation token registration unregister on default is nop",
    () {
      test(
        "",
        () {
          expect(CancellationTokenRegistration.zero.unregister(), isFalse);
        },
      );
    },
  );

  group(
    "cancellation token registration unregister removes delegate",
    () {
      test(
        "",
        () async {
          CancellationTokenSource cts = CancellationTokenSource();
          bool invoked = false;
          CancellationTokenRegistration ctr =
              cts.token.register(callback: (_, __) => invoked = true);
          expect(ctr.unregister(), isTrue);
          expect(ctr.unregister(), isFalse);
          await cts.cancel();
          expect(invoked, isFalse);
        },
      );
    },
  );

  group(
    "cancellation token registration unregister during cancellation successfully removed if not yet invoked",
    () {
      test(
        "",
        () async {
          Completer<void> ctr0running = Completer<void>();
          Completer<void> ctr2blocked = Completer<void>();
          Completer<void> ctr2running = Completer<void>();
          CancellationTokenSource cts = CancellationTokenSource();
          CancellationTokenRegistration ctr0 =
              cts.token.register(callback: (_, __) => ctr0running.complete());

          bool ctr1Invoked = false;
          CancellationTokenRegistration ctr1 =
              cts.token.register(callback: (_, __) => ctr1Invoked = true);

          CancellationTokenRegistration ctr2 = cts.token.register(
            callback: (_, __) async {
              ctr2running.complete();
              await ctr2blocked.future;
            },
          );

          // Cancel.  This will trigger ctr2 to run, then ctr1, then ctr0.
          unawaited(Future<void>.microtask(() => cts.cancel()));

          await ctr2running.future; // wait for ctr2 to start running
          expect(ctr2.unregister(), isFalse);

          // Now that ctr2 is running, unregister ctr1. This should succeed
          // and ctr1 should not run.
          expect(ctr1.unregister(), isTrue);

          // Allow ctr2 to continue.  ctr1 should not run.  ctr0 should, so wait for it.
          ctr2blocked.complete();
          await ctr0running.future;
          expect(ctr0.unregister(), isFalse);
          expect(ctr1Invoked, isFalse);
        },
      );
    },
  );
}
