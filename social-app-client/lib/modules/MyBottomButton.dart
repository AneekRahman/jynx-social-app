import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'constants.dart';

const double _svgWidth = 40;

class MyBottomButton extends StatelessWidget {
  final Function() onTap;
  final String text;
  final bool isLoading;
  MyBottomButton({Key? key, required this.onTap, required this.text, required this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 25),
        color: isLoading ? Colors.lightBlueAccent[100] : Colors.lightBlueAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingRotator(
              isLoading: isLoading,
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontFamily: HelveticaFont.Heavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingRotator extends StatefulWidget {
  final bool isLoading;
  LoadingRotator({required this.isLoading});

  @override
  _LoadingRotatorState createState() => _LoadingRotatorState();
}

class _LoadingRotatorState extends State<LoadingRotator> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  @override
  void initState() {
    _rotationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _rotationController, curve: Curves.ease),
      builder: (_, child) {
        if (widget.isLoading) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: child,
          );
        } else
          return child!;
      },
      child: FadeSlideIn(
        isLoading: widget.isLoading,
        child: Container(
          height: 20,
          width: _svgWidth,
          child: Image.asset(
            "assets/circle-dots-white.png",
          ),
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  FadeSlideIn({required this.isLoading, required this.child});

  @override
  _FadeSlideInState createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with TickerProviderStateMixin {
  late AnimationController _fadeSlideInController;

  @override
  void initState() {
    _fadeSlideInController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    super.initState();
  }

  @override
  void dispose() {
    _fadeSlideInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      _fadeSlideInController.forward(from: 0);
    } else {
      _fadeSlideInController.reverse(from: 1);
    }
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _fadeSlideInController, curve: Curves.ease),
      builder: (_, child) {
        return Opacity(
          opacity: _fadeSlideInController.value,
          child: SizedBox(
            child: child,
            width: _svgWidth * _fadeSlideInController.value,
          ),
        );
      },
      child: widget.child,
    );
  }
}
