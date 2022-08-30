import 'package:flutter/material.dart';

class LoadingBar extends StatelessWidget {
  bool _loading;
  LoadingBar({Key? key, required bool loading})
      : _loading = loading,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _loading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              backgroundColor: Colors.transparent,
            )
          : Container(),
      constraints: BoxConstraints.expand(height: 1),
    );
  }
}
