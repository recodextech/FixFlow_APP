import 'package:flutter/material.dart';

const String homeScreenRoute = '/home';

void navigateToHomeScreen(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(homeScreenRoute, (_) => false);
}

class HomeNavigationButton extends StatelessWidget {
  const HomeNavigationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Home',
      onPressed: () => navigateToHomeScreen(context),
    );
  }
}
