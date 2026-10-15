import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

base class LogObserver extends ProviderObserver {
  String _name(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    debugPrint('ADD  ${_name(context)}: $value');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    debugPrint('UPD  ${_name(context)}: $newValue');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('FAIL ${_name(context)}: $error\n$stackTrace');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    debugPrint('DISP ${_name(context)}');
  }
}