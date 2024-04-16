import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_project/welcome/data/card_class.dart';
import 'package:test_project/welcome/bloc/navigation_bloc.dart';
import 'package:test_project/welcome/bloc/navigation_state.dart';
import 'package:test_project/welcome/widgets/favorite_widget.dart';
import 'package:test_project/welcome/widgets/settings_widget.dart';

class WelcomeScreen extends StatefulWidget {
  final List<CardClass> listCards;
  final NavigationBloc navigationBloc;
  const WelcomeScreen(
      {super.key, required this.listCards, required this.navigationBloc});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
        bloc: widget.navigationBloc,
        builder: (
          BuildContext context,
          NavigationState currentState,
        ) {
          if (currentState is UnNavigationState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (currentState is FavoriteNavigationState) {
            return FavoriteWidget(
              listCards: widget.listCards,
            );
          }
          if (currentState is SettingsNavigationState) {
            return const SettingsWidget();
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
