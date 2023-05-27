// ignore_for_file: avoid_print, unused_local_variable

import "package:cancellation_token_dotnet/cancellation_token_dotnet.dart";

Future<void> main() async {
  CancellationTokenSource cts = CancellationTokenSource()
    ..cancelAfter(duration: const Duration(milliseconds: 4000));

  Future<String> t1 = aLongRunnningTask(
    const Duration(milliseconds: 250),
    "t1",
    token: cts.token,
  );
  Future<String> t2 = aLongRunnningTask(
    const Duration(milliseconds: 500),
    "t2",
    token: cts.token,
  );
  Future<String> t3 = aLongRunnningTask(
    const Duration(milliseconds: 750),
    "t3",
    token: cts.token,
  );
  Future<String> t4 = aLongRunnningTask(
    const Duration(milliseconds: 1000),
    "t4",
    token: cts.token,
  );

  CancellationTokenRegistration ctr = cts.register(
    callback: (Object? state, CancellationToken token) {
      print("Callback has run");
    },
    state: Object(),
  );

  try {
    await Future.wait<String>(
      <Future<String>>[
        t1,
        t2,
        t3,
        t4,
      ],
    );
  } on OperationCancelledException catch (e, st) {
    print("Operation is cancelled. Exception $e, Stack Trace: $st");
  }
}

Future<String> aLongRunnningTask(
  Duration duration,
  String taskName, {
  CancellationToken token = CancellationToken.none,
}) async {
  print("Running Task name: $taskName");
  int iteration = 1;
  while (!token.isCancellationRequested) {
    print("Task name: $taskName, iteration: $iteration");
    await Future<void>.delayed(duration);
    ++iteration;
  }

  if (taskName == "t4") {
    token.throwIfCancellationRequested();
  }

  print("Completed Task name: $taskName");

  return taskName;
}
