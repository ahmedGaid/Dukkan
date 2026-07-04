import 'package:flutter/material.dart';

/// F1 scaffold splash — shows the brand mark while the app boots.
/// Routing to the real entry point lands in F2/F3 once auth + router exist.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = isDark
        ? 'assets/brand/logo-dark.png'
        : 'assets/brand/logo-light.png';

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Image.asset(logo, width: 200),
        ),
      ),
    );
  }
}
