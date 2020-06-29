import 'package:flutter/material.dart';

class DoubleFloatingActionButton extends StatelessWidget {
  final Widget leftButton, rightButton;
  final EdgeInsetsGeometry padding;
  DoubleFloatingActionButton({@required this.leftButton, @required this.rightButton, this.padding});

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding = this.padding != null ? this.padding : EdgeInsets.symmetric(horizontal: 15, vertical: 0);

    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(padding: padding, child: leftButton),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(padding: padding, child: rightButton),
        ),
      ],
    );
  }
}
