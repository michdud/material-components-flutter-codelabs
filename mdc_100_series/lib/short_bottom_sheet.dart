import 'model/app_state_model.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:meta/meta.dart';
import 'colors.dart';
import 'model/product.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

const EmphasizedEasing easeFastOutExtraSlowIn = const EmphasizedEasing();

class ShortBottomSheet extends StatefulWidget {
  @override
  _ShortBottomSheetState createState() => _ShortBottomSheetState();
}

class _ShortBottomSheetState extends State<ShortBottomSheet>
    with TickerProviderStateMixin {
  final GlobalKey _shortBottomSheetKey =
      GlobalKey(debugLabel: 'Short bottom sheet');
  double _cartPadding;
  double _width;
  AnimationController _controller;
  AnimationController _expandController;
  double _widthStartTime;
  double _widthEndTime;
  double _heightStartTime;
  double _heightEndTime;
  double _cutStartTime;
  double _cutEndTime;
  double _iconRowOpacityStartTime;
  double _iconRowOpacityEndTime;

  /*final Interval _widthEnter = Interval(0.0, 0.35, curve: easeFastOutExtraSlowIn);
  final Interval _widthExit = Interval(0.17, 0.72, curve: easeFastOutExtraSlowIn);
  final Interval _heightEnter = Interval(0.0, 1.0, curve: easeFastOutExtraSlowIn);
  final Interval _heightExit = Interval(0.33, 1.0, curve: easeFastOutExtraSlowIn);
  final Interval _iconRowOpacityEnter = Interval(0.0, 0.25, curve: easeFastOutExtraSlowIn);
  final Interval _iconRowOpacityExit = Interval(0.25, 0.5, curve: easeFastOutExtraSlowIn);*/

  @override
  void initState() {
    super.initState();
    _adjustCartPadding(0);
    _updateWidth(0);
    _controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _expandController = AnimationController(
        duration: const Duration(milliseconds: 225), vsync: this);
    _setToOpenTiming();
  }

  @override
  void dispose() {
    _controller.dispose();
    _expandController.dispose();
    super.dispose();
  }

  double _getWidth(int numProducts) {
    if (numProducts == 0) {
      return 64.0;
    } else if (numProducts == 1) {
      return 136.0;
    } else if (numProducts == 2) {
      return 192.0;
    } else if (numProducts == 3) {
      return 248.0;
    } else {
      return 278.0;
    }
  }

  double _updateWidth(int numProducts) {
    _width = _getWidth(numProducts);
    return _width;
  }

  bool get _isOpen {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _setToOpenTiming() {
    _widthStartTime = 0.0;
    _widthEndTime = 0.35; // 105 ms
    _cutStartTime = 0.0;
    _cutEndTime = 0.35;
    _heightStartTime = 0.0;
    _heightEndTime = 1.0; // 300 ms
    _iconRowOpacityStartTime = 0.0;
    _iconRowOpacityEndTime = 0.25;
  }

  void _setToCloseTiming() {
    _widthStartTime = 0.17; // 50 ms
    _widthEndTime = 0.72; // 217 ms
    _cutStartTime = 0.17;
    _cutEndTime = 0.72;
    _heightStartTime = 0.33; // 100 ms
    _heightEndTime = 1.0; // 200 ms
    _iconRowOpacityStartTime = 0.25;
    _iconRowOpacityEndTime = 0.5;
  }

  void _open() {
    if (!_isOpen) {
      _setToOpenTiming();
      _controller.forward();
    } else {
      // TODO: Remove this when the carrot is available
      _setToCloseTiming();
      _controller.reverse();
    }
  }

  void _adjustCartPadding(int numProducts) {
    if (numProducts == 0) {
      _cartPadding = 20.0;
    } else {
      _cartPadding = 32.0;
    }
  }

  Widget _buildStack(BuildContext context, Widget child, AppStateModel model) {
    MediaQueryData media = MediaQuery.of(context);
    int numProducts = model.productsInCart.keys.length;

    _adjustCartPadding(numProducts);

    Animation<double> updateInitWidth =
        Tween<double>(begin: _width, end: _updateWidth(numProducts)).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Interval(0.0, 1.0, curve: easeFastOutExtraSlowIn),
      ),
    );

    Animation<double> width = Tween<double>(
      begin: _width,
      end: media.size
          .width, // TODO: maybe make the mediaquerydata object a Size object to cut down on calling size()
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _widthStartTime,
          _widthEndTime,
          curve: easeFastOutExtraSlowIn,
        ),
      ),
    );

    Animation<double> height = Tween<double>(
      begin: 56.0, //TODO: maybe declare this as the height
      end: media.size.height,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _heightStartTime,
          _heightEndTime,
          curve: easeFastOutExtraSlowIn,
        ),
      ),
    );

    Animation<double> opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _iconRowOpacityStartTime,
          _iconRowOpacityEndTime, // TODO: could use a better name
          curve: easeFastOutExtraSlowIn,
        ),
      ),
    );

    // TODO: this animation looks funky even though it should be = width
    Animation<double> cut = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.9, // temporarily hardcoded
          1.0,
          curve: easeFastOutExtraSlowIn,
        ),
      ),
    );

    // TODO: add animation for the icons

    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => SizedBox(
            key: _shortBottomSheetKey,
            width: width.value,
            height: height.value,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  _open, // TODO: This should only work if the cart is closed - otherwise should only toggle on carrot button
              child: Material(
                type: MaterialType.canvas,
                shape: BeveledRectangleBorder(
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(cut.value)),
                ),
                elevation: 4.0,
                color: kShrinePink50,
                child: Opacity(
                  opacity: opacity.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: _cartPadding, right: 8.0, top: 16.0),
                        child: Icon(Icons.shopping_cart),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: BottomSheetProducts(_controller),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 1.0;
    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => AnimatedBuilderWithModel(
          builder: _buildStack, animation: _controller, model: model),
    );
  }
}

class BottomSheetProducts extends StatelessWidget {
  final AnimationController _controller;

  BottomSheetProducts(this._controller);

  int getNumImagesToShow(int numProducts) {
    // TODO: fix this
    if (numProducts == 0) {
      return 0;
    } else if (numProducts == 1) {
      return 1;
    } else if (numProducts == 2) {
      return 2;
    } else {
      return 3;
    }
  }

  int getNumOverflowProducts(int numProducts) {
    if (numProducts > 3) {
      return numProducts - 3;
    } else {
      return 0;
    }
  }

  List<Container> _generateImageList(AppStateModel model) {
    Map<int, int> products = model.productsInCart;
    // Don't call totalCartQuantity, because products won't be repeated in the cart preview (i.e. duplicates of a product won't be shown)
    int numProducts = products.keys.length;
    var keys = products.keys;

    return List.generate(getNumImagesToShow(numProducts), (int index) {
      // reverse the products per email from Kunal (may change)
      Product product =
          model.getProductById(keys.elementAt(keys.length - 1 - index));
      return Container(child: ProductIcon(_controller, false, product));
    });
  }

  List<Container> _buildCart(BuildContext context, AppStateModel model) {
    List<Container> productsToDisplay = _generateImageList(model);
    int numProducts = model.productsInCart.keys.length;
    int numOverflowProducts = getNumOverflowProducts(numProducts);

    if (numOverflowProducts != 0) {
      productsToDisplay.add(
        Container(
          margin: EdgeInsets.only(left: 16.0),
          child: Text('+$numOverflowProducts',
              style: Theme.of(context).primaryTextTheme.button),
        ),
      );
    }

    return productsToDisplay;
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => Row(
            children: _buildCart(context, model),
          ),
    );
  }
}

class AnimatedBuilderWithModel extends AnimatedWidget {
  const AnimatedBuilderWithModel(
      {Key key,
      @required Listenable animation,
      @required this.builder,
      this.child,
      @required this.model})
      : assert(builder != null),
        super(key: key, listenable: animation);

  final TransitionWithModelBuilder builder;

  final Widget child;

  final AppStateModel model;

  @override
  Widget build(BuildContext context) {
    return builder(context, child, model);
  }
}

// To follow the convention of AnimatedBuilder, use a typedef for the builder
// the widget parameter in AnimatedBuilder is called TransitionBuilder,
// because it's called every time the animation changes value. This is similar,
// but it also takes a model
// TODO: should the parameter be a Model instead of an AppStateModel?
typedef Widget TransitionWithModelBuilder(
    BuildContext context, Widget child, AppStateModel model);

class ProductIcon extends StatelessWidget {
  final AnimationController _controller;
  final bool isAnimated;
  final Product product;

  const ProductIcon(this._controller, this.isAnimated, this.product);

  Widget _buildCart(BuildContext context) {
    //, Widget child) {
    Animation<double> scale = Tween<double>(begin: 0.0, end: 40.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.2, // TODO: real numbers
            curve: Curves.linear // TODO: real curve
            ),
      ),
    );

    if (isAnimated) {
      return Container(
          width: scale.value,
          height: scale.value,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: ExactAssetImage(
                  product.assetName, // asset name
                  package: product.assetPackage, // asset package
                ),
                fit: BoxFit.cover),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          margin: EdgeInsets.only(left: 16.0));
    } else {
      return Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: ExactAssetImage(
                  product.assetName, // asset name
                  package: product.assetPackage, // asset package
                ),
                fit: BoxFit.cover),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          margin: EdgeInsets.only(left: 16.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCart(context);
    /*return AnimatedBuilder(
      builder: _buildCart,
      animation: _controller
    );*/
  }
}

/// This implementation creates the two curves required for this motion,
/// but transformed so that they fit within the 0.0 - 1.0 interval. Instead of
/// "physically" stitching the curves together, the curve that is used for
/// animation is switched based on the time at which the animation is currently.
/// This leads to skipping/jumpiness (change timeDilation to 10.0 to see this
/// more clearly).
class EmphasizedEasing extends Curve {
  //curve from the original spec
  final Cubic accelerateCurve = const Cubic(0.3, 0.0, 0.8,
      0.15); // divide the x-coords of these points by ~6 (6 = 1 / 0.1666)
  final Cubic accelerateCurveModified = const Cubic(
      0.05, 0.0, 0.1333, 0.15); // modified to fit into the time interval
  //curve from the original spec
  final Cubic decelerateCurve = const Cubic(0.05, 0.7, 0.1,
      1.0); // divide the x-coords of these points by ~1.2 (1.2 = 1 / (1 - 0.1666)) and then add 0.1666
  final Cubic decelerateCurveModified = const Cubic(
      0.1333, 0.15, 0.2499, 1.0); // modified to fit into the time interval
  final double midpointX = 0.166666;

  const EmphasizedEasing();

  /// Spec: When at 1/6 (0.166666...) of total duration, interpolator is 0.4
  // given some t, return the y-value from this curve
  @override
  double transform(double t) {
    //this is wrong because the accelerateCurve is only going to get through 0.16666 of itself instead of the full curve
    if (t <= midpointX) {
      return accelerateCurveModified.transform(t);
    } else {
      return decelerateCurveModified.transform(t);
    }
  }
}
