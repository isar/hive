part of hive_flutter;

/// Signature for a function that builds a widget given a [Box].
typedef HiveWidgetBuilder = Widget Function(BuildContext context, Box box);

/// A general-purpose widget which rebuilds itself when the box or a specific
/// key change.
class HiveBuilder extends StatefulWidget {
  /// Creates a widget that rebuilds itself when a value in the [box] changes.
  ///
  /// If you specify [watchKeys], the widget only refreshes when a value
  /// associated to a key in [watchKeys] changes.
  HiveBuilder({
    Key key,
    @required this.box,
    @required this.builder,
    this.watchKeys,
  })  : openBox = null,
        child = null,
        assert(box != null),
        assert(builder != null),
        super(key: key);

  /// Creates a widget that builds itself a value in the box opened by
  /// [openBox] changes.
  ///
  /// While the box opening is in progress, the [child] widget is shown. If
  /// child is null, a [Container] is shown instead.
  ///
  /// If you specify [watchKeys], the widget only refreshes when a value
  /// associated to a key in [watchKeys] changes.
  HiveBuilder.openBox({
    Key key,
    @required this.openBox,
    @required this.builder,
    this.child,
    this.watchKeys,
  })  : box = null,
        assert(openBox != null),
        assert(builder != null),
        super(key: key);

  /// The box which should be watched.
  final Box box;

  /// This function has to open and return the desired box.
  final FutureOr<Box> Function() openBox;

  /// Called every time the box changes. The builder must not return null.
  final HiveWidgetBuilder builder;

  /// This widget is being shown until openening is finished.
  final Widget child;

  /// Specifies which keys should be watched.
  final List<String> watchKeys;

  @override
  HiveBuilderState createState() => HiveBuilderState();
}

class HiveBuilderState extends State<HiveBuilder> {
  @visibleForTesting
  Box box;

  @visibleForTesting
  StreamSubscription subscription;

  @visibleForTesting
  var openBoxHandle = 0;

  @override
  void initState() {
    super.initState();

    if (widget.box != null) {
      box = widget.box;
      _subscribe();
    } else {
      _startOpeningBox();
    }
  }

  @override
  void didUpdateWidget(HiveBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.openBox != oldWidget.openBox) {
      _cancelOpeningBox();

      if (widget.openBox != null) {
        _unsubscribe();
        _startOpeningBox();
      }
    }

    if (widget.box != null && box != widget.box) {
      _unsubscribe();
      box = widget.box;
    }
  }

  _subscribe() {
    subscription = box.watch().listen((event) {
      if (widget.watchKeys != null && !widget.watchKeys.contains(event.key)) {
        return;
      }

      setState(() {});
    });
  }

  _unsubscribe() {
    subscription?.cancel();
  }

  _startOpeningBox() async {
    var handle = ++openBoxHandle;
    var openedBox = await widget.openBox();
    if (mounted && handle == openBoxHandle) {
      setState(() {
        box = openedBox;
      });
      _subscribe();
    }
  }

  _cancelOpeningBox() {
    openBoxHandle++;
  }

  @override
  Widget build(BuildContext context) {
    if (box == null) {
      return widget.child ?? Container();
    } else {
      return widget.builder(context, box);
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
