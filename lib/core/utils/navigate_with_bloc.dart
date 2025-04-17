import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void navigateWithBloc<T extends Bloc<dynamic, dynamic>>({
  required BuildContext context,
  required Widget Function(BuildContext) pageBuilder,
  required T Function() createBloc,
  required List<dynamic> Function(T bloc) initEvents,
  Function? onReturn,
}) {
  // Create a new bloc instance
  final bloc = createBloc();

  // Initialize the bloc with events
  for (final event in initEvents(bloc)) {
    bloc.add(event);
  }

  // Navigate with the properly wrapped page
  Navigator.of(context)
      .push(
    MaterialPageRoute(
      builder: (context) => BlocProvider<T>(
        create: (context) => bloc,
        child: pageBuilder(context),
      ),
    ),
  )
      .then((_) {
    // Handle any post-navigation logic
    if (onReturn != null) onReturn();
  });
}
