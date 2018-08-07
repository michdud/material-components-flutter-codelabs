import 'model/app_state_model.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:meta/meta.dart';
import 'colors.dart';
import 'shopping_cart.dart';
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

  double _adjustCartPadding(int numProducts) {
    // TODO: fix this
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
          tween: new Tween<double>(
              begin: _updateWidth(numProducts),
              end: _updateWidth(numProducts) +
                  (media.size.width - _updateWidth(numProducts)) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        new TweenSequenceElement<double>(
          tween: new Tween<double>(
              begin: _updateWidth(numProducts) +
                  (media.size.width - _updateWidth(numProducts)) * 0.4,
              end: media.size.width),
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

    final TweenSequence<double> heightSequence = TweenSequence(
      elements: <TweenSequenceElement<double>>[
        TweenSequenceElement<double>(
          tween: Tween<double>(
              begin: cartHeight, end: (media.size.height - cartHeight) * 0.4),
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        TweenSequenceElement<double>(
          tween: Tween<double>(
              begin: (media.size.height - cartHeight) * 0.4,
              end: media.size.height),
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

    final TweenSequence<double> opacitySequence =
        TweenSequence(elements: <TweenSequenceElement<double>>[
      TweenSequenceElement<double>(
        tween: Tween<double>(begin: 1.0, end: 0.4),
        curve: accelerateCurve,
        weight: 1.0 / 6.0,
      ),
      TweenSequenceElement<double>(
        tween: Tween<double>(begin: 0.4, end: 0.0),
        curve: decelerateCurve,
        weight: 5.0 / 6.0,
      ),
    ]);

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
          curve: accelerateCurve,
          weight: 1.0 / 6.0,
        ),
        TweenSequenceElement<double>(
          tween: Tween<double>(begin: (24.0 - 0.0) * 0.4, end: 0.0),
          curve: decelerateCurve,
          weight: 5.0 / 6.0,
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

    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) => Container(
              alignment: Alignment.bottomRight,
              child: AnimatedSize(
                key: _shortBottomSheetKey,
                duration: Duration(milliseconds: 225),
                curve: Curves.easeInOut,
                vsync: this,
                alignment: Alignment.bottomLeft,
                //child: SizedBox(
                child: Container(
                  width: width.value,
                  height: height.value,
                  //constraints: BoxConstraints.tight(Size(width.value, height.value)),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap:
                        _open, // TODO: This should only work if the cart is closed - otherwise should only toggle on carrot button
                    child: Material(
                      type: MaterialType.canvas,
                      animationDuration: Duration(milliseconds: 0),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(cut.value)),
                      ),
                      elevation: 4.0, // TODO: check this #
                      color: kShrinePink50,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Opacity(
                                    opacity: opacity.value,
                                    child: Row(children: <Widget>[
                                      AnimatedPadding(
                                          padding: EdgeInsets.only(
                                              left: _cartPadding,
                                              right: 8.0), //16.0),
                                          child: Icon(
                                            Icons.shopping_cart,
                                            semanticLabel: "Cart",
                                          ),
                                          duration:
                                              Duration(milliseconds: 225)),
                                      Container(
                                        width: numProducts > 3
                                            ? _width - 96
                                            : _width -
                                                64, // TODO: fix this hardcoded value
                                        height:
                                            56.0, //needed because otherwise vertical is unbounded
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: 8.0, bottom: 8.0),
                                          child: ProductList(_expandController),
                                        ),
                                      ),
                                      ExtraProductsNumber()
                                    ]),
                                  ),
                                  //Row(children: <Widget>[

                                    //Container(height: height.value, child: ShoppingCartPage()),
                                  //]),
                                ]),
                            Expanded(child: ShoppingCartPage(),),
                          ]),
                    ),
                  ),
                ),
              ),
            ));
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
  ListModel
      _list; //_list represents the list that actively manipulates the AnimatedList, meaning that it needs to be updated by _internalList
  List<int>
      _internalList; //internalList represents the list as it is updated by the AppStateModel

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
          0.25, 0.75, //this is currently 150 ms
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

  /// Calculates the number to be displayed at the end of the row if there are
  /// more than three products in the cart.
  /* int calculateOverflow(AppStateModel model) {
    int overflow = 0;
    if (_list.length > 3) {
      for(int i = 2; i < _list.length; i++) { // TODO: if the order of the products changes that go into the visible cart, this'll need to change
        overflow += model.productsInCart[_list[i]];
      }
    }
    return overflow;
  }

  Widget _buildOverflow(AppStateModel model) {
    if (_list.length > 3) {
      int numOverflowProducts = calculateOverflow(model);
      return Container(
        margin: EdgeInsets.only(left: 16.0),
        child: Text('+$numOverflowProducts',
            style: Theme.of(context).primaryTextTheme.button),
      );
    } else {
      return Container(); //so that this object is never null
    }
  }*/

  @override
  Widget build(BuildContext context) {
    calculateDifference();
    return ScopedModelDescendant<AppStateModel>(
      builder: (context, child, model) => Container(
            child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              itemBuilder: _buildThumbnail,
              initialItemCount: _list.length < 3 ? _list.length : 3,
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(), // Cart shouldn't scroll
            ),
          ),
    );
  }
}

class ExtraProductsNumber extends StatelessWidget {
  /// Calculates the number to be displayed at the end of the row if there are
  /// more than three products in the cart. This calculates overflow products,
  /// including their duplicates (but not duplicates of products shown as
  /// thumbnails).
  int calculateOverflow(AppStateModel model) {
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
      int numOverflowProducts = calculateOverflow(model);
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
    _items.insert(index, item);
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

/*class BottomSheetProducts extends StatelessWidget {
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
      Product product = model.getProductById(keys.elementAt(index));
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
    return AnimatedBuilder(builder: _buildIcon, animation: _controller);
  }
}*/

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
