import 'dart:async';
import 'dart:developer' as developer;

// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';

import 'package:test_project/welcome/bloc/index.dart';

@immutable
abstract class NavigationEvent {
  Stream<NavigationState> applyAsync(
      {NavigationState currentState, NavigationBloc bloc});
}

class UnNavigationEvent extends NavigationEvent {
  @override
  Stream<NavigationState> applyAsync({NavigationState? currentState, NavigationBloc? bloc}) async* {
    yield const UnNavigationState();
  }
}

class LoadNavigationEvent extends NavigationEvent {
   
  @override
  Stream<NavigationState> applyAsync(
      {NavigationState? currentState, NavigationBloc? bloc}) async* {
    try {
      yield const UnNavigationState();
      await Future.delayed(const Duration(seconds: 1));
   
    } catch (_, stackTrace) {
      developer.log('$_', name: 'LoadNavigationEvent', error: _, stackTrace: stackTrace);
      yield ErrorNavigationState( _.toString());
    }
  }
}

class FavoriteNavigationEvent extends NavigationEvent {
  @override
  Stream<NavigationState> applyAsync({NavigationState? currentState, NavigationBloc? bloc}) async* {
    yield const FavoriteNavigationState("Программы");
  }}

  class SettingsNavigationEvent extends NavigationEvent {
  @override
  Stream<NavigationState> applyAsync({NavigationState? currentState, NavigationBloc? bloc}) async* {
    yield const SettingsNavigationState("Настройки");
  }}



