import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:oym/Helper/AppBtn.dart';
import 'package:oym/Helper/SimBtn.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/ProductsListModel.dart';
import 'package:oym/Model/SearchResultParametersModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:oym/Screen/Product_Detail.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Login.dart';

class ProductList extends StatefulWidget {
  final String? keyword, id;
  final String? from;
  final String? salePer;

  const ProductList(
      {Key? key, this.id, this.keyword, this.from, this.salePer = '0'})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProduct();
}

class StateProduct extends State<ProductList> with TickerProviderStateMixin {
  bool _isLoading = true, _isProgress = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<ProductListData> productList = [];
  //List<Product> tempList = [];
  String sortBy = 'p.id', orderBy = "DESC";
  int offset = 0;
  int total = 0;
  String? totalProduct;
  bool isLoadingmore = true;
  ScrollController controller = new ScrollController();
  var filterList;
  String minPrice = "0", maxPrice = "500";
  List<String>? attnameList;
  List<String>? attsubList;
  //List<String>? selectedColor;
  List<String>? selectedColor = [];
  List<String>? selectedBrand = [];
  List<String>? selectedGender = [];
  List<String>? brandOptions = [];
  List<ColorFile> colorOptions = [];
  List<String> genderOptions = [];
  bool _isNetworkAvail = true;
  List<String> selectedId = [];
  bool _isFirstLoad = true;
  ScrollController scrollController = ScrollController();

  String selId = "";
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool listType = true;
  List<TextEditingController> _controller = [];

  ChoiceChip? choiceChip;
  RangeValues? _currentRangeValues = RangeValues(0, 500);

  // late UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getProduct();

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        if (mounted)
          setState(() {
            _isProgress = true;
            getProduct(from: 'scroll');
          });
      }
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    controller.removeListener(() {});
    for (int i = 0; i < _controller.length; i++) _controller[i].dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  @override
  Widget build(BuildContext context) {
    // userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
        appBar: getAppBar(widget.keyword!, context),
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : Stack(
                    children: <Widget>[
                      _showForm(context),
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child:
                              showCircularProgress(_isProgress, colors.primary))
                    ],
                  )
            : noInternet(context));
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  offset = 0;
                  total = 0;
                  getProduct();
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  noIntBtn(BuildContext context) {
    double width = deviceWidth!;
    return Container(
        padding: EdgeInsetsDirectional.only(bottom: 10.0, top: 50.0),
        child: Center(
            child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: colors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(80.0)),
          ),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => super.widget));
          },
          child: Ink(
            child: Container(
              constraints: BoxConstraints(maxWidth: width / 1.2, minHeight: 45),
              alignment: Alignment.center,
              child: Text(getTranslated(context, 'TRY_AGAIN_INT_LBL')!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Theme.of(context).colorScheme.white,
                      fontWeight: FontWeight.normal)),
            ),
          ),
        )));
  }

  Widget listItem(int index) {
    if (index < productList.length) {
      double discount =
          ((double.parse(productList[index].product![0].sellingPrice!) /
                      double.parse(productList[index].product![0].mrp!)) *
                  100) -
              100;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10)),
                          child: Stack(
                            children: [
                              FadeInImage(
                                image: NetworkImage(imageBaseUrl +
                                    productList[index].product![0].image1!),
                                height: 125.0,
                                width: 110.0,
                                fit: BoxFit.contain,
                                imageErrorBuilder:
                                    (context, error, stackTrace) =>
                                        erroWidget(125),
                                placeholder: placeHolder(125),
                              ),
                              double.parse(discount.toStringAsFixed(0)) != 0
                                  ? Container(
                                      decoration: BoxDecoration(
                                          color: colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          discount.toStringAsFixed(0) + "%",
                                          style: TextStyle(
                                              color: colors.whiteTemp,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9),
                                        ),
                                      ),
                                      margin: EdgeInsets.all(5),
                                    )
                                  : Container()
                            ],
                          )),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            //mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                productList[index].product![0].productTitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack,
                                        fontSize: 14),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: double.parse(productList[index]
                                        .avgRating!
                                        .toString()),
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star_rate_rounded,
                                      color: Colors.amber,
                                      //color: colors.primary,
                                    ),
                                    unratedColor: Colors.grey.withOpacity(0.5),
                                    itemCount: 5,
                                    itemSize: 18.0,
                                    direction: Axis.horizontal,
                                  ),
                                  Text(
                                    " (" +
                                        productList[index]
                                            .totalReviews
                                            .toString() +
                                        ")",
                                    style: Theme.of(context).textTheme.overline,
                                  )
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  Text(
                                      CUR_CURRENCY! +
                                          " " +
                                          productList[index]
                                              .product![0]
                                              .sellingPrice
                                              .toString() +
                                          " ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Colors.red[800],
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold)),
                                  double.parse(discount.toStringAsFixed(0)) != 0
                                      ? Text(
                                          CUR_CURRENCY! +
                                              "" +
                                              productList[index]
                                                  .product![0]
                                                  .mrp!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .overline!
                                              .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  letterSpacing: 0),
                                        )
                                      : Container(),
                                ],
                              ),
                              Text('Sold By : ${productList[index].soldBy}')
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ]),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ProductDetail(
                              productId: productList[index].product![0].prodID,
                              index: index,
                              secPos: 0,
                              list: true,
                            )),
                  );
                },
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              bottom: -15,
              end: 0,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: productList[index].isFavLoading!
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 0.7,
                            )),
                      )
                    : InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Icon(
                            productList[index].wishList == 0
                                ? Icons.favorite_border
                                : Icons.favorite,
                            size: 20,
                          ),
                        ),
                        onTap: () {
                          if (CUR_USERID != null) {
                            productList[index].wishList == 0
                                ? _setFav(productList[index])
                                : _removeFav(productList[index]);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Login()),
                            );
                          }
                        },
                      ),
              ),
            )
          ],
        ),
      );
    } else
      return Container();
  }

  _setFav(ProductListData model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {
        'custid': CUR_USERID,
        'productID': model.product![0].prodID,
        'wishlist': '1'
      };
      setState(() {
        model.isFavLoading = true;
      });
      Response response = await post(setWishListApi, body: parameter);

      var getdata = json.decode(response.body);
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];
      if (error == 200) {
        if (mounted)
          setState(() {
            model.isFavLoading = false;
            model.wishList = 1;
          });
      } else {
        setSnackbar(msg!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  _removeFav(ProductListData model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {
        'custid': CUR_USERID,
        'productID': model.product![0].prodID,
        'wishlist': '0'
      };
      setState(() {
        model.isFavLoading = true;
      });
      Response response = await post(setWishListApi, body: parameter);

      var getdata = json.decode(response.body);
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];
      if (error == 200) {
        if (mounted)
          setState(() {
            model.isFavLoading = false;
            model.wishList = 0;
          });
      } else {
        setSnackbar(msg!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> getProduct({String from = ''}) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (from == 'filter') if (mounted) setState(() => productList.clear());
    SearchParameters searchParameters = SearchParameters(
        keyword: widget.keyword,
        custid: CUR_USERID != '' ? CUR_USERID : '',
        minimumPrice: _currentRangeValues!.start.toString(),
        maximumPrice: _currentRangeValues!.end.toString(),
        from: widget.from,
        salePercent: widget.salePer,
        brand: selectedBrand,
        gender: selectedGender,
        color: selectedColor,
        startPosition: productList.length == 0
            ? '0'
            : (productList.length + 1).toString());
    var header = {'Accept': 'application/json'};
    var parameter = searchParameters.toJson();
    print(parameter);
    if (_isNetworkAvail) {
      try {
        Response response = await post(getSearchAllProductsApi,
                body: json.encode(parameter), headers: header)
            .timeout(Duration(minutes: 10));
        var getdata = json.decode(response.body);
        print(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        if (error == 200) {
          var data = getdata["data"];
          var colorData = getdata["color"];
          var brandData = getdata["brand"];
          var genderData = getdata["gender"];
          if (from != 'filter' && from != 'scroll') {
            if (getdata["color"] != null)
              colorOptions.addAll((colorData as List)
                  .map((colorData) => ColorFile.fromJson(colorData))
                  .toList());
            print(colorOptions.length);
            if (getdata["brand"] != null)
              brandOptions!.addAll(List.from(brandData));
            print(brandOptions);
            if (getdata["gender"] != null)
              genderOptions.addAll(List.from(genderData));
          }
          print(data);
          productList.addAll((data as List)
              .map((data) => new ProductListData.fromJson(data))
              .toList());
        } else if (error == 401) {
          //setSnackbar(msg!, context);
        }
        setState(() {
          _isLoading = false;
          _isProgress = false;
        });
      } on TimeoutException catch (_) {
        setState(() {
          _isLoading = false;
        });
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Widget productItem(int index, bool pad) {
    if (index < productList.length) {
      double discount =
          ((double.parse(productList[index].product![0].sellingPrice!) /
                      double.parse(productList[index].product![0].mrp!)) *
                  100) -
              100;

      return InkWell(
        child: Card(
          elevation: 0.2,
          margin: EdgeInsetsDirectional.only(
              bottom: 10, end: 10, start: pad ? 10 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5)),
                        child: FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: NetworkImage(imageBaseUrl +
                              productList[index].product![0].image1!),
                          height: double.maxFinite,
                          width: double.maxFinite,
                          fit: BoxFit.contain,
                          placeholder: placeHolder(100),
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(100),
                        )),
                    int.parse(discount.toStringAsFixed(0)) != 0
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: colors.red,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  discount.toStringAsFixed(0) + "%",
                                  style: TextStyle(
                                      color: colors.whiteTemp,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9),
                                ),
                              ),
                              margin: EdgeInsets.all(5),
                            ),
                          )
                        : Container(),
                    Divider(
                      height: 1,
                    ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      end: 0,
                      // bottom: -18,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: productList[index].isFavLoading!
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 0.7,
                                        )),
                                  )
                                : InkWell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        productList[index].wishList == 0
                                            ? Icons.favorite_border
                                            : Icons.favorite,
                                        size: 15,
                                      ),
                                    ),
                                    onTap: () {
                                      if (CUR_USERID != null) {
                                        productList[index].wishList == 0
                                            ? _setFav(productList[index])
                                            : _removeFav(productList[index]);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => Login()),
                                        );
                                      }
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  RatingBarIndicator(
                    rating:
                        double.parse(productList[index].avgRating!.toString()),
                    itemBuilder: (context, index) => Icon(
                      Icons.star_rate_rounded,
                      color: Colors.amber,
                      //color: colors.primary,
                    ),
                    unratedColor: Colors.grey.withOpacity(0.5),
                    itemCount: 5,
                    itemSize: 12.0,
                    direction: Axis.horizontal,
                    itemPadding: EdgeInsets.all(0),
                  ),
                  Text(
                    " (" + productList[index].totalReviews!.toString() + ")",
                    style: Theme.of(context).textTheme.overline,
                  )
                ],
              ),
              Row(
                children: [
                  Text(
                      " " +
                          CUR_CURRENCY! +
                          " " +
                          productList[index]
                              .product![0]
                              .sellingPrice
                              .toString() +
                          " ",
                      style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  double.parse(discount.toStringAsFixed(0)) != 0
                      ? Flexible(
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  double.parse(discount.toStringAsFixed(0)) != 0
                                      ? CUR_CURRENCY! +
                                          "" +
                                          productList[index]
                                              .product![0]
                                              .mrp
                                              .toString()
                                      : "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .overline!
                                      .copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          letterSpacing: 0),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container()
                ],
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 5.0, bottom: 5),
                child: Text(
                  productList[index].product![0].productTitle!,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontSize: 14),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          // Product model = productList[index];
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                      productId: productList[index].product![0].prodID,
                      index: index,
                      secPos: 0,
                      list: true,
                    )),
          );
        },
      );
    } else
      return Container();
  }

  _showForm(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              filterOptions(),
            ],
          ),
        ),
        Expanded(
          child: productList.length == 0
              ? getNoItem(context)
              : listType
                  ? GridView.count(
                      padding: EdgeInsetsDirectional.only(top: 5),
                      crossAxisCount: 2,
                      controller: controller,
                      childAspectRatio: 0.6,
                      physics: AlwaysScrollableScrollPhysics(),
                      children: List.generate(
                        (offset < total)
                            ? productList.length + 1
                            : productList.length,
                        (index) {
                          return (index == productList.length && isLoadingmore)
                              ? simmerSingleProduct(context)
                              : productItem(
                                  index, index % 2 == 0 ? true : false);
                        },
                      ))
                  : ListView.builder(
                      controller: controller,
                      itemCount: (offset < total)
                          ? productList.length + 1
                          : productList.length,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return (index == productList.length && isLoadingmore)
                            ? singleItemSimmer(context)
                            : listItem(index);
                      },
                    ),
        ),
      ],
    );
  }

  filterOptions() {
    return Container(
      color: Theme.of(context).colorScheme.gray,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
              onPressed: filterDialog,
              icon: Icon(
                Icons.filter_list,
              ),
              label: Text(getTranslated(context, 'FILTER')!)),
          InkWell(
            child: Icon(
              listType ? Icons.list : Icons.grid_view,
              color: colors.primary,
            ),
            onTap: () {
              productList.length != 0
                  ? setState(() {
                      listType = !listType;
                    })
                  : null;
            },
          ),
        ],
      ),
    );
  }

  void filterDialog() {
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsetsDirectional.only(top: 30.0),
                child: AppBar(
                  title: Text(
                    getTranslated(context, 'FILTER')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                  ),
                  centerTitle: true,
                  elevation: 5,
                  backgroundColor: Theme.of(context).colorScheme.white,
                  leading: Builder(builder: (BuildContext context) {
                    return Container(
                      margin: EdgeInsets.all(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4.0),
                          child: Icon(Icons.arrow_back_ios_rounded,
                              color: colors.primary),
                        ),
                      ),
                    );
                  }),
                )),
            Expanded(
                child: SingleChildScrollView(
              child: Container(
                color: Theme.of(context).colorScheme.lightWhite,
                padding:
                    EdgeInsetsDirectional.only(start: 7.0, end: 7.0, top: 7.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Container(
                            width: deviceWidth,
                            child: Card(
                                elevation: 0,
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Price Range',
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack,
                                              fontWeight: FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    )))),
                        RangeSlider(
                          values: _currentRangeValues!,
                          min: double.parse(minPrice),
                          max: double.parse(maxPrice),
                          divisions: 10,
                          labels: RangeLabels(
                            _currentRangeValues!.start.round().toString(),
                            _currentRangeValues!.end.round().toString(),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _currentRangeValues = values;
                            });
                          },
                        ),
                      ],
                    ),
                    colorOptions.isEmpty
                        ? Container()
                        : ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsetsDirectional.only(top: 10.0),
                            itemCount: 1,
                            itemBuilder: (context, index) {
                              List<Widget?> chips = [];

                              for (int i = 0; i < colorOptions.length; i++) {
                                Widget itemLabel;
                                String clr =
                                    (colorOptions[i].colorCode!.substring(1));
                                print(clr);
                                String color = "0xff" + clr;
                                print(color);
                                itemLabel = Container(
                                  width: 25,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(int.parse(color))),
                                );

                                choiceChip = ChoiceChip(
                                  selected:
                                      selectedColor!.contains(colorOptions[i]),
                                  label: itemLabel,
                                  labelPadding: EdgeInsets.all(0),
                                  selectedColor: colors.primary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        selectedColor!.contains(
                                                colorOptions[i].colorNM)
                                            ? 100
                                            : 50),
                                    side: BorderSide(
                                        color: selectedColor!.contains(
                                                colorOptions[i].colorNM)
                                            ? colors.primary
                                            : colors.black12,
                                        width: 1.5),
                                  ),
                                  onSelected: (bool selected) {
                                    if (mounted)
                                      setState(() {
                                        if (!selectedColor!.contains(
                                            colorOptions[i].colorNM!)) {
                                          selectedColor!
                                              .add(colorOptions[i].colorNM!);
                                        } else {
                                          selectedColor!
                                              .remove(colorOptions[i].colorNM!);
                                        }
                                      });
                                  },
                                );
                                chips.add(choiceChip);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: deviceWidth,
                                    child: Card(
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: new Text(
                                          'Select Colors',
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight:
                                                      FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  chips.length > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: new Wrap(
                                            children: chips
                                                .map<Widget>((Widget? chip) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: chip,
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      : Container()
                                ],
                              );
                            }),
                    genderOptions.isEmpty
                        ? Container()
                        : ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsetsDirectional.only(top: 10.0),
                            itemCount: 1,
                            itemBuilder: (context, index) {
                              List<Widget?> chips = [];

                              for (int i = 0; i < genderOptions.length; i++) {
                                Widget itemLabel;

                                itemLabel = Container(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(left: 8.0, right: 8),
                                    child: Text(genderOptions[i]),
                                  ),
                                );
                                choiceChip = ChoiceChip(
                                  selected: selectedGender!
                                      .contains(genderOptions[i]),
                                  label: itemLabel,
                                  labelPadding: EdgeInsets.all(0),
                                  selectedColor: colors.primary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        selectedGender!
                                                .contains(genderOptions[i])
                                            ? 100
                                            : 50),
                                    side: BorderSide(
                                        color: selectedGender!
                                                .contains(genderOptions[i])
                                            ? colors.primary
                                            : colors.black12,
                                        width: 1.5),
                                  ),
                                  onSelected: (bool selected) {
                                    if (mounted)
                                      setState(() {
                                        if (!selectedGender!
                                            .contains(genderOptions[i])) {
                                          selectedGender!.add(genderOptions[i]);
                                        } else {
                                          selectedGender!
                                              .remove(genderOptions[i]);
                                        }
                                      });
                                  },
                                );
                                chips.add(choiceChip);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: deviceWidth,
                                    child: Card(
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: new Text(
                                          'Select Gender',
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight:
                                                      FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  chips.length > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: new Wrap(
                                            children: chips
                                                .map<Widget>((Widget? chip) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: chip,
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      : Container()
                                ],
                              );
                            }),

                    ///Brands
                    brandOptions!.isEmpty
                        ? Container()
                        : ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsetsDirectional.only(top: 10.0),
                            itemCount: 1,
                            itemBuilder: (context, index) {
                              List<Widget?> chips = [];

                              for (int i = 0; i < brandOptions!.length; i++) {
                                Widget itemLabel;

                                itemLabel = Container(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(left: 8.0, right: 8),
                                    child: Text(brandOptions![i]),
                                  ),
                                );
                                choiceChip = ChoiceChip(
                                  selected:
                                      selectedBrand!.contains(brandOptions![i]),
                                  label: itemLabel,
                                  labelStyle: TextStyle(
                                      color: selectedBrand!
                                              .contains(brandOptions![i])
                                          ? Colors.white
                                          : Colors.black),
                                  labelPadding: EdgeInsets.all(0),
                                  selectedColor: colors.primary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        selectedBrand!
                                                .contains(brandOptions![i])
                                            ? 100
                                            : 50),
                                    side: BorderSide(
                                        color: selectedBrand!
                                                .contains(brandOptions![i])
                                            ? colors.primary
                                            : colors.black12,
                                        width: 1.5),
                                  ),
                                  onSelected: (bool selected) {
                                    if (mounted)
                                      setState(() {
                                        if (!selectedBrand!
                                            .contains(brandOptions![i])) {
                                          selectedBrand!.add(brandOptions![i]);
                                        } else {
                                          selectedBrand!
                                              .remove(brandOptions![i]);
                                        }
                                      });
                                  },
                                );
                                chips.add(choiceChip);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: deviceWidth,
                                    child: Card(
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: new Text(
                                          'Select Brands',
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight:
                                                      FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  chips.length > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: new Wrap(
                                            children: chips
                                                .map<Widget>((Widget? chip) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: chip,
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      : Container()
                                ],
                              );
                            }),
                  ],
                ),
              ),
            )),
            Container(
              color: Theme.of(context).colorScheme.white,
              child: Row(children: <Widget>[
                Container(
                  margin: EdgeInsetsDirectional.only(start: 20),
                  width: deviceWidth! * 0.4,
                  child: OutlinedButton(
                    onPressed: () {
                      if (mounted)
                        setState(() {
                          _isLoading = true;
                          total = 0;
                          offset = 0;
                          _currentRangeValues = RangeValues(0, 500);
                          selectedBrand!.clear();
                          selectedGender = null;
                          selectedColor!.clear();
                          selectedId.clear();
                          getProduct(from: 'filter');
                        });
                        Navigator.pop(context, 'Product Filter');
                    },
                    child: Text(getTranslated(context, 'DISCARD')!),
                  ),
                ),
                Spacer(),
                SimBtn(
                    size: 0.4,
                    title: getTranslated(context, 'APPLY'),
                    onBtnSelected: () {
                      if (mounted)
                        setState(() {
                          _isLoading = true;
                          total = 0;
                          offset = 0;
                          productList.clear();
                          getProduct(from: 'filter');
                        });
                      Navigator.pop(context, 'Product Filter');
                    }),
              ]),
            )
          ]);
        });
      },
    );
  }
}
