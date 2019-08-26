part of hive_flutter;

/// Signature for a function that builds a widget with an error [Object].
typedef ErrorBoxWidgetBuilder = Widget Function(
    BuildContext context, Object error);

/// Signature for a function that builds a widget when the [Box] is
/// currently loading.
typedef LoadingBoxWidgetBuilder = Widget Function(BuildContext context);

/// A general-purpose widget which rebuilds itself when the [Box] in the
/// [openBox] function is loaded. While the box is not loaded a placeholder
/// [placeholderBuilder] is specified to inform the user. In the case of the
/// box failing to open an error widget [errorBuilder] is displayed.
class HiveBuilder extends StatelessWidget {
  HiveBuilder.openBox(
      {Key key,
      @required this.openBox,
      @required this.builder,
      @required this.placeholderBuilder,
      @required this.errorBuilder})
      : assert(openBox != null),
        assert(builder != null),
        assert(errorBuilder != null),
        assert(placeholderBuilder != null),
        super(key: key);

  /// The function where the box is opened
  final Future<Box> Function() openBox;

  /// Called when the box finished loading
  final BoxWidgetBuilder builder;

  /// Called while the box is loading
  final LoadingBoxWidgetBuilder placeholderBuilder;

  /// Called when the box finished loading with an error
  final ErrorBoxWidgetBuilder errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: openBox(),
      builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return builder(context, snapshot.data);
          } else {
            return errorBuilder(context, snapshot.error);
          }
        } else {
          return placeholderBuilder(context);
        }
      },
    );
  }
}
