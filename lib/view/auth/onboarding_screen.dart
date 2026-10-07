import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/auth/widgets/onboarding_slide.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const slides = [
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

  @override
  Widget build(BuildContext context) {
    void openGetStarted(int index) => context.push(SangaRoutes.getStarted, extra: slides[index].image);

    return AnnotatedRegion(
      value: SangaSystemUi.onPhoto,
      child: Scaffold(
        body: SangaStoryPager(
          count: slides.length,
          onFinished: () => openGetStarted(slides.length - 1),
          pageBuilder: (context, index) => SangaPhotoBackdrop.fadeToWhite(image: AssetImage(slides[index].image)),
          overlayBuilder: (context, story) => SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: SangaSpacing.lg, right: SangaSpacing.lg),
                    child: Visibility.maintain(
                      visible: !story.isLast,
                      child: SangaPillButton(label: 'Skip', onPressed: () => openGetStarted(story.index)),
                    ),
                  ),
                ),
                const Spacer(),
                _SlideText(key: ValueKey(story.index), slide: slides[story.index]),
                const SizedBox(height: SangaSpacing.xxl),
                SangaPageIndicator.dots(count: story.count, index: story.index, progress: story.progress),
                const SizedBox(height: SangaSpacing.xxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.heroInset),
                  child: SangaButton.primary(label: story.isLast ? 'Get started' : 'Next', onPressed: story.next),
                ),
                const SizedBox(height: SangaSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideText extends StatelessWidget {
  const _SlideText({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter),
          child: Text(slide.title, style: SangaTextStyles.display, textAlign: TextAlign.center),
        ).sangaEnter(),
        const SizedBox(height: SangaSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.heroInset),
          child: Text(slide.message, style: SangaTextStyles.lead, textAlign: TextAlign.center),
        ).sangaEnter(delay: SangaMotion.stagger),
      ],
    );
  }
}
