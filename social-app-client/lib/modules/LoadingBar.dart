import 'package:flutter/material.dart';

class LoadingBar extends StatelessWidget {
  final bool loading;
  Color barColor;
  LoadingBar({Key? key, required bool this.loading, this.barColor = Colors.yellow});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: loading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              backgroundColor: Colors.transparent,
            )
          : Container(),
      constraints: BoxConstraints.expand(height: 1),
    );
  }
}
