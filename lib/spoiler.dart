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

  final bool waitFirstCloseAnimationBeforeOpen;

  const Spoiler(
      {this.header,
      this.child,
      this.isOpened = false,
      this.waitFirstCloseAnimationBeforeOpen = false,
      this.duration,
      this.openCurve = Curves.easeOutExpo,
      this.closeCurve = Curves.easeInExpo});

  @override
  SpoilerState createState() => SpoilerState();
}

class SpoilerState extends State<Spoiler> with SingleTickerProviderStateMixin {
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

    animation = CurvedAnimation(
        parent: animationController,
        curve: widget.openCurve,
        reverseCurve: widget.closeCurve);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      childHeight = _childKey.currentContext.size.height;

      animation =
          Tween(begin: 0.toDouble(), end: childHeight).animate(animation);

      isReadyController.add(true);

      try {
        if (widget.waitFirstCloseAnimationBeforeOpen) {
          isOpened
              ? await animationController.forward().orCancel
              : await animationController
                  .forward()
                  .orCancel
                  .whenComplete(() => animationController.reverse().orCancel);
        } else {
          isOpened
              ? await animationController.forward().orCancel
              : await animationController.reverse().orCancel;
        }
      } on TickerCanceled {
        // the animation got canceled, probably because we were disposed
      }
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
                    animation: animation,
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
