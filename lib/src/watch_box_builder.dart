part of hive_flutter;

/// Signature for a function that builds a widget given a [Box].
typedef BoxWidgetBuilder<T> = Widget Function(BuildContext context, Box<T> box);

/// A general-purpose widget which rebuilds itself when the box or a specific
/// key change.
class WatchBoxBuilder<T> extends StatelessWidget {
  /// Creates a widget that rebuilds itself when a value in the [box] changes.
  ///
  /// If you specify [watchKey], the widget only refreshes when a value
  /// associated to a key in [watchKey] changes.
  WatchBoxBuilder({
    Key key,
    @required this.box,
    @required this.builder,
    this.watchKey,
  })  : assert(box != null),
        assert(builder != null),
        super(key: key);

  /// The box which should be watched.
  final Box<T> box;

  /// Called every time the box changes. The builder must not return null.
  final BoxWidgetBuilder builder;

  /// Specifies which keys should be watched.
  final String watchKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(key: watchKey),
      builder: (BuildContext context, Box<T> value, Widget child) {
        return builder(context, box);
      },
    );
  }
}
