import 'model/app_state_model.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:meta/meta.dart';
import 'colors.dart';
import 'model/product.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

const Curve easeFastOutSlowIn = const Cubic(0.4, 0.0, 0.2, 1.0);

class ShortBottomSheet extends StatefulWidget {
  @override
  _ShortBottomSheetState createState() => _ShortBottomSheetState();
}

class _ShortBottomSheetState extends State<ShortBottomSheet>
    with TickerProviderStateMixin {
  final GlobalKey _shortBottomSheetKey = GlobalKey(debugLabel: 'Short bottom sheet');
  double _cartPadding;
  double _width;
  AnimationController _controller;
  AnimationController _expandController;
  double _widthEndTime;
  double _heightEndTime;
  double _iconRowOpacityStartTime;
  double _iconRowOpacityEndTime;

  @override
  void initState() {
    super.initState();
    _adjustCartPadding(0);
    _updateWidth(0);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this
    );
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 225),
      vsync: this
    );
    _setToOpenTiming();
  }

  @override
  void dispose() {
    _controller.dispose();
    _expandController.dispose();
    super.dispose();
  }

  double _getWidth(int numProducts) {
    if(numProducts == 0) {
      return 64.0; //real number
    } else if(numProducts == 1) {
      return 136.0; //real number
    } else if(numProducts == 2) {
      return 192.0; //real number
    } else if(numProducts == 3) {
      return 248.0; //fake number - implies text field will be 30px
    } else {
      return 278.0; //real number
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
    _widthEndTime = 0.35;
    _heightEndTime = 1.0;
    _iconRowOpacityStartTime = 0.0;
    _iconRowOpacityEndTime = 0.25;
  }

  void _setToCloseTiming() {
    _widthEndTime = 0.44; // 133 ms
    _heightEndTime = 0.83; // 250 ms
    _iconRowOpacityStartTime = 0.25;
    _iconRowOpacityEndTime = 0.5;
  }

  void _open() {
    if(!_isOpen) {
      _setToOpenTiming();
      _controller.forward();
    } else { // TODO: Remove this when the carrot is available
      _setToCloseTiming();
      _controller.reverse();
    }
  }

  void _expand() {

  }

  void _adjustCartPadding(int numProducts) {
    if(numProducts == 0) {
      _cartPadding = 20.0;
    } else {
      _cartPadding = 32.0;
    }
  }

  Widget _buildStack(BuildContext context, Widget child, AppStateModel model) {
    MediaQueryData media = MediaQuery.of(context);
    int numProducts = model.productsInCart.keys.length;

    _adjustCartPadding(numProducts);
    //_updateWidth(numProducts);

    Animation<double> updateInitWidth = Tween<double>(
      begin: _width,
      end: _updateWidth(numProducts)
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Interval(
          0.0, 1.0,
          curve: easeFastOutSlowIn
        ),
      ),
    );

    Animation<double> width = Tween<double>(
      begin: _width,
      end: media.size.width, // TODO: maybe make the mediaquerydata object a Size object to cut down on calling size()
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0, _widthEndTime,
          curve: easeFastOutSlowIn,
        ),
      ),
    );

    /*updateInitWidth.addStatusListener((status) {
      if(status == AnimationStatus.completed) {
        updateInitWidth = width;
      }
    });*/

    /*width.addStatusListener((status) {
      if(status == AnimationStatus.completed) {
        width = updateInitWidth;
      }
    });*/

    Animation<double> height = Tween<double>(
      begin: 56.0, //TODO: maybe declare this as the height
      end: media.size.height,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0, _heightEndTime,
          curve: easeFastOutSlowIn,
        ),
      ),
    );

    Animation<double> opacity = Tween<double>(
      begin: 1.0,
      end: 0.0
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _iconRowOpacityStartTime, _iconRowOpacityEndTime, // TODO: could use a better name tbh
          curve: easeFastOutSlowIn,
        ),
      ),
    );

    Animation<double> cut = Tween<double>(
      begin: 24.0,
      end: 0.0
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0, _widthEndTime,
          curve: easeFastOutSlowIn,
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
          onTap: _open, // TODO: This should only work if the cart is closed - otherwise should only toggle on carrot button
          child: Material(
            type: MaterialType.canvas,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(cut.value)),
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
                    padding: EdgeInsets.only(left: _cartPadding, right: 8.0, top: 16.0),
                    child: Icon(
                        Icons.shopping_cart
                    ),
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
        builder: _buildStack,
        animation: _controller,
        model: model
      ),
    );
  }
}

class BottomSheetProducts extends StatelessWidget {
  final AnimationController _controller;

  BottomSheetProducts(
    this._controller
  );

  int getNumImagesToShow(int numProducts) {
    if(numProducts == 0) {
      return 0;
    } else if(numProducts == 1) {
      return 1;
    } else if(numProducts == 2) {
      return 2;
    } else {
      return 3;
    }
  }

  int getNumOverflowProducts(int numProducts) {
    if(numProducts > 3) {
      return numProducts - 3;
    } else {
      return 0;
    }
  }

  List<Container> _generateImageList(AppStateModel model) {
    Map<int, int> products = model.productsInCart;
    int numProducts = products.keys.length; // Don't call totalCartQuantity, because products won't be repeated in the cart preview (i.e. duplicates of a product won't be shown)
    var keys = products.keys;

    return List.generate(getNumImagesToShow(numProducts), (int index) { // reverse the products per email from kunal (may change)
        Product product = model.getProductById(keys.elementAt(keys.length - 1 - index));
        return Container(
            child: ProductIcon(_controller, false, product)
        );
      }
    );
  }

  List<Container> _buildCart(BuildContext context, AppStateModel model) {
    List<Container> productsToDisplay = _generateImageList(model);
    int numProducts = model.productsInCart.keys.length;
    int numOverflowProducts = getNumOverflowProducts(numProducts);

    if(numOverflowProducts != 0) {
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
  const AnimatedBuilderWithModel({
    Key key,
    @required Listenable animation,
    @required this.builder,
    this.child,
    @required this.model
  }) : assert(builder != null),
       super(key: key, listenable: animation);

  final TransitionWithModelBuilder builder; // TODO: could this be an anonymous builder, as used in ScopedModelDescendant?

  final Widget child;

  final AppStateModel model;

  @override
  Widget build(BuildContext context) {
    return builder(context, child, model);
  }
}
// to follow the convention of AnimatedBuilder, use a typedef for the builder
// the widget parameter in AnimatedBuilder is called TransitionBuilder,
// because it's called every time the animation changes value. This is similar,
// but it also takes a model
// TODO: should the parameter be a Model instead of an AppStateModel?
typedef Widget TransitionWithModelBuilder(BuildContext context, Widget child, AppStateModel model);

class ProductIcon extends StatelessWidget {
  final AnimationController _controller;
  final bool isAnimated;
  final Product product;

  const ProductIcon(
      this._controller,
      this.isAnimated,
      this.product
  );

  Widget _buildCart(BuildContext context) {//, Widget child) {
    Animation<double> scale = Tween<double>(
        begin: 0.0,
        end: 40.0
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
            0.0, 0.2, // tODO: real numbers
            curve: Curves.linear // tODO: real curve
        ),
      ),
    );

    if(isAnimated) {
      return Container(
          width: scale.value,
          height: scale.value,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: ExactAssetImage(
                  product.assetName, // asset name
                  package: product.assetPackage, // asset package
                ),
                fit: BoxFit.cover
            ),
            borderRadius: BorderRadius.all(
                Radius.circular(10.0)
            ),
          ),
          margin: EdgeInsets.only(left: 16.0)
      );
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
              fit: BoxFit.cover
          ),
          borderRadius: BorderRadius.all(
              Radius.circular(10.0)
          ),
        ),
        margin: EdgeInsets.only(left: 16.0)
      );
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
