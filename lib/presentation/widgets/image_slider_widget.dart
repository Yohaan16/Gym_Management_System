import 'package:flutter/material.dart';

class ImageSliderWidget extends StatefulWidget {
  final List<Map<String, String>> items; // List of {"title": "TITLE", "image": "path"}
  final bool autoSlide; // Whether to auto-slide
  final Duration autoSlideDuration; // Duration between slides
  final Widget Function(int currentIndex)? overlayBuilder; // Dynamic overlay builder (moves with slides)
  final Widget? overlayWidget; // Static overlay widget per slide (moves with slides)
  final Widget? staticOverlayWidget; // Static overlay widget (stays fixed over sliding images)
  final bool showDots; // Whether to show dot indicators
  final double height; // Height of the slider
  final BorderRadius? borderRadius; // Border radius for the container
  final LinearGradient? activeDotGradient; // Gradient for active dot
  final Color? inactiveDotColor; // Color for inactive dots
  final Function(int)? onPageChanged; // Callback when page changes

  const ImageSliderWidget({
    super.key,
    required this.items,
    this.autoSlide = false,
    this.autoSlideDuration = const Duration(seconds: 3),
    this.overlayBuilder,
    this.overlayWidget,
    this.staticOverlayWidget,
    this.showDots = true,
    this.height = 200,
    this.borderRadius,
    this.activeDotGradient,
    this.inactiveDotColor,
    this.onPageChanged,
  }) : assert((overlayWidget == null || overlayBuilder == null) && 
             (overlayWidget == null || staticOverlayWidget == null) &&
             (overlayBuilder == null || staticOverlayWidget == null),
            'Cannot provide multiple overlay types simultaneously');

  @override
  State<ImageSliderWidget> createState() => _ImageSliderWidgetState();
}

class _ImageSliderWidgetState extends State<ImageSliderWidget>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.autoSlide && widget.items.isNotEmpty) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    Future.delayed(widget.autoSlideDuration, () {
      if (mounted && widget.items.isNotEmpty) {
        final nextIndex = (_currentIndex + 1) % widget.items.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        _startAutoSlide(); // Schedule next slide
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, index) {
                final item = widget.items[index];
                return Stack(
                  children: [
                    Image.asset(
                      item["image"]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    // Overlay gradient for better text visibility (only if no static overlay)
                    if (widget.staticOverlayWidget == null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    // Custom overlay widget (per slide)
                    if (widget.overlayWidget != null)
                      Center(child: widget.overlayWidget!)
                    else if (widget.overlayBuilder != null)
                      Center(child: widget.overlayBuilder!(_currentIndex)),
                  ],
                );
              },
            ),

            // Dot indicators
            if (widget.showDots)
              Positioned(
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.items.length,
                    (index) => _buildDotIndicator(index == _currentIndex),
                  ),
                ),
              ),

            // Static overlay widget (fixed over sliding images)
            if (widget.staticOverlayWidget != null)
              Positioned.fill(
                child: widget.staticOverlayWidget!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 6,
      height: isActive ? 10 : 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive ? widget.activeDotGradient : null,
        color: isActive ? null : (widget.inactiveDotColor ?? Colors.white54),
      ),
    );
  }
}