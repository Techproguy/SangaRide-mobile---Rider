import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/buttons/inkwell.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SangaNavigation<T extends BaseTabView> extends StatefulWidget {
  final T? currentTab;
  final List<T> tabs;

  const SangaNavigation({super.key, required this.currentTab, required this.tabs});

  @override
  State<SangaNavigation<T>> createState() => SangaNavigationState<T>();

  static void switchTo(BuildContext context, BaseTabView tab) {
    context.findAncestorStateOfType<SangaNavigationState<BaseTabView>>()?.selectTab(tab);
  }
}

class SangaNavigationState<T extends BaseTabView> extends State<SangaNavigation<T>> {
  late final Rx<T> _currentTab = (widget.currentTab ?? widget.tabs.first).obs;
  late final PageController _pageController = PageController(initialPage: widget.tabs.indexOf(_currentTab.value));

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  BaseTabView get currentTabValue => _currentTab.value;

  void selectTab(BaseTabView tab) {
    final index = widget.tabs.indexOf(tab as T);
    if (index < 0) return;
    _currentTab.value = tab;
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) => _currentTab.value = widget.tabs[index];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: widget.tabs.map((tab) => tab.screen).toList(),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: SangaColors.textPrimary.withValues(alpha: 0.1),
                offset: const Offset(0, -3),
                blurRadius: 20,
              ),
            ],
            border: Border.all(color: SangaColors.divider),
            color: SangaColors.surface.withValues(alpha: 0.65),
          ),
          padding: const EdgeInsets.all(12),
          child: SafeArea(
            top: false,
            child: Obx(
              () => Row(
                spacing: 4,
                children: widget.tabs.map((tab) {
                  return Expanded(
                    child: SangaNavigationTab<T>(
                      tab,
                      onPressed: () => selectTab(tab),
                      isSelected: _currentTab.value == tab,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SangaNavigationTab<T extends BaseTabView> extends StatelessWidget {
  final VoidCallback? onPressed;
  final T tab;
  final bool isSelected;

  const SangaNavigationTab(this.tab, {super.key, this.onPressed, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return SangaInkwell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          AnimatedSwitcher(
            duration: 150.ms,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Image.asset(
              isSelected ? tab.activeIcon : tab.inactiveIcon,
              key: ValueKey(isSelected),
              width: 28,
              height: 28,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tab.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? SangaColors.primary : SangaColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
