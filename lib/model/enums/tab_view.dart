import 'package:flutter/widgets.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/home/home_screen.dart';
import 'package:sanga_ride/view/profile/profile_screen.dart';
import 'package:sanga_ride/view/trips/trips_screen.dart';
import 'package:sanga_ride/view/wallet/wallet_screen.dart';

sealed class BaseTabView {
  const BaseTabView();

  String get name;

  Widget get screen;

  String get activeIcon;

  String get inactiveIcon;

  String get route;
}

enum TabView implements BaseTabView {
  home('Home', HomeScreen(), AppAssets.homeActive, AppAssets.homeInactive, SangaRoutes.home),
  trips('Trips', TripsScreen(), AppAssets.tripsActive, AppAssets.tripsInactive, SangaRoutes.trips),
  wallet('Wallet', WalletScreen(), AppAssets.walletActive, AppAssets.walletInactive, SangaRoutes.wallet),
  profile('Profile', ProfileScreen(), AppAssets.profileActive, AppAssets.profileInactive, SangaRoutes.profile);

  @override
  final String name;
  @override
  final Widget screen;
  @override
  final String activeIcon;
  @override
  final String inactiveIcon;
  @override
  final String route;

  const TabView(this.name, this.screen, this.activeIcon, this.inactiveIcon, this.route);
}
