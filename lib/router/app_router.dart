import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:test_project/clock/page/question_page.dart';
import 'package:test_project/tic_tac/bloc/index.dart';

import '../welcome/page/welcome_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {

  @override
  List<AutoRoute> get routes => [
    /// routes go here
      AutoRoute(page: WelcomeRoute.page, path: "/"),
      AutoRoute(page: TicTacRoute.page),
      AutoRoute(page: QusetionRoute.page)
  ];
}