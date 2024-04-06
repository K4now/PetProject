import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:test_project/logic/navigation/navigation/index.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {

  NavigationBloc(NavigationState initialState) : super(initialState){
   on<NavigationEvent>((event, emit) {
      return emit.forEach<NavigationState>(
        event.applyAsync(currentState: state, bloc: this),
        onData: (state) => state,
        onError: (error, stackTrace) {
          developer.log('$error', name: 'NavigationBloc', error: error, stackTrace: stackTrace);
          return ErrorNavigationState(error.toString());
        },
      );
    });
  }
}
