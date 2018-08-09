import 'model/app_state_model.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:meta/meta.dart';
import 'colors.dart';
import 'shopping_cart.dart';
import 'model/product.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

class ShortBottomSheet extends StatefulWidget {
  const ShortBottomSheet({Key key}) : super(key: key);

  @override
  _ShortBottomSheetState createState() => _ShortBottomSheetState();

  static _ShortBottomSheetState of(BuildContext context, {bool nullOk: false}) {
    assert(nullOk != null);
    assert(context != null);
    final _ShortBottomSheetState result = context
        .ancestorStateOfType(const TypeMatcher<_ShortBottomSheetState>());
    if (nullOk || result != null) {
      return result;
    }
    throw new FlutterError(
        'ShortBottomSheet.of() called with a context that does not contain a ShortBottomSheet.\n');
  }
}

class _ShortBottomSheetState extends State<ShortBottomSheet>
    with TickerProviderStateMixin {
  final GlobalKey _shortBottomSheetKey =
      GlobalKey(debugLabel: 'Short bottom sheet');
  // The padding between the left edge of the Material and the shopping cart icon
  double _cartPadding;
  // The width of the Material, calculated by _getWidth & based on the number of
  // products in the cart.
  double _width;
  // Controller for the opening and closing of the ShortBottomSheet
  AnimationController _controller;
  // Controller for the expansion (i.e. when products are added) of the ShortBottomSheet
  AnimationController _expandController;
  // Represent the differing intervals of time over which the animations take place.
  double _widthStartTime;
  double _widthEndTime;
  double _heightStartTime;
  double _heightEndTime;
  double _thumbnailOpacityStartTime;
  double _thumbnailOpacityEndTime;
  double _cartOpacityStartTime;
  double _cartOpacityEndTime;
  // Tracks the size of the screen so animations can be updated appropriately.
  Size _mediaSize;
  // Animations for the opening and closing of the ShortBottomSheet
  Animation<double> _widthAnimation;
  Animation<double> _heightAnimation;
  Animation<double> _thumbnailOpacityAnimation;
  Animation<double> _cartOpacityAnimation;
  Animation<double> _shapeAnimation;
  // Curves that represent the two curves that compose the emphasized easing curve.
  final Cubic accelerateCurve = const Cubic(0.3, 0.0, 0.8, 0.15);
  final Cubic decelerateCurve = const Cubic(0.05, 0.7, 0.1, 1.0);
  final cartHeight = 56.0;
  bool _revealCart;

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
    _mediaSize = Size.zero;
    _revealCart = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _expandController.dispose();
    super.dispose();
  }

  // Returns true if the screen size has changed, false otherwise.
  bool _dimensionsNeedUpdate(BuildContext context) {
    if (_mediaSize != MediaQuery.of(context).size) {
      return true;
    }
    return false;
  }

  // Updates the animations for the opening/closing of the ShortBottomSheet,
  // using the size of the screen.
  void _updateAnimations(BuildContext context) {
    _mediaSize = MediaQuery.of(context).size;
    double mediaWidth = _mediaSize.width;
    double mediaHeight = _mediaSize.height;

    _widthAnimation = TweenSequence(
      elements: <TweenSequenceElement<double>>[
        new TweenSequenceElement<double>(
          // 1/6 of duration = 40% (0.4) of property delta
          tween: new Tween<double>(
              begin: _width, end: _width + (mediaWidth - _width) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        new TweenSequenceElement<double>(
          tween: new Tween<double>(
              begin: _width + (mediaWidth - _width) * 0.4, end: mediaWidth),
          curve: decelerateCurve,
          weight: 5.0 / 6.0,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _widthStartTime,
          _widthEndTime,
        ),
      ),
    );

    _heightAnimation = TweenSequence(
      elements: <TweenSequenceElement<double>>[
        TweenSequenceElement<double>(
          tween: Tween<double>(
              begin: cartHeight, end: (mediaHeight - cartHeight) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        TweenSequenceElement<double>(
          tween: Tween<double>(
              begin: (mediaHeight - cartHeight) * 0.4, end: mediaHeight),
          curve: decelerateCurve,
          weight: 5.0 / 6.0,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _heightStartTime,
          _heightEndTime,
        ),
      ),
    );

    _thumbnailOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(_thumbnailOpacityStartTime, _thumbnailOpacityEndTime,
            curve: Curves.linear),
      ),
    );

    _cartOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(_cartOpacityStartTime, _cartOpacityEndTime,
          curve: Curves.linear),
    )..addStatusListener((status) {
      print('cart opacity: $status');
    });

    _shapeAnimation = TweenSequence(
      elements: <TweenSequenceElement<double>>[
        TweenSequenceElement<double>(
          tween: Tween<double>(begin: 24.0, end: (24.0 - 0.0) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        TweenSequenceElement<double>(
          tween: Tween<double>(begin: (24.0 - 0.0) * 0.4, end: 0.0),
          curve: decelerateCurve,
          weight: 5.0 / 6.0,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          _widthStartTime,
          _widthEndTime,
        ),
      ),
    );
  }

  // Returns the correct width of the ShortBottomSheet based on the number of
  // products in the cart.
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

  bool _widthNeedsUpdate(int numProducts) {
    if (_width != _getWidth(numProducts)) {
      return true;
    }
    return false;
  }

  // Updates _width based on the number of products in the cart.
  void _updateWidth(int numProducts) {
    _width = _getWidth(numProducts);
  }

  // Returns true if the cart is open and false otherwise.
  bool get _isOpen {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  // Sets the times used by open/close animations to the timing used by the open
  // animation.
  void _setToOpenTiming() {
    setState(() {
      _widthStartTime = 0.0;
      _widthEndTime = 0.35; // 105 ms
      _heightStartTime = 0.0;
      _heightEndTime = 1.0; // 300 ms
      _thumbnailOpacityStartTime = 0.0;
      _thumbnailOpacityEndTime = 0.25;
      _cartOpacityStartTime = 0.25;
      _cartOpacityEndTime = 0.75;
    });
  }

  // Sets the times used by open/close animations to the timing used by the
  // close animation.
  void _setToCloseTiming() {
    setState(() {
      _widthStartTime = 0.17; // 50 ms
      _widthEndTime = 0.72; // 217 ms
      _heightStartTime = 0.33; // 100 ms
      _heightEndTime = 1.0; // 200 ms
      _thumbnailOpacityStartTime = 0.75;
      _thumbnailOpacityEndTime = 1.0;
      _cartOpacityStartTime = 0.25;
      _cartOpacityEndTime = 0.75;
    });
  }

  // Opens the ShortBottomSheet if it's open, otherwise does nothing.
  void open() {
    if (!_isOpen) {
      _setToOpenTiming();
      _controller.forward();
    }
  }

  // Closes the ShortBottomSheet if it's open, otherwise does nothing.
  void close() {
    if (_isOpen) {
      _setToCloseTiming();
      _controller.reverse();
    }
  }

  // Changes the padding between the left edge of the Material and the cart icon
  // based on the number of products in the cart (padding increases when > 0
  // products.)
  void _adjustCartPadding(int numProducts) {
    _cartPadding = numProducts == 0 ? 20.0 : 32.0;
  }

  Widget _buildThumbnails(int numProducts) {
    return Opacity(
      opacity: _thumbnailOpacityAnimation.value,
      child: Row(children: <Widget>[
        AnimatedPadding(
            padding: EdgeInsets.only(left: _cartPadding, right: 8.0), //16.0),
            child: Icon(
              Icons.shopping_cart,
              semanticLabel: "Cart",
            ),
            duration: Duration(milliseconds: 225)),
        Container(
          width: numProducts > 3
              ? _width - 96
              : _width - 64, // TODO: fix this hardcoded value
          height: 56.0, //needed because otherwise vertical is unbounded
          child: Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: ProductList(_expandController),
          ),
        ),
        ExtraProductsNumber()
      ]),
    );
  }

  Widget _buildShoppingCartPage() {
    return Opacity(
        opacity: _cartOpacityAnimation.value, child: ShoppingCartPage());
  }

  Widget _buildCart(BuildContext context, Widget child, AppStateModel model) {
    // numProducts is the number of different products in the cart (does not
    // include multiple of the same product).
    int numProducts = model.productsInCart.keys.length;

    // Update the variable used when building the cart padding.
    _adjustCartPadding(numProducts);

    // Update animations only if the screen size has changed or the number of
    // products has changed, since the animations rely on the screen size and
    // number of products, but it's costly to recreate the animations each time
    // the build method is called. Dubious that this really saves much, however,
    // since the only time one of these things isn't true is when there are
    // more than three products in the cart. Another option might be to just to
    // make the width into an object and see if the references will be enough to
    // auto-update the animation
    if (_dimensionsNeedUpdate(context) || _widthNeedsUpdate(numProducts)) {
      _updateWidth(numProducts);
      _updateAnimations(context);
    }

    if(_thumbnailOpacityAnimation.value == 0.0) {
      _revealCart = true;
    } else if (_cartOpacityAnimation.value == 0.0) {
      _revealCart = false;
    }

    return AnimatedSize(
        key: _shortBottomSheetKey,
        duration: Duration(milliseconds: 225),
        curve: Curves.easeInOut,
        vsync: this,
        alignment: Alignment.topLeft,
        child: Container(
          width: _widthAnimation.value,
          height: _heightAnimation.value,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: open,
            child: Material(
                type: MaterialType.canvas,
                animationDuration: Duration(milliseconds: 0),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(_shapeAnimation.value)),
                ),
                elevation: 4.0,
                color: kShrinePink50,
                child: _revealCart
                    ? _buildShoppingCartPage()
                    : _buildThumbnails(numProducts)
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 10.0;
    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => AnimatedBuilderWithModel(
          builder: _buildCart, animation: _controller, model: model),
    );
  }
}

class ProductList extends StatefulWidget {
  final AnimationController _controller;
  ProductList(this._controller);

  AnimationController get controller => _controller;

  @override
  ProductListState createState() {
    return ProductListState();
  }
}

class ProductListState extends State<ProductList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  //_list represents the list that actively manipulates the AnimatedList,
  // meaning that it needs to be updated by _internalList
  ListModel _list;
  //internalList represents the list as it is updated by the AppStateModel
  List<int> _internalList;

  @override
  void initState() {
    super.initState();
    _list = ListModel(
      listKey: _listKey,
      initialItems:
          ModelFinder<AppStateModel>().of(context).productsInCart.keys.toList(),
      removedItemBuilder: _buildRemovedThumbnail,
    );
    _internalList = List<int>.from(
        _list.list); //initialize internal list to ListModel's list
  }

  Widget _buildRemovedThumbnail(
      int item, BuildContext context, Animation<double> animation) {
    return ProductThumbnail(
        animation,
        animation, // TODO: put in the right animation here!
        ModelFinder<AppStateModel>().of(context).getProductById(item));
  }

  Widget _buildThumbnail(
      BuildContext context, int index, Animation<double> animation) {
    Animation<double> thumbnailSize =
        Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        curve: Interval(
          0.25, 0.75,
          curve: Curves.easeIn,
        ),
        parent: animation,
      ),
    );

    Animation<double> opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          curve: Interval(
            0.25,
            0.75,
            curve: Curves.linear,
          ),
          parent: animation),
    );

    AppStateModel model = ModelFinder<AppStateModel>()
        .of(context); // TODO: don't rely on the ModelFinder
    int productId = _list[index];
    Product product = model.getProductById(productId);
    assert(product != null);

    return ProductThumbnail(thumbnailSize, opacity, product);
  }

  /// Returns the element that has been inserted/removed between the two lists.
  /// If the lists are the same length, assume nothing has changed.
  /// If the internalList is shorter than the ListModel, an item has been removed.
  /// If the internalList is longer, then an item has been added.
  void calculateDifference() {
    _internalList =
        ModelFinder<AppStateModel>().of(context).productsInCart.keys.toList();
    while (_internalList.length != _list.length) {
      // TODO: make this conditional a Real Thing
      int index = 0;
      while (_internalList.length > 0 &&
          _list.length > 0 &&
          index < _internalList.length &&
          index < _list.length &&
          _internalList[index] == _list[index]) {
        index++;
      }

      if (_internalList.length < _list.length) {
        _list.removeAt(index);
      } else if (_internalList.length > _list.length) {
        _list.insert(_list.length, _internalList[index]);
      }
    }
  }

  Widget _buildAnimatedList() {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      itemBuilder: _buildThumbnail,
      initialItemCount: _list.length,
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(), // Cart shouldn't scroll
    );
  }

  @override
  Widget build(BuildContext context) {
    calculateDifference();
    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) => _buildAnimatedList());
  }
}

class ExtraProductsNumber extends StatelessWidget {
  /// Calculates the number to be displayed at the end of the row if there are
  /// more than three products in the cart. This calculates overflow products,
  /// including their duplicates (but not duplicates of products shown as
  /// thumbnails).
  int _calculateOverflow(AppStateModel model) {
    Map<int, int> productMap = model.productsInCart;
    // List created to be able to access products by index instead of ID
    // Order is guaranteed because productsInCart returns a LinkedHashMap
    List<int> products = productMap.keys.toList();
    int overflow = 0;
    int numProducts = products.length;
    if (numProducts > 3) {
      for (int i = 3; i < numProducts; i++) {
        // TODO: if the order of the products changes that go into the visible cart, this'll need to change
        overflow += productMap[products[i]];
      }
    }
    return overflow;
  }

  Widget _buildOverflow(AppStateModel model, BuildContext context) {
    if (model.productsInCart.length > 3) {
      int numOverflowProducts = _calculateOverflow(model);
      int displayedOverflowProducts = numOverflowProducts <= 99
          ? numOverflowProducts
          : 99; // Maximum of 99 so the padding doesn't get funky
      return Container(
        child: Text('+$displayedOverflowProducts',
            style: Theme.of(context).primaryTextTheme.button),
      );
    } else {
      return Container(); //so that this object is never null
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<AppStateModel>(
        builder: (builder, child, model) => _buildOverflow(model, context));
  }
}

class ProductThumbnail extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> opacityAnimation;
  final Product product;

  ProductThumbnail(this.animation, this.opacityAnimation, this.product);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: opacityAnimation,
        //duration: Duration(milliseconds: 150),
        child: ScaleTransition(
            scale: animation,
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
                margin: EdgeInsets.only(left: 16.0))));
  }
}

class ListModel {
  ListModel({
    @required this.listKey,
    @required this.removedItemBuilder,
    Iterable<int> initialItems,
  })  : assert(listKey != null),
        assert(removedItemBuilder != null),
        _items = List<int>.from(initialItems ?? <int>[]);

  final GlobalKey<AnimatedListState> listKey;
  final dynamic removedItemBuilder;
  final List<int> _items;

  AnimatedListState get _animatedList => listKey.currentState;

  void insert(int index, int item) {
    print('index: $index');
    _items.insert(index, item);
    print('list length: ${_items.length}');
    _animatedList.insertItem(index);
  }

  int removeAt(int index) {
    final int removedItem = _items.removeAt(index);
    if (removedItem != null) {
      _animatedList.removeItem(index,
          (BuildContext context, Animation<double> animation) {
        return removedItemBuilder(removedItem, context, animation);
      });
    }
  }

  int get length => _items.length;

  int operator [](int index) => _items[index];

  int indexOf(int item) => _items.indexOf(item);

  List<int> get list => _items;
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
  const TweenSequenceElement(
      {@required this.tween, @required this.weight, this.curve})
      : assert(tween != null),
        assert(weight != null && weight > 0.0);
  final Tween<T> tween;
  final double weight;
  final Curve curve;
}

class TweenSequence<T> extends Animatable<T> {
  TweenSequence({@required this.elements}) {
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
    final double tCurve =
        element.curve == null ? tInterval : element.curve.transform(tInterval);
    return element.tween.lerp(tCurve);
  }

  @override
  T evaluate(Animation<double> animation) {
    final double t = animation.value;
    assert(t >= 0.0 && t <= 1.0);
    if (t == 1.0) return _evaluate(t, elements.length - 1);
    for (int index = 0; index < elements.length; index++) {
      if (intervals[index].contains(t)) return _evaluate(t, index);
    }
    // no interval contains t? assert failure
  }
}
