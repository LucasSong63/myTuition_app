import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class FloatingEducationalElements extends StatefulWidget {
  final int numberOfElements;

  const FloatingEducationalElements({
    Key? key,
    this.numberOfElements = 15,
  }) : super(key: key);

  @override
  State<FloatingEducationalElements> createState() =>
      _FloatingEducationalElementsState();
}

class _FloatingEducationalElementsState
    extends State<FloatingEducationalElements> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Offset> _positions;
  late List<double> _sizes;
  late List<Color> _colors;
  late List<int> _elementTypes;

  final Random _random = Random();

  // Define the symbols to use
  final List<IconData> _mathIcons = [
    Icons.add, // Plus
    Icons.remove, // Minus
    Icons.close, // Multiply
    Icons.drag_handle, // Equals
  ];

  final List<IconData> _scienceIcons = [
    Icons.biotech, // Lab
    Icons.science, // Flask
    Icons.brightness_5, // Sun/atom
    Icons.offline_bolt, // Energy
  ];

  final List<IconData> _languageIcons = [
    Icons.menu_book, // Book
    Icons.translate, // Languages
    Icons.spellcheck, // Spelling
    Icons.format_quote, // Quote
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers and animations
    _controllers = List.generate(
      widget.numberOfElements,
      (index) => AnimationController(
        duration: Duration(milliseconds: _random.nextInt(3000) + 2000),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Generate random positions and properties for each element
    _positions = List.generate(
      widget.numberOfElements,
      (index) => Offset(
        _random.nextDouble(),
        _random.nextDouble(),
      ),
    );

    _sizes = List.generate(
      widget.numberOfElements,
      (index) => _random.nextDouble() * 15 + 10,
    );

    _colors = List.generate(
      widget.numberOfElements,
      (index) {
        final colorOptions = [
          AppColors.primaryBlue,
          AppColors.accentOrange,
          AppColors.accentTeal,
          AppColors.mathSubject,
          AppColors.scienceSubject,
          AppColors.englishSubject,
          AppColors.bahasaSubject,
          AppColors.chineseSubject,
        ];
        return colorOptions[_random.nextInt(colorOptions.length)]
            .withOpacity(0.3 + _random.nextDouble() * 0.3);
      },
    );

    _elementTypes = List.generate(
      widget.numberOfElements,
      (index) => _random.nextInt(3),
    );

    // Start animations with random delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _random.nextInt(1000)), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(widget.numberOfElements, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                // Calculate position with a floating effect
                final dx = _positions[index].dx * constraints.maxWidth;
                final dy = _positions[index].dy * constraints.maxHeight;

                // Add a floating motion using sin function
                final floatingOffset =
                    sin(_controllers[index].value * 2 * pi) * 10;

                return Positioned(
                  left: dx,
                  top: dy + floatingOffset,
                  child: Opacity(
                    opacity: 0.3 + (_controllers[index].value * 0.4),
                    child: _buildElement(index),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildElement(int index) {
    // Get the appropriate icon based on element type (math, science, language)
    IconData icon;
    switch (_elementTypes[index]) {
      case 0: // Math
        icon = _mathIcons[_random.nextInt(_mathIcons.length)];
        break;
      case 1: // Science
        icon = _scienceIcons[_random.nextInt(_scienceIcons.length)];
        break;
      case 2: // Language
        icon = _languageIcons[_random.nextInt(_languageIcons.length)];
        break;
      default:
        icon = Icons.school;
    }

    return Icon(
      icon,
      size: _sizes[index],
      color: _colors[index],
    );
  }
}
