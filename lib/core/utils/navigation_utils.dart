import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Utility for navigating to a page with a fresh BLoC instance
class BlocNavigator {
  /// Navigate to a page with a new BLoC instance from GetIt
  static Future<T?> navigateWithNewBloc<B extends Bloc, T>({
    required BuildContext context,
    required Widget Function(BuildContext, B) pageBuilder,
    List<void Function(B)>? initEvents,
    void Function(T?)? onReturn,
  }) {
    final GetIt getIt = GetIt.instance;
    final bloc = getIt<B>();

    // Initialize the bloc with events if provided
    if (initEvents != null) {
      for (final addEvent in initEvents) {
        addEvent(bloc);
      }
    }

    // Navigate with the properly wrapped page
    return Navigator.of(context)
        .push<T>(
      MaterialPageRoute(
        builder: (context) => BlocProvider<B>(
          create: (context) => bloc,
          child: pageBuilder(context, bloc),
        ),
      ),
    )
        .then((result) {
      if (onReturn != null) onReturn(result);
      return result;
    });
  }
}
