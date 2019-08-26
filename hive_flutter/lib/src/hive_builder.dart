part of hive_flutter;

typedef AsyncBoxWidgetBuilder = Widget Function(BuildContext context, Box box);
typedef ErrorBoxWidgetBuilder = Widget Function(
    BuildContext context, Object error);
typedef LoadingBoxWidgetBuilder = Widget Function(BuildContext context);

class HiveBuilder extends StatelessWidget {
  final Future<Box> Function() openBox;
  final AsyncBoxWidgetBuilder builder;
  final LoadingBoxWidgetBuilder placeholderBuilder;
  final ErrorBoxWidgetBuilder errorBuilder;

  const HiveBuilder.openBox(
      {Key key,
      @required this.openBox,
      @required this.builder,
      @required this.placeholderBuilder,
      @required this.errorBuilder})
      : super(key: key);

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
