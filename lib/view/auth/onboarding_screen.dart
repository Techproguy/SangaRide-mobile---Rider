import 'package:flutter/material.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/view/auth/onboarding_copy.dart';
import 'package:sanga_ride/view/auth/widgets/get_started_sheet.dart';

import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  static const _sheetHidden = Offset(0, 1.2);
  static const _slides = [
    SangaOnboardingSlide(
      image: AppAssets.onboardingRide,
      title: OnboardingCopy.bookRidesTitle,
      message: OnboardingCopy.bookRidesMessage,
    ),
    SangaOnboardingSlide(
      image: AppAssets.onboardingDelivery,
      title: OnboardingCopy.safeDeliveryTitle,
      message: OnboardingCopy.safeDeliveryMessage,
    ),
    SangaOnboardingSlide(
      image: AppAssets.onboardingFares,
      title: OnboardingCopy.faresTitle,
      message: OnboardingCopy.faresMessage,
    ),
  ];

  late final _choice = AnimationController(
    vsync: this,
    duration: SangaMotion.sheetEnter,
    reverseDuration: SangaMotion.sheetExit,
  )..addStatusListener((_) => setState(() {}));
  late final _slideFade = ReverseAnimation(
    CurvedAnimation(
      parent: _choice,
      curve: const Interval(0, 0.45, curve: SangaMotion.fadeCurve),
    ),
  );
  late final _sheetRise = Tween(begin: _sheetHidden, end: Offset.zero).animate(
    CurvedAnimation(parent: _choice, curve: SangaMotion.springSheet, reverseCurve: SangaMotion.springSheet.flipped),
  );

  bool get _isChoosing => _choice.status == AnimationStatus.forward || _choice.status == AnimationStatus.completed;

  bool get _isChoiceVisible => _choice.status != AnimationStatus.dismissed;

  @override
  void dispose() {
    _choice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SangaBackScope(
      canPop: !_isChoosing,
      onBack: _choice.reverse,
      child: AnnotatedRegion(
        value: SangaSystemUi.onPhoto,
        child: Scaffold(
          body: SangaStoryPager(
            count: _slides.length,
            isPaused: _isChoosing,
            onFinished: _choice.forward,
            pageBuilder: (context, index) => SangaPhotoBackdrop.fadeToWhite(image: AssetImage(_slides[index].image)),
            overlayBuilder: (context, story) => Stack(
              fit: StackFit.expand,
              children: [
                Visibility(
                  visible: _isChoiceVisible,
                  child: SangaRecedingPhoto(image: AssetImage(_slides[story.index].image), progress: _choice),
                ),
                FadeTransition(
                  opacity: _slideFade,
                  child: IgnorePointer(
                    ignoring: _isChoosing,
                    child: _SlideOverlay(story: story, slide: _slides[story.index], onSkip: _choice.forward),
                  ),
                ),
                Visibility(
                  visible: _isChoiceVisible,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SlideTransition(
                      position: _sheetRise,
                      child: GetStartedSheet(onClose: _choice.reverse),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideOverlay extends StatelessWidget {
  const _SlideOverlay({required this.story, required this.slide, required this.onSkip});

  final SangaStory story;
  final SangaOnboardingSlide slide;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: SangaSpacing.lg, right: SangaSpacing.lg),
              child: SangaFadeVisibility(
                isVisible: !story.isLast,
                child: SangaPillButton(label: SangaAuthCopy.skip, onPressed: onSkip),
              ),
            ),
          ),
          const Spacer(),
          SangaHandoff(
            value: story.index,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter),
                  child: Text(slide.title, style: SangaTextStyles.display, textAlign: TextAlign.center),
                ).sangaEnter(SangaEntrance.title),
                const SizedBox(height: SangaSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.heroInset),
                  child: Text(slide.message, style: SangaTextStyles.lead, textAlign: TextAlign.center),
                ).sangaEnter(SangaEntrance.body),
              ],
            ),
          ),
          const SizedBox(height: SangaSpacing.xxl),
          SangaPageIndicator.dots(count: story.count, index: story.index, progress: story.progress),
          const SizedBox(height: SangaSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.heroInset),
            child: SangaButton.primary(
              label: story.isLast ? SangaAuthCopy.getStarted : SangaAuthCopy.next,
              onPressed: story.next,
            ),
          ),
          const SizedBox(height: SangaSpacing.md),
        ],
      ),
    );
  }
}
