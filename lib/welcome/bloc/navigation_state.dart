import 'package:equatable/equatable.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object> get props => [];
}

/// UnInitialized
class UnNavigationState extends NavigationState {

  const UnNavigationState();

  @override
  String toString() => 'UnNavigationState';
}



class FavoriteNavigationState extends NavigationState {
  const FavoriteNavigationState(this.titile);
 
  final String titile;
  
  @override
  String toString() => 'Title';

  @override
  List<Object> get props => [titile];
}
class SettingsNavigationState extends NavigationState {
  const SettingsNavigationState(this.titile);
 
  final String titile;
  
  @override
  String toString() => 'Title';

  @override
  List<Object> get props => [titile];
}

class ErrorNavigationState extends NavigationState {
  const ErrorNavigationState(this.errorMessage);
 
  final String errorMessage;
  
  @override
  String toString() => 'ErrorNavigationState';

  @override
  List<Object> get props => [errorMessage];
}
