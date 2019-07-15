import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HiveBuilder extends StatefulWidget {
  final String boxName;

  final Future<Widget> Function(BuildContext context, Box box) builder;

  final Future<Box> Function() openBox;

  final Widget Function(BuildContext context) loadingBuilder;

  final Widget Function(BuildContext context, dynamic error) errorBuilder;

  final bool Function(String key) keyFilter;

  HiveBuilder({
    @required this.boxName,
    @required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.keyFilter,
  }) : openBox = null;

  HiveBuilder.open({
    @required this.openBox,
    @required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.keyFilter,
  }) : boxName = null;

  @override
  _HiveBuilderState createState() => _HiveBuilderState();
}

class _HiveBuilderState extends State<HiveBuilder> {
  Box _box;
  StreamSubscription _subscription;
  Widget _builtWidget;
  bool _notifyBuildComplete = false;

  @override
  void initState() {
    super.initState();

    _subscribe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_box.name != widget.boxName) {
      _subscription.cancel();
      _subscribe();
    }
  }

  void _subscribe() async {
    if (!Hive.isBoxOpen(widget.boxName)) {
      throw 'Box "${widget.boxName}" is not open. Call Hive.box() first.';
    }
    _box = await Hive.box(widget.boxName);
    _subscription = _box.watch().listen((e) {
      if (widget.keyFilter != null) {
        if (!widget.keyFilter(e.key)) return;
      }

      setState(() {});
    });
  }

  void _build() async {
    Widget built;
    try {
      built = await widget.builder(context, _box);
    } catch (e) {
      if (widget.errorBuilder != null) {
        built = widget.errorBuilder(context, e);
      } else {
        rethrow;
      }
    }

    if (_notifyBuildComplete && mounted) {
      setState(() {
        _builtWidget = built;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notifyBuildComplete && _builtWidget != null) {
      _notifyBuildComplete = false;
      return _builtWidget;
    }

    _builtWidget = null;
    _notifyBuildComplete = false;
    _build();
    if (_builtWidget != null) {
      return _builtWidget;
    } else {
      _notifyBuildComplete = true;
      if (widget.loadingBuilder != null) {
        return widget.loadingBuilder(context);
      } else {
        return Container();
      }
    }
  }
}
