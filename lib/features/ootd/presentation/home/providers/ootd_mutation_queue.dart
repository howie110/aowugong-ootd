import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Serializes read-modify-write operations across all three persisted providers.
final ootdMutationQueueProvider = Provider((ref) => OotdMutationQueue());

class OotdMutationQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
