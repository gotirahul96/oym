import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oym/main.dart';
import 'dart:math';
import 'package:oym/Helper/ApiBaseHelper.dart';
import 'package:oym/Helper/AppBtn.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/HomePageProductTile.dart';
import 'package:oym/Helper/ProductTileListView.dart';
import 'package:oym/Helper/PushNotificationService.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/AllCategoryModel.dart';
import 'package:oym/Model/HomePageListModel.dart';
import 'package:oym/Model/HomeScreenBanners.dart';
import 'package:oym/Model/HomeScreenRecommendationsModel.dart';
import 'package:oym/Model/Model.dart';
import 'package:oym/Model/ProductsListModel.dart';
import 'package:oym/Model/Section_Model.dart';
import 'package:oym/Model/SponserBannerModel.dart';
import 'package:oym/Provider/CartProvider.dart';
import 'package:oym/Provider/FavoriteProvider.dart';
import 'package:oym/Provider/HomeProvider.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/Sale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'Login.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';
import 'SectionList.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}
ApiBaseHelper apiBaseHelper = ApiBaseHelper();
int count = 1;

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  List<HomeScreenBannersData> homeSliderList = [];
  List<HomeScreenBannersData> adsImages = [];
  List<Widget> pages = [];
  final _controller = PageController();
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  //String? curPin;
  List<SubCategoryList> catList = [];
  HomeScreenRecommendationsModel? homeScreenRecommendationModel;
  HomeScreenRecommendationsModel? homeScreenRecentlyViewed;
  SponserBannersModel? sponserBannersModel;
  List<HomePageListData>? homePageListData = [];
  ScrollController scrollController = ScrollController();
  bool isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    CUR_USERID = context.read<SettingProvider>().userId;
    PushNotificationService(context: context).initialise();
    initDynamicLinks(context);
    callApi();
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
    scrollController.addListener(pagination);
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateSlider());
  }

   Future initDynamicLinks(BuildContext context) async {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();

    if (initialLink != null) {
      final Uri deepLink = initialLink.link;
      print('Initial Link is called - ' + deepLink.toString());

      // Example of using the dynamic link to push the user to a different screen
      Map<String, String> params =
          deepLink.queryParameters; // query parameters automatically populated
      var postId = params['post'];
      Navigator.push(
        this.context,
        PageRouteBuilder(
            // transitionDuration: Duration(milliseconds: 150),
            pageBuilder: (_, __, ___) => ProductDetail(
                  productId: postId,
                  index: int.parse('0'),
                )),
      );
    }
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      Map<String, String> params = dynamicLinkData
          .link.queryParameters; // query parameters automatically populated

      var postId = params['post'];
      print("Onlink listen is called - " + dynamicLinkData.toString());
      Navigator.push(
          this.context,
          MaterialPageRoute(
              builder: (_) => ProductDetail(
                    productId: postId,
                    index: int.parse('0'),
                  )));
    }).onError((error) {
      // Handle errors
      Fluttertoast.showToast(msg: error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
        body: _isNetworkAvail
            ? RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      //_deliverPincode(),
                     catList.isNotEmpty ?   _catList() : Container(),
                     homeSliderList.isNotEmpty ?   _slider() : Container(),
                     homeScreenRecommendationModel != null ?  homeScreenRecommendationModel!.data![0].product!.isNotEmpty ?  _recommendations() : Container() : Container(),
                     sponserBannersModel != null ?  _sponserslider() : Container(),
                     homeScreenRecentlyViewed != null ? _recentlyViewed() : Container(),
                     homePageListData != null ? _section() : Container(),
                    ],
                  ),
                ))
            : noInternet(context));
  }

  Future<Null> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);
    context.read<HomeProvider>().setRecommendationLoading(true);

    return callApi();
  }

  void pagination() {
      if ((scrollController.position.pixels ==
          scrollController.position.maxScrollExtent)) {
        setState(() {
          isLoading = true;
          getSection(from: 'pagination');
          //add api for load the more data according to new page
        });
      }
  }

  Widget _slider() {
    double height = deviceWidth! / 2.0;

    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? sliderLoading()
            : Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    // margin: EdgeInsetsDirectional.only(top: 10),
                    child: PageView.builder(
                      itemCount: homeSliderList.isEmpty ? 0 : homeSliderList.length ,
                      scrollDirection: Axis.horizontal,
                      controller: _controller,
                      physics: AlwaysScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          context.read<HomeProvider>().setCurSlider(index);
                        });
                        
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return _buildImagePageItem(homeSliderList[index]);
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    height: 40,
                    left: 0,
                    width: deviceWidth,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: map<Widget>(
                        homeSliderList,
                        (index, url) {
                          print(context.read<HomeProvider>().curSlider);
                          return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 2.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.read<HomeProvider>().curSlider ==
                                        index
                                    ? Theme.of(context).colorScheme.fontColor
                                    : Theme.of(context).colorScheme.lightBlack,
                              ));
                        },
                      ),
                    ),
                  ),
                ],
              );
      },
      selector: (_, homeProvider) => homeProvider.sliderLoading,
    );
  }

  Widget _sponserslider() {
    

    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? sliderLoading()
            : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Padding(
                //   padding: EdgeInsets.only(left : 5.0,top: 10),
                //   child: Text('Sponsers :',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600)),
                // ),
                Container(
                  height: 249,
                  width: double.infinity,
                  margin: EdgeInsetsDirectional.only(top: 10),
                  child: PageView.builder(
                    itemCount: sponserBannersModel!.data!.isEmpty ? 0 : sponserBannersModel!.data!.length ,
                    scrollDirection: Axis.horizontal,
                    controller: PageController(viewportFraction: 0.92),
                    physics: AlwaysScrollableScrollPhysics(),
                    onPageChanged: (index) {
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return _buildSponserBannerItem(sponserBannersModel!.data![index]);
                    },
                  ),
                ),
              ],
            );
      },
      selector: (_, homeProvider) => homeProvider.sponsers,
    );
  }

  Widget _buildSponserBannerItem(SponserBannersData slider) {

    return Container(
      child: Card(
        elevation : 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: GestureDetector(
            child: Column(
              children: [
                FadeInImage(
                    fadeInDuration: Duration(milliseconds: 150),
                    image: NetworkImage(sponserImageBaseurl + slider.image! ),
                    width: double.infinity,
                    height : 200,
                    fit: BoxFit.fill,
                    imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                          "assets/images/placeholder.png",
                          fit: BoxFit.fill,
                          height: 200,
                        ),
                    placeholderErrorBuilder: (context, error, stackTrace) =>
                        Image.asset(
                          "assets/images/placeholder.png",
                          fit: BoxFit.fill,
                          height: 200,
                        ),
                    placeholder: AssetImage("assets/images/placeholder.png")
                    ),
                Container(
                  color : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(slider.type == 'sale' ? 'Up to ' +slider.storeLink! + '% Off' : slider.type == 'soldby' ? 'From ' + slider.storeLink! : 'Direct from Store' ,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_right)
                      ],
                    ),
                  ),
                )
              ],
            ),
            onTap: () async {

              if (slider.type == "search") {
                
              Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(
                            keyword : slider.storeLink,
                            from: 'search',
                          ),
                        ));
              }
              if (slider.type == "category3") {
              Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(
                            keyword : slider.storeLink,
                            from: 'category3',
                          ),
                        ));
              }
              if (slider.type == "category") {
                
              Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(
                            keyword : slider.storeLink,
                            from: 'category',
                          ),
                        ));

              }
               else if (slider.type == "sale") {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Sale(
                            discount : slider.storeLink,
                          ),
                        ));
              } else if (slider.type == 'soldby'){
                Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(
                            keyword : slider.storeLink,
                            from: 'soldby',
                            salePer: '0',
                          ),
                        ));
              }
              else if (slider.type == 'product'){
                Navigator.push(
                  context,
                  PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductDetail(
                            productId: slider.storeLink,
                            index: 0,
                            secPos: 0,
                            list: true,
                          )),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _animateSlider() {
    Future.delayed(Duration(seconds: 30)).then((_) {
      if (mounted) {
        int nextPage = _controller.hasClients
            ? _controller.page!.round() + 1
            : _controller.initialPage;

        if (nextPage == homeSliderList.length) {
          nextPage = 0;
        }
       setState(() {
          context.read<HomeProvider>().setCurSlider(nextPage);
       });
        if (_controller.hasClients)
          _controller
              .animateToPage(nextPage,
                  duration: Duration(milliseconds: 200), curve: Curves.linear)
              .then((_) => _animateSlider());

      }
    });
  }


  _singleSection(int index) {
    Color back;
    int pos = index % 5;
    if (pos == 0)
      back = Theme.of(context).colorScheme.back1;
    else if (pos == 1)
      back = Theme.of(context).colorScheme.back2;
    else if (pos == 2)
      back = Theme.of(context).colorScheme.back3;
    else if (pos == 3)
      back = Theme.of(context).colorScheme.back4;
    else
      back = Theme.of(context).colorScheme.back5;

    return homePageListData!.length > 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                          margin: EdgeInsets.only(bottom: 40),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20)))),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _getHeading(homePageListData![index].title ?? "", index),
                        _getSection(index),
                      ],
                    ),
                  ],
                ),
              ),
              adsImages.length > index ? _getOfferImage(index) : Container(),
            ],
          )
        : Container();
  }

  _getHeading(String title, int index,{String from = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  color: colors.yellow,
                ),
                padding: EdgeInsetsDirectional.only(
                    start: 10, bottom: 3, top: 3, end: 10),
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(color: colors.blackTemp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              /*   Positioned(
                  // clipBehavior: Clip.hardEdge,
                  // margin: EdgeInsets.symmetric(horizontal: 20),

                  right: -14,
                  child: SvgPicture.asset("assets/images/eshop.svg"))*/
            ],
          ),
        ),
      from.isNotEmpty ? Container():  Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(homePageListData![index].categoryName2!,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1!
                          .copyWith(color: Theme.of(context).colorScheme.fontColor)),
                ),
                TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero, // <
                        backgroundColor: (Theme.of(context).colorScheme.white),
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                    child: Text(
                      getTranslated(context, 'SHOP_NOW')!,
                      style: Theme.of(context).textTheme.caption!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : homePageListData![index].categoryName2,
                      from: 'category',
                    ),
                  ));
                    }),
              ],
            )),
      ],
    );
  }

  _getOfferImage(index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: InkWell(
        child: FadeInImage(
            fadeInDuration: Duration(milliseconds: 150),
            image: NetworkImage(homePageImageBaseurl + adsImages[index].imageNM!),
            width: double.maxFinite,
            height: 140,
            imageErrorBuilder: (context, error, stackTrace) => erroWidget(50),
            fit: BoxFit.cover,
            // errorWidget: (context, url, e) => placeHolder(50),
            placeholder: AssetImage(
              "assets/images/placeholder.png",
            )),
        onTap: () {
          if (adsImages[index].type == "category") {
          
        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : adsImages[index].keywordLink,
                      from: 'category',
                    ),
                  ));

        } else if (adsImages[index].type == "sale") {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Sale(
                      discount : adsImages[index].keywordLink,
                    ),
                  ));
        } else if (adsImages[index].type == 'soldby'){
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : adsImages[index].keywordLink,
                      from: 'soldby',
                      salePer: '0',
                    ),
                  ));
        }
        else if (adsImages[index].type == 'search'){
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : adsImages[index].keywordLink,
                      from: 'search',
                      salePer: '0',
                    ),
                  ));
        }
        else if (adsImages[index].type == 'category3'){
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : adsImages[index].keywordLink,
                      from: 'category3',
                      salePer: '0',
                    ),
                  ));
        }
        else if (adsImages[index].type == 'product'){
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                      productId: adsImages[index].keywordLink,
                      index: 1,
                      secPos: 0,
                      list: true,
                    )),
          );
        }
        },
      ),
    );
  }

  _getSection(int i) {
    var orient = MediaQuery.of(context).orientation;

       return homePageListData![i].product!.length == 3
            ?  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Flexible(
                            flex: 3,
                            fit: FlexFit.loose,
                            child: Container(
                                height: orient == Orientation.portrait
                                    ? MediaQuery.of(context).size.height * 0.4
                                    : MediaQuery.of(context).size.height,
                                child: productItem(i, 0,))),
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 1,)),
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 2,)),
                            ],
                          ),
                        ),
                      ],
                    ))
            : homePageListData![i].product!.length == 2
                ? Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Row(
                            //mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Container(
                                    height: orient == Orientation.portrait
                                        ? deviceHeight! * 0.3
                                        : deviceHeight! * 0.5,
                                    child: productItem(i, 0)),
                              ),
                              Expanded(
                                child: Container(
                                    height: orient == Orientation.portrait
                                        ? deviceHeight! * 0.3
                                        : deviceHeight! * 0.5,
                                    child: productItem(i, 1)),
                              ),
                            ],
                          ),
                        ),
                        // Flexible(
                        //     flex: 3,
                        //     fit: FlexFit.loose,
                        //     child: Container(
                        //         height: orient == Orientation.portrait
                        //             ? deviceHeight! * 0.4
                        //             : deviceHeight,
                        //         child: productItem(i, 2))),
                      ],
                    ))
                    : homePageListData![i].product!.length == 1
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: Container(
                                        height: orient == Orientation.portrait
                                            ? deviceHeight! * 0.25
                                            : deviceHeight! * 0.5,
                                        child: productItem(i, 0,))),
                                
                              ],
                            )) 
                        : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GridView.count(
                                padding: EdgeInsetsDirectional.only(top: 5),
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                childAspectRatio: 0.8,
                                physics: NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 0,
                                children: List.generate(
                                  homePageListData![i].product!.length,
                                  (index) {
                                    return productItem(i, index,);
                                  },
                                )));
  }

  Widget productItem(int secPos, int index,) {
    if (homePageListData!.length > index) {

      double width = deviceWidth! * 0.5;

      return Card(
        elevation: 0.0,
        margin: EdgeInsetsDirectional.only(bottom: 2, end: 2),
        //end: pad ? 5 : 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5)),
                          child: FadeInImage(
                            fadeInDuration: Duration(milliseconds: 150),
                            image: NetworkImage(imageBaseUrl + homePageListData![secPos].product![index].image1!),
                            height: double.maxFinite,
                            width: double.maxFinite,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(double.maxFinite),
                            //fit: BoxFit.fill,
                            placeholder: placeHolder(width),
                          )),
                    ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(homePageListData![secPos].product![index].category3!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),textAlign: TextAlign.center),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom : 8.0),
                  child: homePageListData![secPos].product![index].discount! != '0' ?  Text('Up to '+ homePageListData![secPos].product![index].discount! + ' % Off',
                    style: TextStyle(fontSize: 14,color: Colors.green,fontWeight: FontWeight.w600)
                  ) : Text('Best Deals',
                  textAlign: TextAlign.center,style: TextStyle(fontSize: 14,color: Colors.red,fontWeight: FontWeight.w600)),
                ),
              )
            ],
          ),
          onTap: () {
            Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : homePageListData![secPos].product![index].category3,
                      from: 'category3',
                    ),
                  ));
          },
        ),
      );
    } else
      return Container();
  }

  _section() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: sectionLoading()))
            : Stack(
              children: [
                ListView.builder(
                  
                    padding: EdgeInsets.all(0),
                    itemCount: homePageListData!.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _singleSection(index);
                    },
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: showCircularProgress(isLoading, colors.primary)),
              ],
            );
      },
      selector: (_, homeProvider) => homeProvider.secLoading,
    );
  }
  _recommendations() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: sectionLoading()))
            : ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: 1,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _commonBackgroundSection(homeScreenRecommendationModel!.data![0].title ?? "",index,'recommedation',sections: _getRecommendationSection());
                },
              );
      },
      selector: (_, homeProvider) => homeProvider.recommendationLoading,
    );
  }

  _recentlyViewed(){
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: sectionLoading()))
            : ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: 1,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _commonBackgroundSection(homeScreenRecentlyViewed!.data![0].title ?? "",
                  index,'recentlyView',
                  sections: _getRecentlyViewSection()
                  );
                },
              );
      },
      selector: (_, homeProvider) => homeProvider.recentlyViewed,
    );
  }

  _commonBackgroundSection(String title,int index,String from,{Widget? sections}) {
    Color back = Theme.of(context).colorScheme.back1;
    
    return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                          margin: EdgeInsets.only(bottom: 40),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20)))),
                    ),
                    Column(

                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _getHeading(title, index,from: from),
                        sections != null ? sections : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  _getRecentlyViewSection(){
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: homeScreenRecentlyViewed!.data![0].product!.length,
        itemBuilder: (context,index){
        return ProductTileListView(
          title: homeScreenRecentlyViewed!.data![0].product![index].productTitle!,
          sellingPrice: homeScreenRecentlyViewed!.data![0].product![index].sellingPrice.toString(),
                        mrp: homeScreenRecentlyViewed!.data![0].product![index].mrp.toString(),
                        index: index.toString(),
                        productId: homeScreenRecentlyViewed!.data![0].product![index].prodID.toString(),
                        image: imageBaseUrl + homeScreenRecentlyViewed!.data![0].product![index].image1!,
        );
      }),
    );
  }

  _getRecommendationSection(){
    return Padding(
            padding: const EdgeInsets.all(15.0),
            child: GridView.count(
                padding: EdgeInsetsDirectional.only(top: 5),
                crossAxisCount: 2,
                shrinkWrap: true,
                //childAspectRatio: 0.8,
                physics: NeverScrollableScrollPhysics(),
                children: List.generate(
                  homeScreenRecommendationModel!.data![0].product!.length,
                  (index) {
                    return HomeScreenProductTile(
                      sellingPrice: homeScreenRecommendationModel!.data![0].product![index].sellingPrice.toString(),
                      mrp: homeScreenRecommendationModel!.data![0].product![index].mrp.toString(),
                      index: index.toString(),
                      productId: homeScreenRecommendationModel!.data![0].product![index].prodID.toString(),
                      image: imageBaseUrl + homeScreenRecommendationModel!.data![0].product![index].image1!,
                    );
                  },
                )),
          );
  }

  _catList() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: catLoading()))
            : Container(
                height: 85,
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: ListView.builder(
                  itemCount: catList.length < 10 ? catList.length : 10,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : catList[index].categoryName!,
                      from: 'category',
                    ),
                  ));
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 5.0),
                                child: new ClipRRect(
                                  borderRadius: BorderRadius.circular(25.0),
                                  child: new FadeInImage(
                                    fadeInDuration: Duration(milliseconds: 150),
                                    image: NetworkImage(
                                     categoryBaseUrl + catList[index].coverImage!,
                                    ),
                                    height: 50.0,
                                    width: 50.0,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
                                            erroWidget(50),
                                    placeholder: placeHolder(50),
                                  ),
                                ),
                              ),
                              Container(
                                child: Text(
                                  catList[index].categoryName!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                          color: Theme.of(context).colorScheme.fontColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                width: 50,
                              ),
                            ],
                          ),
                        ),
                      );
                  },
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.catLoading,
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Future<Null> callApi({String from = ''}) async {
    UserProvider user = Provider.of<UserProvider>(context, listen: false);
    SettingProvider setting =
        Provider.of<SettingProvider>(context, listen: false);

    user.setUserId(setting.userId);

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getSetting();
      getSlider();
      getSponserSlider();
      getCat();
      getRecommendations();
      getRecentlyViewed();
      getSection(from: from);
      getOfferImages();
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    return null;
  }

  Future _getFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        Map parameter = {
          'custid': context.read<SettingProvider>().userId,
        };
        print(parameter);
        apiBaseHelper.postAPICall(wishListApi, parameter).then((getdata) {
          print(getdata);
          int error = int.parse(getdata["error"]);
          String? msg = getdata["message"];
          if (error == 200) {
            var data = getdata["data"];
            List<ProductListData> tempList = (data as List)
                .map((data) => new ProductListData.fromJson(data))
                .toList();
            if(mounted)
            setState(() {
              context.read<FavoriteProvider>().setFavlist(tempList);
            });
          } else {
            if (msg != 'No Favourite(s) Product Are Added')
              setSnackbar(msg!, context);
          }

          context.read<FavoriteProvider>().setLoading(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<FavoriteProvider>().setLoading(false);
        });
      } else {
        context.read<FavoriteProvider>().setLoading(false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  void getOfferImages() {
    Map parameter = Map();

    apiBaseHelper.postAPICall(homePageAdsApi, parameter).then((getdata) {
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];
      if (error == 200) {
        var data = getdata["data"];
        adsImages.clear();
        adsImages.addAll((data as List).map((data) => HomeScreenBannersData.fromJson(data)).toList());
      } else {
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setOfferLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setOfferLoading(false);
    });
  }
  
  void getSection({String from = ''}) {
    if (from.isEmpty)homePageListData!.clear();
    Map parameter = {'startPosition': homePageListData!.length == 0 ? "0" : '${homePageListData!.length}'};
    print(parameter);

    apiBaseHelper.postAPICall(homePageListApi, parameter).then((getdata) {
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];
      //sectionList.clear();
      if (error == 200) {
        var data = getdata["data"];
        
        homePageListData!.addAll((data as List)
            .map((data) => new HomePageListData.fromJson(data))
            .toList());
            homePageListData!.forEach((element) { 
              print(element.toJson());
            });
      } else {
        setSnackbar(msg!, context);
      }
      setState(() {
        isLoading = false;
      });
      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }
  // void getSection() {
  //   Map parameter = {PRODUCT_LIMIT: "6", PRODUCT_OFFSET: "0"};

  //   if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;
  //   String curPin = context.read<UserProvider>().curPincode;
  //   if (curPin != '') parameter[ZIPCODE] = curPin;

  //   apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
  //     bool error = getdata["error"];
  //     String? msg = getdata["message"];
  //     sectionList.clear();
  //     if (!error) {
  //       var data = getdata["data"];

  //       sectionList = (data as List)
  //           .map((data) => new SectionModel.fromJson(data))
  //           .toList();
  //     } else {
  //       if (curPin != '') context.read<UserProvider>().setPincode('');
  //       setSnackbar(msg!, context);
  //     }

  //     context.read<HomeProvider>().setSecLoading(false);
  //   }, onError: (error) {
  //     setSnackbar(error.toString(), context);
  //     context.read<HomeProvider>().setSecLoading(false);
  //   });
  // }

  void getSetting() {
    
    //print("")
    Map parameter = Map();
    if (CUR_USERID != null) parameter = {'custID': CUR_USERID}; else parameter = {'custId' : '0'};

    apiBaseHelper.postAPICall(homePageSettingsApi, parameter).then((getdata) async {
      
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];

      if (error == 200) {
        var data = getdata["data"][0];
        
        String? versionfromBackend = data['version'];
        

        if (CUR_USERID != null) {
          
          context.read<UserProvider>().setCartCount(
              getdata["cartLength"].toString());
        }
          PackageInfo packageInfo = await PackageInfo.fromPlatform();

          String version = packageInfo.version;

          final Version currentVersion = Version.parse(version);
          final Version latestVersionAnd = Version.parse(versionfromBackend);
          

          if ((latestVersionAnd > currentVersion) )
            updateDailog();
        
      } else {
        setSnackbar(msg!, context);
      }
    }, onError: (error) {
      setSnackbar(error.toString(), context);
    });
  }


  // Future<void> _getCart(String save) async {
  //   _isNetworkAvail = await isNetworkAvailable();

  //   if (_isNetworkAvail) {
  //     try {
  //       var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};

  //       Response response =
  //       await post(getCartApi, body: parameter, headers: headers)
  //           .timeout(Duration(seconds: timeOut));

  //       var getdata = json.decode(response.body);
  //       bool error = getdata["error"];
  //       String? msg = getdata["message"];
  //       if (!error) {
  //         var data = getdata["data"];


  //         List<SectionModel> cartList = (data as List)
  //             .map((data) => new SectionModel.fromCart(data))
  //             .toList();
  //         context.read<CartProvider>().setCartlist(cartList);


  //       }

  //     } on TimeoutException catch (_) {

  //     }
  //   } else {
  //     if (mounted)
  //       setState(() {
  //         _isNetworkAvail = false;
  //       });
  //   }
  // }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<Null> generateReferral() async {
    String refer = getRandomString(8);

    //////

    Map parameter = {
      REFERCODE: refer,
    };

    apiBaseHelper.postAPICall(validateReferalApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        REFER_CODE = refer;

        Map parameter = {
          USER_ID: CUR_USERID,
          REFERCODE: refer,
        };

        apiBaseHelper.postAPICall(getUpdateUserApi, parameter);
      } else {
        if (count < 5) generateReferral();
        count++;
      }

      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }

  updateDailog() async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: Text(getTranslated(context, 'UPDATE_APP')!),
        content: Text(
          getTranslated(context, 'UPDATE_AVAIL')!,
          style: Theme.of(this.context)
              .textTheme
              .subtitle1!
              .copyWith(color: Theme.of(context).colorScheme.fontColor),
        ),
        actions: <Widget>[
          new TextButton(
              child: Text(
                getTranslated(context, 'NO')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              }),
          new TextButton(
              child: Text(
                getTranslated(context, 'YES')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop(false);

                String _url = '';
                if (Platform.isAndroid) {
                  _url = androidLink + packageName;
                } else if (Platform.isIOS) {
                  _url = iosLink;
                }

                if (await canLaunch(_url)) {
                  await launch(_url);
                } else {
                  throw 'Could not launch $_url';
                }
              })
        ],
      );
    }));
  }

  Widget homeShimmer() {
    return Container(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
            child: Column(
          children: [
            catLoading(),
            sliderLoading(),
            sectionLoading(),
          ],
        )),
      ),
    );
  }

  Widget sliderLoading() {
    double width = deviceWidth!;
    double height = width / 2;
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: height,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget _buildImagePageItem(HomeScreenBannersData slider) {
    double height = deviceWidth! / 0.4;

    return GestureDetector(
      child: FadeInImage(
          fadeInDuration: Duration(milliseconds: 150),
          image: NetworkImage(sliderImageBaseUrl + slider.imageNM! ),
          height: height,
          width: double.maxFinite,
          fit: BoxFit.fill,
          imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                "assets/images/placeholder.png",
                //fit: BoxFit.cover,
                height: height,
              ),
          placeholderErrorBuilder: (context, error, stackTrace) =>
              Image.asset(
                "assets/images/placeholder.png",
                //fit: BoxFit.cover,
                height: height,
              ),
          placeholder: AssetImage("assets/images/placeholder.png")
          ),
      onTap: () async {
        int curSlider = context.read<HomeProvider>().curSlider;

        if (homeSliderList[curSlider].type == "category") {
          
        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : slider.keywordLink,
                      from: 'category',
                    ),
                  ));

        } if (homeSliderList[curSlider].type == "search") {
          
        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : slider.keywordLink,
                      from: 'search',
                    ),
                  ));

        }
        if (homeSliderList[curSlider].type == "category3") {
          
        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : slider.keywordLink,
                      from: 'category3',
                    ),
                  ));
        } 
        else if (homeSliderList[curSlider].type == "sale") {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Sale(
                      discount : slider.keywordLink,
                    ),
                  ));
        } else if (homeSliderList[curSlider].type == 'soldby'){
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : slider.keywordLink,
                      from: 'soldby',
                      salePer: '0',
                    ),
                  ));
        }
        else if (homeSliderList[curSlider].type == 'product'){
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                      productId: slider.keywordLink,
                      index: curSlider,
                      secPos: 0,
                      list: true,
                    )),
          );
        }
      },
    );
  }

  Widget deliverLoading() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((_) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            shape: BoxShape.circle,
                          ),
                          width: 50.0,
                          height: 50.0,
                        ))
                    .toList()),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
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
              context.read<HomeProvider>().setCatLoading(true);
              context.read<HomeProvider>().setSecLoading(true);
              context.read<HomeProvider>().setSliderLoading(true);
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  if (mounted)
                    setState(() {
                      _isNetworkAvail = true;
                    });
                  callApi();
                } else {
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  

  


  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  void getSlider() async{
    try {
      Response response = await get(homePageBannerApi);
      var getData = json.decode(response.body);
      HomeScreenBanners homeScreenBanners = HomeScreenBanners.fromJson(getData);
      setState(() {
        homeSliderList = homeScreenBanners.data!;
      });
      print(homeSliderList.length);
      context.read<HomeProvider>().setSliderLoading(false);
    } catch (e) {
      setSnackbar(e.toString(), context);
      context.read<HomeProvider>().setSliderLoading(false);
    }
  }

  void getSponserSlider() async {
    try {
      Response response = await get(homePageSponsers);
      var getData = json.decode(response.body);
      
      setState(() {
        sponserBannersModel = SponserBannersModel.fromJson(getData);
        context.read<HomeProvider>().setSponserLoading(false);
      });
      
    } catch (e) {
      setSnackbar(e.toString(), context);
      setState(() {
        context.read<HomeProvider>().setSponserLoading(false);
      });
    }
  }

  void getCat() async {
    
    try {
      Response response = await get(homePageCategoryApi);
      var getData = json.decode(response.body);
      var data = getData['data'];
      catList = (data as List).map((data) => new SubCategoryList.fromJson(data)).toList();
      context.read<HomeProvider>().setCatLoading(false);
    } catch (e) {
      setSnackbar(e.toString(), context);
      context.read<HomeProvider>().setCatLoading(false);
    }
  }
  
  
  void getRecommendations() async {
    
    try {
      Response response = await get(homePageRecommendationsApi);
      print(response.body);
      var getData = json.decode(response.body);
      homeScreenRecommendationModel = HomeScreenRecommendationsModel.fromJson(getData);
      context.read<HomeProvider>().setRecommendationLoading(false);
    } catch (e) {
      setSnackbar(e.toString(), context);
      context.read<HomeProvider>().setRecommendationLoading(false);
    }
  }

  void getRecentlyViewed() async {
    if(CUR_USERID != null){
      try {
      var parameter = {
        'customerID' : CUR_USERID
      };
      Response response = await post(homePageRecentlyViewedApi,body: parameter);
      var getData = json.decode(response.body);
      print(response.body);
      int error = int.parse(getData['error']);
      if (error == 200) {
        setState(() {
        homeScreenRecentlyViewed = HomeScreenRecommendationsModel.fromJson(getData);
      });
      }
      context.read<HomeProvider>().setRecentlyViewedLoading(false);
    } catch (e) {
      setSnackbar(e.toString(), context);
      context.read<HomeProvider>().setRecentlyViewedLoading(false);
    }
    }
    
  }

  sectionLoading() {
    return Column(
        children: [0, 1, 2, 3, 4]
            .map((_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                                margin: EdgeInsets.only(bottom: 40),
                                decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.white,
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20)))),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              GridView.count(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  childAspectRatio: 1.0,
                                  physics: NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                  children: List.generate(
                                    4,
                                    (index) {
                                      return Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color: Theme.of(context).colorScheme.white,
                                      );
                                    },
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    sliderLoading()
                    //offerImages.length > index ? _getOfferImage(index) : Container(),
                  ],
                ))
            .toList());
  }

  
}
