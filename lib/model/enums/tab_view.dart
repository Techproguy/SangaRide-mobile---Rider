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
  home('Home', HomeScreen(), SangaAssets.homeActive, SangaAssets.homeInactive, SangaRoutes.home),
  trips('Trips', TripsScreen(), SangaAssets.tripsActive, SangaAssets.tripsInactive, SangaRoutes.trips),
  wallet('Wallet', WalletScreen(), SangaAssets.walletActive, SangaAssets.walletInactive, SangaRoutes.wallet),
  profile('Profile', ProfileScreen(), SangaAssets.profileActive, SangaAssets.profileInactive, SangaRoutes.profile);

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
