import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class Spoiler extends StatefulWidget {
  final Widget header;
  final Widget child;

  final bool isOpened;

  final Curve openCurve;
  final Curve closeCurve;

  final Duration duration;

  const Spoiler(
      {this.header,
      this.child,
      this.isOpened = false,
      this.duration,
      this.openCurve = Curves.linear,
      this.closeCurve = Curves.linear});

  @override
  SpoilerState createState() => SpoilerState();
}

class SpoilerState extends State<Spoiler> with TickerProviderStateMixin {
  double childHeight;

  AnimationController animationController;
  Animation<double> animation;

  StreamController<bool> isReadyController = StreamController();
  Stream<bool> isReady;

  StreamController<bool> isOpenController = StreamController();
  Stream<bool> isOpen;

  bool isOpened;

  @override
  void initState() {
    super.initState();

    isOpened = widget.isOpened;

    isReady = isReadyController.stream.asBroadcastStream();

    isOpen = isOpenController.stream.asBroadcastStream();

    animationController = AnimationController(
        duration: widget.duration != null
            ? widget.duration
            : Duration(milliseconds: 400),
        vsync: this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      childHeight = _childKey.currentContext.size.height;

      animation = CurvedAnimation(
          parent: animationController,
          curve: widget.openCurve,
          reverseCurve: widget.closeCurve);

      animation =
          Tween(begin: 0.toDouble(), end: childHeight).animate(animation);

      isReadyController.add(true);

      isOpened
          ? animationController.forward().orCancel
          : animationController.reverse().orCancel;
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    isOpenController.close();
    isReadyController.close();
    super.dispose();
  }

  Future<void> toggle() async {
    try {
      isOpened = isOpened ? false : true;

      isOpenController.add(isOpened);

      isOpened
          ? await animationController.forward().orCancel
          : await animationController.reverse().orCancel;
    } on TickerCanceled {
      // the animation got canceled, probably because we were disposed
    }
  }

  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: toggle,
            child: Container(
              key: Key('header'),
              child:
                  widget.header != null ? widget.header : _buildDefaultHeader(),
            ),
          ),
          StreamBuilder<bool>(
              stream: isReady,
              initialData: false,
              builder: (context, snapshot) {
                if (snapshot.data) {
                  return AnimatedBuilder(
                    animation:
                        animation != null ? animation : animationController,
                    builder: (BuildContext context, Widget child) => Container(
                      height: animation.value > 0 ? animation.value : 0,
                      child: Wrap(
                        children: <Widget>[
                          widget.child != null ? widget.child : Container()
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    key: _childKey,
                    child: Wrap(
                      children: <Widget>[
                        widget.child != null ? widget.child : Container()
                      ],
                    ),
                  );
                }
              }),
        ],
      );

  Widget _buildDefaultHeader() => StreamBuilder<bool>(
      stream: isOpen,
      initialData: isOpened,
      builder: (context, snapshot) => Container(
          margin: EdgeInsets.all(10),
          height: 20,
          width: 20,
          child: Center(
              child: Center(child: snapshot.data ? Text('-') : Text('+')))));
}
