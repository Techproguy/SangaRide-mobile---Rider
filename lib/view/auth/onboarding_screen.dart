import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/auth/widgets/onboarding_slide.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    OnboardingSlide(
      image: AppAssets.onboardingRide,
      title: 'Book Rides Promptly',
      message: 'Request a ride in seconds and get moving without the wait',
    ),
    OnboardingSlide(
      image: AppAssets.onboardingDelivery,
      title: 'Secure & Safe Delivery',
      message: 'Fast pickups, secure handling, and reliable delivery from start to finish',
    ),
    OnboardingSlide(
      image: AppAssets.onboardingFares,
      title: 'Flexible, Negotiable Fares',
      message: 'Agree on a fare that works for both you and the driver',
    ),
  ];

  final _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastPage) return _openGetStarted();
    _pageController.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _openGetStarted() => context.push(SangaRoutes.getStarted);

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return AnnotatedRegion(
      value: SangaSystemUi.onPhoto,
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => SangaPhotoBackdrop.fadeToWhite(image: AssetImage(_slides[index].image)),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: SangaSpacing.lg, right: SangaSpacing.lg),
                      child: SangaPillButton(label: 'Skip', onPressed: _openGetStarted),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Column(
                      key: ValueKey(_page),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter),
                          child: Text(slide.title, style: SangaTextStyles.display, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: SangaSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.heroInset),
                          child: Text(slide.message, style: SangaTextStyles.lead, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SangaSpacing.xxl),
                  SangaPageIndicator.dots(count: _slides.length, index: _page),
                  const SizedBox(height: SangaSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.heroInset),
                    child: SangaButton.primary(label: _isLastPage ? 'Get started' : 'Next', onPressed: _next),
                  ),
                  const SizedBox(height: SangaSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
