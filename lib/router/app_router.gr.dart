// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    QusetionRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const QusetionPage(),
      );
    },
    TicTacRoute.name: (routeData) {
      final args = routeData.argsAs<TicTacRouteArgs>(
          orElse: () => const TicTacRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: TicTacPage(key: args.key),
      );
    },
    WelcomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const WelcomePage(),
      );
    },
  };
}

/// generated route for
/// [QusetionPage]
class QusetionRoute extends PageRouteInfo<void> {
  const QusetionRoute({List<PageRouteInfo>? children})
      : super(
          QusetionRoute.name,
          initialChildren: children,
        );

  static const String name = 'QusetionRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [TicTacPage]
class TicTacRoute extends PageRouteInfo<TicTacRouteArgs> {
  TicTacRoute({
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          TicTacRoute.name,
          args: TicTacRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'TicTacRoute';

  static const PageInfo<TicTacRouteArgs> page = PageInfo<TicTacRouteArgs>(name);
}

class TicTacRouteArgs {
  const TicTacRouteArgs({this.key});

  final Key? key;

  @override
  String toString() {
    return 'TicTacRouteArgs{key: $key}';
  }
}

/// generated route for
/// [WelcomePage]
class WelcomeRoute extends PageRouteInfo<void> {
  const WelcomeRoute({List<PageRouteInfo>? children})
      : super(
          WelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'WelcomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
