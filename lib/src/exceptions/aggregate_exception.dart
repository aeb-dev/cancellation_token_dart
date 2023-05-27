class AggregateException implements Exception {
  final List<Object> exceptionList;

  const AggregateException(this.exceptionList);
}
