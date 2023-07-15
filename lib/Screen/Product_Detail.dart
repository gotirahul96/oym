import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/ProductDetailModel.dart';
import 'package:oym/Model/ProductsListModel.dart';
import 'package:oym/Model/SellerVideoModel.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/Cart.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:oym/Screen/ProductList.dart';
import 'package:oym/Screen/ReviewList.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Helper/modal_progress_hud.dart';
import 'Favorite.dart';
import 'Login.dart';
import 'Product_Preview.dart';
import 'Search.dart';

class ProductDetail extends StatefulWidget {

  final int? secPos, index;
  final bool? list;

  final String? productId;

  const ProductDetail(
      {Key? key, this.secPos, this.index, this.list,this.productId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateItem();
}

List<String>? sliderList = [];
// List<User> reviewList = [];
// List<imgModel> revImgList = [];
int offset = 0;
int total = 0;
int cartCount = 0;
int maxquantity = 0;
int minquantity = 0;
class StateItem extends State<ProductDetail> with TickerProviderStateMixin {

  final _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ChoiceChip? choiceChip, tagChip;
  bool _isProgress = false, _isLoading = false;
  var star1 = "0", star2 = "0", star3 = "0", star4 = "0", star5 = "0";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  late Animation<double> _progressAnimation;
  late AnimationController _progressAnimcontroller;

  late Animation<double> _cartAnimation;
  late AnimationController _cartAnimcontroller;

  var isDarkTheme;
  late ShortDynamicLink shortenedLink;
  String? shareLink;
  late String curPin;
  late double growStepWidth, beginWidth, endWidth = 0.0;

  ////
   List<ProductListData>? relatedProductsData = [];
   ProductDetailData productDetailData = ProductDetailData();
   List<OtherSizes> otherSizes = [];
   List<OtherColors> otherColors = [];
   List<Specification> otherspecifications = [];
   List<TwoReviews> tworeviewList = [];
   SellerVideoModel? sellerVideoModel;

  @override
  void initState() {
    super.initState();
    print(widget.productId);
    _getRelatedProducts();
    _getProductDetail();
    _getSellerVideo();
    offset = 0;
    total = 0;

    _progressAnimcontroller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _setProgressAnim(deviceWidth!, 1);

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

    _cartAnimcontroller = new AnimationController(
        duration: new Duration(milliseconds : 400), vsync: this);
    _cartAnimcontroller.addStatusListener((status) { 
      if(status == AnimationStatus.completed){
        _cartAnimcontroller.reverse();
      }
    });
    
    _cartAnimation = new Tween<double>(
      begin: 25.0,
      end: 35.0,
    ).animate(new CurvedAnimation(
      parent: _cartAnimcontroller,
      curve: new Interval(
        0.0,
        0.0,
      ),
    ));
  }

  _setProgressAnim(double maxWidth, int curPageIndex) {
    setState(() {
      growStepWidth = maxWidth / sliderList!.length;
      beginWidth = growStepWidth * (curPageIndex - 1);
      endWidth = growStepWidth * curPageIndex;

      _progressAnimation = Tween<double>(begin: beginWidth, end: endWidth)
          .animate(_progressAnimcontroller);
    });

    _progressAnimcontroller.forward();
  }


  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> createDynamicLink() async {
    var documentDirectory;

    if (Platform.isIOS)
      documentDirectory = (await getApplicationDocumentsDirectory()).path;
    else
      documentDirectory = (await getExternalStorageDirectory())!.path;

    final response1 = await get(Uri.parse(productDetailData.images![0]));
    final bytes1 = response1.bodyBytes;

    final File imageFile = File('$documentDirectory/${productDetailData.product![0].productTitle}.png');
    imageFile.writeAsBytesSync(bytes1);
    Share.shareFiles(['$documentDirectory/${productDetailData.product![0].productTitle}.png'],
        text:
            "${productDetailData.product![0].productTitle}\n${shortenedLink.shortUrl.toString()}\n$shareLink");
  }

  

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
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
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
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

  _getProductDetail({String? from = '',String? size = '',String? color = '',String? groupId = '',String? sellerId = ''}) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {
        'productID' : from != '' ? '0' : widget.productId,
        'custid': CUR_USERID == null ? '' : CUR_USERID,
        'size': size,
        'color': color,
        'groupid': groupId,
        'sellerid': sellerId,
        };
      print(parameter);
      if(from != ''){
        sliderList!.clear();
        otherColors.clear();
        otherSizes.clear();
        otherspecifications.clear();
        productDetailData = ProductDetailData();
        _setProgressAnim(deviceWidth!, 1);
        
      }
      Response response = await post(getProductDetailsApi,body: parameter);
      if(mounted)
      setState(() {
        _isProgress = true;
      });
      var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        print(response.body);
        if (error == 200) {
      if (mounted)
        setState(() {
          List<ProductDetailData> tempData = [];
          var data = getdata["data"];
          if(data != null)
          tempData.addAll((data as List).map((data) => ProductDetailData.fromJson(data)).toList());
          var sizes = data[0]["otherSizes"];
          if(sizes != null)
          otherSizes.addAll((sizes as List).map((sizes) => OtherSizes.fromJson(sizes)).toList());
          var colorss = data[0]["otherColors"];
          print(data[0]["otherColors"]);
          if(colorss != null)
          otherColors.addAll((colorss as List).map((colorss) => OtherColors.fromJson(colorss)).toList());
          var specification = data[0]["specification"];
          if(specification != null)
          otherspecifications.addAll((specification as List).map((specification) => Specification.fromJson(specification)).toList());
          productDetailData = tempData[0];
          print(productDetailData.totalReviews);
          sliderList = productDetailData.images;
          _setProgressAnim(deviceWidth!, 1);
          cartCount = int.parse(productDetailData.product![0].minQtyBuy!);
          minquantity = int.parse(productDetailData.product![0].minQtyBuy!);
          maxquantity = int.parse(productDetailData.product![0].stock!) > int.parse(productDetailData.product![0].maxQtyBuy!) ?int.parse(productDetailData.product![0].maxQtyBuy!) : int.parse(productDetailData.product![0].stock!);
          tworeviewList = productDetailData.twoReviews ?? [];
          star1 = productDetailData.reviews1.toString();
          star2 = productDetailData.reviews2.toString();
          star3 = productDetailData.reviews3.toString();
          star4 = productDetailData.reviews4.toString();
          star5 = productDetailData.reviews5.toString();
        });
        setState(() {
          _isProgress = false;
        });
        // if(from != ''){
        // if(mounted)
        // setState((){
        //   _isLoading = false;
        // });
        // }
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

  _getRelatedProducts() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      
      var parameter = {
        'productID' : widget.productId,
        };
       
      Response response = await post(getRelatedProductsApi,body: parameter);

      var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        if (error == 200) {
         var data = getdata["data"];
         print(getdata["data"]);
          if (mounted)
        setState(() {
          relatedProductsData?.addAll((data as List).map((data) => ProductListData.fromJson(data)).toList());
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

  _getSellerVideo() async{
     _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      
      var parameter = {
        'productID' : widget.productId,
        };
       
      Response response = await post(sellerVideoApi,body: parameter);

      var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        if (error == 200) {
         
          if (mounted)
        setState(() {
          sellerVideoModel = SellerVideoModel.fromJson(getdata);
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

  Future<void> addToCart() async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    
    settingProvider.getPrefrence('token').then((value) async {
       var parameter = {
      'customerID': CUR_USERID,
      'productID': productDetailData.product![0].prodID,
      'quantity' : cartCount.toString(),
      'flag' : ''
    };
    print(parameter);
    
    if (_isNetworkAvail) {
      setState(()=> _isLoading = true);
      Response response = await post(addToCartApi,body: parameter, headers: {
              "Authorization": 'Bearer ' + value!,
            }).timeout(Duration(minutes: 10));

    print(response.body);
    var getdata = json.decode(response.body);
    int error = int.parse(getdata["error"]);
    String? msg = getdata["message"];
    if (error == 200) {
          setState(() => cartCount = int.parse(productDetailData.product![0].minQtyBuy!));
          _cartAnimcontroller.forward();
           context.read<UserProvider>().setCartCount(
              getdata["cartLength"].toString());
          setSnackbar(msg!, context);
      } else if(error == 401) {
        setSnackbar(msg!, context);
      }

      setState(()=> _isLoading = false);
    }
    else {
      if (mounted)
        setState(()=> _isLoading = true);
        setSnackbar('No internet', context);
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    /* SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));*/

    return  ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: Scaffold(
          key: _scaffoldKey,
          bottomNavigationBar: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.black26, blurRadius: 10)],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // IconButton(
                        //   onPressed: (){
                        //     sharePostWithDynamicLink(
                        //       postId: productDetailData.product![0].prodID
                        //     );
                        //   },
                        //   icon: Icon(Icons.share, color: colors.primary),
                        // ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextButton.icon(
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.black),
                              onPressed: () {
                                if (CUR_USERID != null) {
                                  if (cartCount != 0) {
                                  addToCart();
                                } else {
                                  setSnackbar('Please add quantiy.', context);
                                }
                                } else {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => Login()));
                                }
                              },
                              icon: Icon(
                                Icons.shopping_bag,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                child: Text('ADD TO CART',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              )),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          child: TextButton.icon(
                              style: TextButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.btnColor),
                              onPressed: () {
                                Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Cart(
                                fromBottom: false,
                                productId: productDetailData.product![0].prodID,
                              ),
                            ),
                          );
                              },
                              icon: Padding(
                                padding: const EdgeInsets.only(left : 6.0),
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: Theme.of(context).colorScheme.white,
                                ),
                              ),
                              label: Text(''),),
                        ),
                      ],
                    ),
                  ),
          body: _isNetworkAvail
              ? Stack(
                  children: <Widget>[
                   productDetailData.avgRating != null ? 
                   _showContent() 
                   :
                    showCircularProgress(true, colors.primary),
                 
                  ],
                )
              : noInternet(context),
        
      ),
    );
  }

  List<T?> map<T>(List list, Function handler) {
    List<T?> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Widget _slider() {
    double height = MediaQuery.of(context).size.height * .48;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return InkWell(
      onTap: () {
        
      },
      child: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
            height: height,
            width: double.infinity,
            child: PageView.builder(
              itemCount: sliderList!.length,
              scrollDirection: Axis.horizontal,
              controller: _pageController,
              reverse: false,
              onPageChanged: (index) {
                _progressAnimcontroller.reset(); //reset the animation first
                _setProgressAnim(deviceWidth!, index + 1);
                // context.read<ProductDetailProvider>().setCurSlider(index);
              },
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: (){
                    Navigator.push(
            context,
            PageRouteBuilder(
          // transitionDuration: Duration(seconds: 1),
          pageBuilder: (_, __, ___) => ProductPreview(
            pos: index,
                    secPos: 0,
                    index: 0,
                    id: "$index",
            imgList: sliderList,
          ),
            ));
                  },
                  child: Stack(
                    children: [
                      Container(
                        height : 300,
                        width: double.infinity,
                        color: Colors.white,
                        child: FadeInImage(
                          image: NetworkImage(imageBaseUrl + sliderList![index]),
                          placeholder: AssetImage(
                            "assets/images/placeholder.png",
                          ),
                          height: height,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(height),
                          //  fit: extendImg ? BoxFit.fill : BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: <Widget>[
                      AnimatedProgressBar(
                        animation: _progressAnimation,
                      ),
                      Expanded(
                        child: Container(
                          height: 5.0,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.white),
                        ),
                      )
                    ],
                  ))),
          favImg(),
          
        ],
      ),
    );
  }

  Widget favImg() {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      end: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: productDetailData.isFavLoading ?? false
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 0.7,
                          )),
                    )
                  :  InkWell(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  productDetailData.wishList == 0
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  size: 20,
                                )),
                            onTap: () {
                              if (CUR_USERID != null) {
                                productDetailData.wishList == 0
                                    ? _setFav(productDetailData)
                                    : _removeFav(productDetailData);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Login()),
                                );
                              }
                            })
                      ),
        ),
      ),
    );
  }

  // indicatorImage() {
  //   String? indicator = widget.model!.indicator;
  //   return Positioned.fill(
  //       child: Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Align(
  //         alignment: Alignment.bottomLeft,
  //         child: indicator == "1"
  //             ? SvgPicture.asset("assets/images/vag.svg")
  //             : indicator == "2"
  //                 ? SvgPicture.asset("assets/images/nonvag.svg")
  //                 : Container()),
  //   ));
  // }

  _rate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RatingBarIndicator(
            rating: double.parse('${productDetailData.avgRating!}'),
            itemBuilder: (context, index) => Icon(
              Icons.star,
              color: colors.secondary,
            ),
            itemCount: 5,
            itemSize: 12.0,
            direction: Axis.horizontal,
          ),
          Text(
            " " + productDetailData.avgRating!.toString(),
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.lightBlack),
          ),
          Text(
            " | " + productDetailData.totalReviews!.toString() + " Ratings",
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.lightBlack),
          )
        ],
      ),
    );
  }

  _price() {
    
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(CUR_CURRENCY! + " " + productDetailData.product![0].sellingPrice.toString(),
                style: Theme.of(context).textTheme.headline6!.copyWith(
                  color: Colors.red[800],fontSize: 22
                )),
            Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 3.0, bottom: 5, top: 3),
                    child: Row(
                            children: <Widget>[
                              GestureDetector(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.remove,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                onTap: cartCount > minquantity ? () {
                                  if (cartCount > minquantity){
                                    setState(() => cartCount--);
                                  }
                                  else {
                                    //setSnackbar('Quanity cannot be less than $minquantity', context);
                                    Fluttertoast.showToast(msg: 'Quanity cannot be less than $minquantity');
                                  }
                                } : null,
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                color: Colors.transparent,
                                child: Center(child: Text('$cartCount')),
                              ), 

                              GestureDetector(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.add,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                onTap: cartCount < maxquantity ? () {
                                  if(cartCount < maxquantity) {
                                    setState(() => cartCount++);
                                  }
                                  else {
                                    setSnackbar('Max Quantity Reached.', context);
                                  }
                                } : null,
                              )
                            ],
                          ),
                  ),
          ],
        ));
  }


  _offPrice() {
    double price = double.parse(productDetailData.product?[0].sellingPrice ?? '0.0');

    if (price.round() != 0) {
      var off = ((double.parse(productDetailData.product![0].sellingPrice!) / double.parse(productDetailData.product![0].mrp!)) * 100) - 100 ;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: <Widget>[
            Text(
              CUR_CURRENCY! + " " + productDetailData.product![0].mrp!,
              style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  decoration: TextDecoration.lineThrough, letterSpacing: 0),
            ),
            Text(" | " + off.toString().replaceAll('-', '') + "% off",
                style: Theme.of(context)
                    .textTheme
                    .overline!
                    .copyWith(color: colors.primary, letterSpacing: 0,fontSize: 13)),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Text(
        productDetailData.product?[0].productTitle! ?? '',
        style: Theme.of(context)
            .textTheme
            .subtitle1!
            .copyWith(color: Theme.of(context).colorScheme.lightBlack),
      ),
    );
  }

  _desc() {
    return productDetailData.product![0].description!.isNotEmpty
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 8, end: 8, top: 8, bottom: 5),
            child: Html(data: productDetailData.product![0].description!),
          )
        : Container();
  }

  void _pincodeCheck() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(shrinkWrap: true, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(Icons.close),
                                ),
                              ),
                              TextFormField(
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                validator: (val) => validatePincode(val!,
                                    getTranslated(context, 'PIN_REQUIRED')),
                                onSaved: (String? value) {
                                  if (value != null) curPin = value;
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.location_on),
                                  hintText:
                                      getTranslated(context, 'PINCODEHINT_LBL'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SimBtn(
                                    size: 1.0,
                                    title: getTranslated(context, 'APPLY'),
                                    onBtnSelected: () async {
                                      if (validateAndSave()) {
                                       
                                      }
                                    }),
                              ),
                            ],
                          )),
                    ))
              ]),
            );
            //});
          });
        });
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }
  
 
  
_setFav(ProductDetailData model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      
      var parameter = {
        'custid': CUR_USERID, 
        'productID' : model.product![0].prodID,
        'wishlist' : '1'
        };
       setState(() {
          model.isFavLoading = true;
        });
      Response response = await post(setWishListApi,body: parameter);

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

  _removeFav(ProductDetailData model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      
      var parameter = {
        'custid': CUR_USERID, 
        'productID' : model.product![0].prodID,
        'wishlist' : '0'
        };
       setState(() {
          model.isFavLoading = true;
        });
      Response response = await post(setWishListApi,body: parameter);

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

  _showContent() {
    //qtyController.text=
    

    //String id=widget.model!.id!;

    //print("id****${widget.model!.id!}****${widget.model!.name!}");

    return Column(children: <Widget>[
      Expanded(
          child: CustomScrollView(
            slivers: <Widget>[
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * .43,
          floating: false,
          pinned: true,
          backgroundColor: colors.primary,
          leading: Builder(builder: (BuildContext context) {
            return Container(
              margin: EdgeInsets.all(10),
              //decoration: shadow(),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
          actions: [
            IconButton(
                icon: SvgPicture.asset(
                  imagePath + "search.svg",
                  height: 20,
                  color: Colors.white
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Search(),
                      ));
                }),
            IconButton(
                icon: SvgPicture.asset(
                  imagePath + "desel_fav.svg",
                  height: 20,
                  color: Colors.white
                ),
                onPressed: () {
                  CUR_USERID != null
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Favorite(),
                          ))
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Login(),
                          ));
                }),
            Selector<UserProvider, String>(
              builder: (context, data, child) {
                return IconButton(
                  icon: Stack(
                    children: [
                      Center(
                          child:
                              AnimatedBuilder(
                                animation: _cartAnimation,
                                builder: (context, snapshot) {
                                  return SvgPicture.asset(imagePath + "appbarCart.svg",width: _cartAnimation.value,color: Colors.white);
                                },
                                child : Text('test')
                              )),
                      (data.isNotEmpty && data != "0")
                          ? new Positioned(
                              bottom: 20,
                              right: 0,
                              child: Container(
                                  //  height: 20,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red),
                                  child: new Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(3),
                                      child: new Text(
                                        data,
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.white),
                                      ),
                                    ),
                                  )),
                            )
                          : Container()
                    ],
                  ),
                  onPressed: () {
                    CUR_USERID != null
                        ? Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Cart(
                                fromBottom: false,
                              ),
                            ),
                          )
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Login(),
                            ));
                  },
                );
              },
              selector: (_, homeProvider) => homeProvider.curCartCount,
            )
          ],
          title: Text(
            productDetailData.product?[0].productTitle ?? '',
            maxLines: 1,
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _slider(),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            //SingleChildScrollView( controller: notificationcontroller,
            Stack(
             // crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          _title(),
                          _rate(),
                          _price(),
                          _offPrice(),
                          _desc(),
                          
                        ],
                      ),
                    ),
                   
                  //sellerVideoModel!.videoLink!.isNotEmpty ?  _sellerVideo() : Container(),
                  otherColors.isNotEmpty ?  _availableColors() : Container(),
                  otherSizes.isNotEmpty ?  _availableSizes() : Container(),
                  otherspecifications.isNotEmpty ?  _availableSpecifications() : Container(),
                    //_deliverPincode(),
                    //Divider(),
                    _sellerDetail(),
                  
                     //Divider(),
                     _notMadeInIndia(),
                    Card(
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _reviewTitle(),
                            _reviewStar(),
                            _review(),
                          ],
                        ),
                      ),
                // reviewList.length > 0 ? Divider() : Container(),
                relatedProductsData!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          getTranslated(context, 'MORE_PRODUCT')!,
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      )
                    : Container(),
                 relatedProductsData!.isNotEmpty ? _relatedProducts() : Container(),
                  ],
                ),
              ],
            )
          ]),
        )
      ])),
    ]);
  }

  Widget _availableColors(){
    return Card(
                elevation: 0,
                   child: Padding(padding:   EdgeInsets.only(left : 8, right: 8, top: 8, bottom: 5),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text('Available Colors',
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 100,
              margin: EdgeInsets.only(top: 10),
              width: double.infinity,
              
              child: ListView.builder(
                itemCount: otherColors.length,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context,index){
                       return  Container(
                         decoration: BoxDecoration(
                border: Border.all(
                  color: otherColors[index].color == productDetailData.product![0].color ? colors.primary : Colors.white
                )
              ),
                         child: InkWell(
                             onTap: (){
                               
                               _getProductDetail(
                                 from:'slection',
                                 size: otherColors[index].size,
                                 color: otherColors[index].color,
                                 groupId: otherColors[index].groupID,
                                 sellerId: otherColors[index].sellerID,
                               );
                             },
                             child: Padding(
                               padding: EdgeInsets.all(2),
                               child: FadeInImage(
                                    image: NetworkImage(imageBaseUrl + otherColors[index].image1!),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.contain,
                                    imageErrorBuilder: (context, error, stackTrace) =>
                                        erroWidget(
                                      double.maxFinite,
                                    ),
                                    //errorWidget: (context, url, e) => placeHolder(width),
                                    placeholder: placeHolder(
                                      double.maxFinite,
                                    ),
                                  ),
                             ),
                           ),
                       );
                       }),
            )
                            ],
                          ),
                        ),
                      );
  }

 Widget _availableSpecifications(){
   return Card(
     elevation: 0,
     child: Padding(
       padding: EdgeInsets.only(left : 8, right: 8, top: 8, bottom: 5),
       child : Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text('Specifications - ',
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView.builder(
                  itemCount: otherspecifications.length,
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context,index){
                         return  Padding(
                           padding: EdgeInsets.only(top : 10),
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(otherspecifications[index].name! + '   -   '),
                           Expanded(
                             child: Container(
                               child: Text(otherspecifications[index].value!,
                style: Theme.of(context).textTheme.subtitle2!.copyWith(fontSize: 18,
                    color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),),
                             ),
                           ),
                             ],
                           ),
                         );
                     }),
              ),
                )
         ],
       )
       ),
   );
 }

 Widget _availableSizes(){
        return Card(
                elevation: 0,
                   child: Padding(padding:   EdgeInsets.only(left : 8, right: 8, top: 8, bottom: 5),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text('Available Sizes',
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 25,
              margin: EdgeInsets.only(top: 10),
              width: double.infinity,
              child: ListView.builder(
                itemCount: otherSizes.length,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context,index){
                       return  Container(
                         margin: EdgeInsets.only(right : 10),
                         decoration: BoxDecoration(
                border: Border.all(
                  color: otherSizes[index].size == productDetailData.product![0].size ? colors.primary : Colors.white
                )
              ),
                         child: InkWell(
                             onTap: (){
                               _getProductDetail(
                                 from:'slection',
                                 size: otherSizes[index].size,
                                 color: otherSizes[index].color,
                                 groupId: otherSizes[index].groupID,
                                 sellerId: otherSizes[index].sellerID,
                               );
                             },
                             child: Container(
                               decoration: BoxDecoration(
                                 color: Colors.grey[200],
                                 //borderRadius: BorderRadius.circular(5)
                               ),
                               child: Padding(
                                 padding:  EdgeInsets.only(left : 10.0,top: 2,right: 10,bottom : 2),
                                 child: Text('${otherSizes[index].size}'),
                               ),
                             ),
                           ),
                       );
                   }),
                )
                            ],
                          ),
                        ),
                      );
  }
  Widget _relatedProducts(){
      return Column(
        children: [
           relatedProductsData!.isNotEmpty  ? Container(
                    height: 230,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.builder(
                          physics: AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          //controller: _controller,
                          itemCount: relatedProductsData!.length,
                          itemBuilder: (context, index) {
                            return (index == relatedProductsData!.length)
                                ? simmerSingle()
                                : productItem(index);
                          },
                        )) : Container(),
        ],
      );
  }
  simmerSingle() {
    return Container(
        //width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.simmerBase,
          highlightColor: Theme.of(context).colorScheme.simmerHigh,
          child: Container(
            width: deviceWidth! * 0.45,
            height: 250,
            color: Theme.of(context).colorScheme.white,
          ),
        ));
  }

  // _madeIn() {
  //   String? madeIn = widget.model!.madein;

  //   return madeIn != null && madeIn.isNotEmpty
  //       ? Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 20),
  //           child: ListTile(
  //             trailing: Text(madeIn),
  //             dense: true,
  //             title: Text(
  //               getTranslated(context, 'MADE_IN')!,
  //               style: Theme.of(context).textTheme.subtitle2,
  //             ),
  //           ),
  //         )
  //       : Container();
  // }

  Widget productItem(int index) {
    if (index < relatedProductsData!.length) {
      double discount = ((double.parse(relatedProductsData![index].product![0].sellingPrice!) / double.parse(relatedProductsData![index].product![0].mrp!)) * 100) - 100;

      double width = deviceWidth! * 0.45;

      return Container(
          height: 250,
          width: width,
          child: Card(
            elevation: 0.2,
            margin: EdgeInsetsDirectional.only(bottom: 5, end: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
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
                            image: NetworkImage(imageBaseUrl + relatedProductsData![index].product![0].image1!),
                            height: double.maxFinite,
                            width: double.maxFinite,
                            fit: extendImg ? BoxFit.fill : BoxFit.contain,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(
                              double.maxFinite,
                            ),
                            //errorWidget: (context, url, e) => placeHolder(width),
                            placeholder: placeHolder(
                              double.maxFinite,
                            ),
                          ),
                        ),
                        discount != 0
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      discount.toStringAsFixed(0).toString().replaceAll('-',"") + "%",
                                      style: TextStyle(
                                          color: Colors.white,
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
                        /*   Positioned.directional(
                          textDirection: Directionality.of(context),
                          end: 0,
                          bottom: -18,
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: productList[index].isFavLoading!
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        height: 15,
                                        width: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 0.7,
                                        )),
                                  )
                                : InkWell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        productList[index].isFav == "0"
                                            ? Icons.favorite_border
                                            : Icons.favorite,
                                        size: 15,
                                      ),
                                    ),
                                    onTap: () {

                                      if (CUR_USERID != null) {
                                        productList[index].isFav == "0"
                                            ? _setFav(index)
                                            : _removeFav(index);
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
                        ),*/
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 5.0,
                      top: 5,
                    ),
                    child: Row(
                      children: [
                        RatingBarIndicator(
                          rating: double.parse(relatedProductsData![index].avgRating!.toString()),
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
                          " (" + relatedProductsData![index].totalReviews.toString() + ")",
                          style: Theme.of(context).textTheme.overline,
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 5.0, top: 5, bottom: 5),
                    child: Text(
                      relatedProductsData![index].product![0].productTitle!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Text(" " + CUR_CURRENCY! + " " + relatedProductsData![index].product![0].sellingPrice.toString() + " ",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold)),
                      Text(
                        discount !=
                                0
                            ? CUR_CURRENCY! +
                                "" +
                                relatedProductsData![index].product![0].mrp.toString()
                            : "",
                        style: Theme.of(context).textTheme.overline!.copyWith(
                            decoration: TextDecoration.lineThrough,
                            letterSpacing: 0),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {

                Navigator.push(
                  context,
                  PageRouteBuilder(
                      // transitionDuration: Duration(seconds: 1),
                      pageBuilder: (_, __, ___) => ProductDetail(
                          productId : relatedProductsData![index].product![0].prodID,
                          secPos: widget.secPos,
                          index: index,
                          list: true
                          //  title: sectionList[secPos].title,
                          )),
                );
              },
            ),
          ));
    } else {
      return Container();
    }
  }





  // _specification() {
  //   return Card(
  //     elevation: 0,
  //     child: GestureDetector(
  //       child: ListTile(
  //         dense: true,
  //         title: Text(
  //           getTranslated(context, 'SPECIFICATION')!,
  //           style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
  //         ),
  //         trailing: Icon(Icons.keyboard_arrow_right),
  //       ),
  //       onTap: _extraDetail,
  //     ),
  //   );
  // }

  _sellerDetail() {
    String? name = productDetailData.soldBy;
    if (name == null) name = ' ';

    //print("name***${widget.model!.seller_id}");

    return Card(
      elevation: 0,
      child: GestureDetector(
        child: ListTile(
          dense: true,
          title: Text(
            getTranslated(context, 'SOLD_BY')! + " : " + name,
            style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
          ),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : productDetailData.storeLink,
                      from: 'soldby',
                      salePer: '0',
                    ),
                  ));
          },
        ),
      ),
    );
  }

  //  _sellerVideo() {
    
  //   return GestureDetector(
  //     child: Card(
  //       elevation: 0,
  //       color: colors.whiteTemp,
  //       child: Column(
  //         children: [
  //           Container(
  //             width: double.infinity,
  //             padding: EdgeInsets.only(left: 6,top: 5,bottom: 5),
  //             child: Text(
  //               'Want to Know your Seller' + " ? ",
  //               style: TextStyle(color: Colors.red,fontWeight : FontWeight.w600),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //     onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => YoutubeVideoPlayer(videoUrl: sellerVideoModel!.videoLink!)))
  //   );
  // }

  sellerVideoAlert(){
    return showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                      builder: (context,setstate) {
                                        return AlertDialog(
                                          scrollable: true,
                                          contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                                          insetPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                                          
                                          content: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Business Name - ",style: TextStyle(fontWeight: FontWeight.w300,fontSize: 14)),
                                                  Expanded(
                                                    child: Text(
                                                      "${sellerVideoModel!.data![0].businessName.toString()}",
                                                      style: TextStyle(
                                                          color: Theme.of(context).colorScheme.fontColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Business State - ",style: TextStyle(fontWeight: FontWeight.w300,fontSize: 14)),
                                                  Expanded(
                                                    child: Text(
                                                      "${sellerVideoModel!.data![0].businessState.toString()}",
                                                      style: TextStyle(
                                                          color: Theme.of(context).colorScheme.fontColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              
                                            ],
                                          ),
                                        );
                                      }
                                    );
                                  },
                                );
  }
  _notMadeInIndia() {
    String? name = productDetailData.soldBy;
    if (name == null) name = ' ';

    //print("name***${widget.model!.seller_id}");

    return Card(
      elevation: 0,
      child: GestureDetector(
        child: ListTile(
          dense: true,
          title: Text('Report,If not authentic?',
            style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
          ),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            if (CUR_USERID != null) {
                                openBottomSheet(context);
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
    );
  }
  
   Future<void> openBottomSheet(BuildContext context) async {
     
     
   
    await showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0))),
                isScrollControlled: true,
        context: context,
        builder: (context) {
          return Padding(
          padding : EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ComplaintBottomSheet(productId: productDetailData.product![0].prodID.toString(),screenContext: _scaffoldKey.currentContext!,),
          );
        });
  }

  

  _deliverPincode() {
    String pin = context.read<UserProvider>().curPincode;
    return Card(
      elevation: 0,
      child: GestureDetector(
        child: ListTile(
          dense: true,
          title: Text(
            pin == ''
                ? getTranslated(context, 'SELOC')!
                : getTranslated(context, 'DELIVERTO')! + pin,
            style: TextStyle(color: Theme.of(context).colorScheme.lightBlack),
          ),
          trailing: Icon(Icons.keyboard_arrow_right),
        ),
        onTap: _pincodeCheck,
      ),
    );
  }

  _reviewTitle() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Row(
          children: [
            Text(
              getTranslated(context, 'CUSTOMER_REVIEW_LBL')!,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  getTranslated(context, 'VIEW_ALL')!,
                  style: TextStyle(color: colors.primary),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ReviewList(productDetailData.product![0].prodID,)),
                );
              },
            )
          ],
        ));
  }


 

  // _attr() {
  //   return widget.model!.attributeList!.isNotEmpty
  //       ? Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 20.0),
  //           child: ListView.builder(
  //             shrinkWrap: true,
  //             physics: NeverScrollableScrollPhysics(),
  //             itemCount: widget.model!.attributeList!.length,
  //             itemBuilder: (context, i) {
  //               return Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //                 child: Row(
  //                   children: [
  //                     Expanded(
  //                       flex: 1,
  //                       child: Text(
  //                         widget.model!.attributeList![i].name!,
  //                         style: Theme.of(context).textTheme.subtitle2,
  //                       ),
  //                     ),
  //                     Expanded(
  //                         flex: 2,
  //                         child: Text(
  //                           widget.model!.attributeList![i].value!,
  //                           textAlign: TextAlign.right,
  //                         )),
  //                   ],
  //                 ),
  //               );
  //             },
  //           ),
  //         )
  //       : Container();
  // }

sharePostWithDynamicLink({String? postId}) async {
    final DynamicLinkParameters dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse(Uri.encodeFull(
          'https://oymsmartshop.com/?post=$postId')),
      uriPrefix: "https://oym.page.link",
      androidParameters: const AndroidParameters(
        packageName: "com.nowras.oym",
      ),
      iosParameters: const IOSParameters(
        bundleId: "com.nowras.oym",
        appStoreId: "6443677064",
      ),
    );
    final dynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    print(dynamicLink.shortUrl.toString());
    Share.share(dynamicLink.shortUrl.toString());
  }



  _reviewStar() {
    return Container(
      height: 125,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children:[
                Text(
                  productDetailData.avgRating.toString(),
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
                Text("${productDetailData.totalReviews!.toString()}  ${getTranslated(context, "RATINGS")!}")
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  getRatingBarIndicator(5.0, 5),
                  getRatingBarIndicator(4.0, 4),
                  getRatingBarIndicator(3.0, 3),
                  getRatingBarIndicator(2.0, 2),
                  getRatingBarIndicator(1.0, 1),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  getRatingIndicator(int.parse(star5)),
                  getRatingIndicator(int.parse(star4)),
                  getRatingIndicator(int.parse(star3)),
                  getRatingIndicator(int.parse(star2)),
                  getRatingIndicator(int.parse(star1)),
                  
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getTotalStarRating(star5),
                getTotalStarRating(star4),
                getTotalStarRating(star3),
                getTotalStarRating(star2),
                getTotalStarRating(star1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _review() {
    return  ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            itemCount: tworeviewList.length,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) => Divider(),
            itemBuilder: (context, index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tworeviewList[index].custName!,
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      Spacer(),
                      Text(
                        tworeviewList[index].reviewDate!,
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.lightBlack, fontSize: 11),
                      )
                    ],
                  ),
                  RatingBarIndicator(
                    rating: double.parse(tworeviewList[index].r1 != "0" ? '1' : tworeviewList[index].r2 != "0" ? '2' : tworeviewList[index].r3 != "0" ? '3' : tworeviewList[index].r4 != "0" ? '4' : tworeviewList[index].r5 != "0" ? '5' : '0'),
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: colors.primary,
                    ),
                    itemCount: 5,
                    itemSize: 12.0,
                    direction: Axis.horizontal,
                  ),
                  tworeviewList[index].comments != null &&
                          tworeviewList[index].comments!.isNotEmpty
                      ? Text(
                          tworeviewList[index].comments ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Container(),
                ],
              );
            });
  }

  getRatingIndicator(int totalStar ) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height : 9.5,
          child: LinearProgressIndicator(
            value: double.parse('${totalStar/5}'),
            backgroundColor: Colors.grey[300],
          ),
        ),
      )
    );
  }

  getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        textDirection: TextDirection.rtl,
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_rate_rounded,
          color: colors.yellow,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        direction: Axis.horizontal,
        unratedColor: Colors.transparent,
      ),
    );
  }

  getTotalStarRating(var totalStar) {
    return Container(
        width: 20,
        height: 20,
        child: Text(
          totalStar,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ));
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  final Animation<double> animation;

  AnimatedProgressBar({Key? key, required Animation<double> this.animation})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    // final Animation<double> animation = animation;
    return Container(
      height: 5.0,
      width: animation.value,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.black),
    );
  }
}

class ComplaintBottomSheet extends StatefulWidget {
  BuildContext screenContext;
  String productId;
  ComplaintBottomSheet({required this.screenContext,required this.productId});

  @override
  _ComplaintBottomSheetState createState() => _ComplaintBottomSheetState();
}

class _ComplaintBottomSheetState extends State<ComplaintBottomSheet> {
   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
   bool _isNetworkAvail = true;
   TextEditingController complaint = TextEditingController();
  _submitComplain() async{
    
    if (_formKey.currentState!.validate()) {
      _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      
      var parameter = {
        'customerID': CUR_USERID, 
        'productID' : widget.productId,
        'message': complaint.text
        };
       
      Response response = await post(setNotMadeInIndiaApi,body: parameter);
      print(response.body);
      var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        if (error == 200) {
          
          if (mounted)
          Navigator.of(context).pop();
          setSnackbar(msg!, context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
              child: StatefulBuilder(builder: (BuildContext context,StateSetter innersetState){
                return Container(
                height: deviceHeight!/2.6,
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children : [
                      Text('Is this product not authentic ?',style: Theme.of(context).textTheme.subtitle2!.copyWith(fontSize: 18,
                        color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold)),
                      Padding(
                        padding: EdgeInsets.only(top : 10),
                        child: TextFormField(
                          controller : complaint,
                          maxLines: 4,
                          validator : (val) {
                            if (val!.trim().isEmpty) {
                              return 'Field Required';
                            }
                          },
                          decoration : InputDecoration(
                            hintText : 'Enter your Complain.',
                            border: OutlineInputBorder()
                          )
                        ),
                      ),
         CupertinoButton(
          child: Container(
                width: double.infinity,
                height: 40,
                alignment: FractionalOffset.center,
                decoration: new BoxDecoration(
                  color: colors.secondary,
                  borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
                ),
                child:Text('Submit Complain',
                  textAlign: TextAlign.center,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: colors.whiteTemp, fontWeight: FontWeight.normal))
                        ),
                       onPressed: () =>  _submitComplain()
                     ),
                    ]
                  ),
                ),
              );
              }),
            ),
    );
  }
}


