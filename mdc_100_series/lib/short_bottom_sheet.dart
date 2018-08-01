import 'model/app_state_model.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:meta/meta.dart';
import 'colors.dart';
import 'model/product.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

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
  double _iconRowOpacityStartTime;
  double _iconRowOpacityEndTime;

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
    setState(() {
      _widthStartTime = 0.0;
      _widthEndTime = 0.35; // 105 ms
      _heightStartTime = 0.0;
      _heightEndTime = 1.0; // 300 ms
      _iconRowOpacityStartTime = 0.0;
      _iconRowOpacityEndTime = 0.25;
    });
  }

  void _setToCloseTiming() {
    setState(() {
      _widthStartTime = 0.17; // 50 ms
      _widthEndTime = 0.72; // 217 ms
      _heightStartTime = 0.33; // 100 ms
      _heightEndTime = 1.0; // 200 ms
      _iconRowOpacityStartTime = 0.25;
      _iconRowOpacityEndTime = 0.5;
    });
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

  double _adjustCartPadding(int numProducts) { // TODO: fix this
    if (numProducts == 0) {
      _cartPadding = 20.0;
    } else {
      _cartPadding = 32.0;
    }
    return _cartPadding;
  }

  Widget _buildStack(BuildContext context, Widget child, AppStateModel model) {
    MediaQueryData media = MediaQuery.of(context);

    int numProducts = model.productsInCart.keys.length;

    _adjustCartPadding(numProducts);
    _updateWidth(numProducts);

    final cartHeight = 56.0;
    final Cubic accelerateCurve = const Cubic(0.3, 0.0, 0.8, 0.15);
    final Cubic decelerateCurve = const Cubic(0.05, 0.7, 0.1, 1.0);

    // maybe need to do _getWidth instead because a user might add a product to
    // the cart while the sheet is opening
    final TweenSequence<double> openWidthSequence = new TweenSequence(
      elements: <TweenSequenceElement<double>>[
        new TweenSequenceElement<double>(
          // 1/6 of duration = 40% (0.4) of property delta
          tween: new Tween<double>(begin: _width, end: _width + (media.size.width - _width) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        new TweenSequenceElement<double>(
          tween: new Tween<double>(begin: _width + (media.size.width - _width) * 0.4, end: media.size.width),
          curve: decelerateCurve,
          weight: 5.0 / 6.0,
        ),
      ],
    );

    Animation<double> openWidth = openWidthSequence.animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            _widthStartTime,
            _widthEndTime,
          ),
        ),
    );

    ProxyAnimation width = ProxyAnimation(openWidth);

    final TweenSequence<double> heightSequence = new TweenSequence(
      elements: <TweenSequenceElement<double>>[
        new TweenSequenceElement<double>(
          tween: new Tween<double>(begin: cartHeight, end: (media.size.height - cartHeight) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        new TweenSequenceElement<double>(
            tween: new Tween<double>(begin: (media.size.height - cartHeight) * 0.4, end: media.size.height),
            curve: decelerateCurve,
            weight: 5.0 / 6.0,
        ),
      ],
    );

    Animation<double> height = heightSequence.animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            _heightStartTime,
            _heightEndTime,
          ),
        ),
    );

    final TweenSequence<double> opacitySequence = new TweenSequence(
      elements: <TweenSequenceElement<double>>[
        new TweenSequenceElement<double>(
          tween: new Tween<double>(begin: 1.0, end: 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        new TweenSequenceElement<double>(
          tween: new Tween<double>(begin: 0.4, end: 0.0),
          curve: decelerateCurve,
          weight: 5.0 / 6.0,
        ),
      ]
    );

    Animation<double> opacity = opacitySequence.animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _iconRowOpacityStartTime,
          _iconRowOpacityEndTime, // TODO: could use a better name
        ),
      ),
    );

    final TweenSequence<double> cutSequence = TweenSequence(
      elements: <TweenSequenceElement<double>>[
        TweenSequenceElement<double>(
          tween: Tween<double>(begin: 24.0, end: (24.0 - 0.0) * 0.4),
          curve: accelerateCurve, //Interval(_widthStartTime, _widthStartTime + _widthEndTime * 0.17, curve: accelerateCurve),
          weight: 0.17,
        ),
        TweenSequenceElement<double>(
          tween: Tween<double>(begin: (24.0 - 0.0) * 0.4, end: 0.0),
          curve: decelerateCurve, //Interval(_widthStartTime + _widthEndTime * 0.17, _widthEndTime, curve: decelerateCurve),
          weight: 0.93,
        ),
      ],
    );

    Animation<double> cut = cutSequence.animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _widthStartTime,
          _widthEndTime,
        ),
      ),
    );

    Animation<double> padding = Tween<double>(
      begin: _cartPadding,
      end: _adjustCartPadding(numProducts),
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Curves.easeInOut // TODO: maybe a diff animation? ask around
      ),
    );

    // TODO: add animation for the thumbnails

    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => AnimatedSize(
        //key: _shortBottomSheetKey, //this is throwing an error but should it actually be in there?
        duration: Duration(milliseconds: 225),
        curve: Curves.easeInOut,
        vsync: this,
        alignment: Alignment.centerLeft,
        child: SizedBox(
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
              elevation: 4.0, // TODO: check this #
              color: kShrinePink50,
              child: Opacity(
                opacity: opacity.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AnimatedPadding(
                      padding: EdgeInsets.only(
                          left: _cartPadding, right: 8.0, top: 16.0),
                      child: Icon(
                        Icons.shopping_cart,
                        semanticLabel: "Cart",
                      ),
                      duration: Duration(milliseconds: 225)
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        //child: ProductList()
                        child: BottomSheetProducts(_expandController),
                      ),
                    ),
                  ],
                ),
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

class ProductList extends StatelessWidget {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  ListModel _list;

  Widget _buildThumbnail(
      BuildContext context, int index, Animation<double> animation) {
    print('productlist _buildthumbnail');
    AppStateModel model = ModelFinder<AppStateModel>().of(context); // TODO: don't rely on the ModelFinder
    int productId = model.productsInCart[index];
    Product product = model.getProductById(productId);
    assert(product != null);

    return ProductThumbnail( //there's a bottom padding issue
      animation, product
    );
  }

  @override
  Widget build(BuildContext context) {
    print('productlist build');

    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) =>
      Container(
        color: Color.fromRGBO(50, 50, 50, 1.0),
        child: Text('hi'),
        /*child: AnimatedList(
              itemBuilder: _buildThumbnail,
              initialItemCount: model.productsInCart.length, // TODO: don't rely on the ModelFinder
              scrollDirection: Axis.horizontal,
            ),*/
      ),

      );
  }
}

class ProductThumbnail extends StatelessWidget {
  final Animation<double> animation;
  final Product product;

  ProductThumbnail(this.animation, this.product);

  @override
  Widget build(BuildContext context) {
    print(product.assetName);
    print('productthumbnail');
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
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
        margin: EdgeInsets.only(left: 16.0)
      )
    );
  }
}

/// this class adapted from the AnimatedList example and also probably won't work!
class ListModel { // TODO: this probably won't work with the actual model
  ListModel({
    @required this.listKey,
    @required this.removedItemBuilder,
    @required context
  }) : assert(listKey != null),
       assert(removedItemBuilder != null),
       model = ModelFinder<AppStateModel>().of(context);
  
  final GlobalKey<AnimatedListState> listKey;
  final dynamic removedItemBuilder;
  final AppStateModel model;
  final BuildContext context;
  
  AnimatedListState get _animatedList => listKey.currentState;
  
  void insert(int item) {
    model.addProductToCart(item);
    _animatedList.insertItem(model.productsInCart.length - 1); // TODO: Fix this for when there's > 3 products
  }

  int removeItem(int index) {
    int removedItem = model.productsInCart.keys.elementAt(index); // TODO: this probably isn't safe
    if(model.productsInCart.containsKey(removedItem)) {
      model.removeItemFromCart(removedItem);
      _animatedList.removeItem(index,
          (BuildContext context, Animation<double> animation) {
        return removedItemBuilder(removedItem, context, animation);
      });
    }
    return removedItem;
  }

  int get length => model.productsInCart.length;

  int operator [](int index) => model.productsInCart.keys.elementAt(index);

  //int indexOf(int item) => model.productsInCart.keys.
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
          model.getProductById(keys.elementAt(index));
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

typedef Widget TransitionWithModelBuilder(
    BuildContext context, Widget child, AppStateModel model);

class ProductIcon extends StatelessWidget {
  final AnimationController _controller;
  bool isAnimated;
  final Product product;

  ProductIcon(this._controller, this.isAnimated, this.product);

  Widget _buildIcon(BuildContext context, Widget child) {
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
    //return _buildCart(context);
    return AnimatedBuilder(
      builder: _buildIcon,
      animation: _controller
    );
  }
}

/// Below code authored by hansmuller

class _Interval {
  const _Interval(this.start, this.end) : assert(end > start);
  final double start;
  final double end;
  bool contains(double t) => t >= start && t < end;
  double value(double t) => (t - start) / (end - start);
  String toString() => '<$start, $end>';
}

class TweenSequenceElement<T> {
  const TweenSequenceElement({
    @required this.tween,
    @required this.weight,
    this.curve
  }) : assert(tween != null), assert(weight != null && weight > 0.0);
  final Tween<T> tween;
  final double weight;
  final Curve curve;
}

class TweenSequence<T> extends Animatable<T> {
  TweenSequence({ @required this.elements }) {
    assert(elements != null && elements.isNotEmpty);

    double totalWeight = 0.0;
    for (TweenSequenceElement<T> element in elements)
      totalWeight += element.weight;

    double start = 0.0;
    for (int i = 0; i < elements.length; i++) {
      final double end = start + elements[i].weight / totalWeight;
      intervals.add(new _Interval(start, end));
      start = end;
    }
  }

  final List<TweenSequenceElement<T>> elements;
  final List<_Interval> intervals = <_Interval>[];

  T _evaluate(double t, int index) {
    final TweenSequenceElement<T> element = elements[index];
    final double tInterval = intervals[index].value(t);
    final double tCurve =  element.curve == null ? tInterval : element.curve.transform(tInterval);
    return element.tween.lerp(tCurve);
  }

  @override
  T evaluate(Animation<double> animation) {
    final double t = animation.value;
    assert(t >= 0.0 && t <= 1.0);
    if (t == 1.0)
      return _evaluate(t, elements.length - 1);
    for (int index = 0; index < elements.length; index++) {
      if (intervals[index].contains(t))
        return _evaluate(t, index);
    }
    // no interval contains t? assert failure
  }
}
