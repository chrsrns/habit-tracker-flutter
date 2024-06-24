import 'package:cohabit/home_page.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key, required this.onSplashDone}) : super(key: key);

  final Null Function() onSplashDone;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    _buildPageAsync().then((wgt) {
      Future.delayed(Duration(milliseconds: 1500)).whenComplete(() async {
        final route = _createRoute(wgt);
        // widget.onSplashDone();
        Navigator.of(context).pushReplacement(route);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: IntrinsicHeight(
          child: Column(
            children: [
              Text(
                "CoHabit",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text("Your habit tracking companion")
            ],
          ),
        ),
      ),
    );
  }
}

Future<Widget> _buildPageAsync() async {
  return Future.microtask(() {
    return HomePage(title: "CoHabit");
  });
}

Route _createRoute(Widget wgt) {
  return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => wgt,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      });
}
