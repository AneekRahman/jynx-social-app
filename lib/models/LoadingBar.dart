import 'package:flutter/material.dart';

class LoadingBar extends StatelessWidget {
  bool _loading;
  Color valueColor = Colors.blue[100];
  LoadingBar({Key key, bool loading, Color valueColor})
      : _loading = loading,
        valueColor = valueColor,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _loading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(valueColor),
              backgroundColor: Colors.transparent,
            )
          : Container(),
      constraints: BoxConstraints.expand(height: 1),
    );
  }
}
