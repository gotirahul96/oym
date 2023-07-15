import 'dart:async';
import 'dart:convert';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/GetAllReviewsModel.dart';
import 'package:oym/Screen/write_review.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'Product_Detail.dart';
import 'Product_Preview.dart';

class ReviewList extends StatefulWidget {
  final String? productID;

  ReviewList(this.productID);

  @override
  State<StatefulWidget> createState() {
    return StateRate();
  }
}

class StateRate extends State<ReviewList> {
  bool _isNetworkAvail = true;
  bool _isLoading = true;

  // bool _isProgress = false, _isLoading = true;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  List<GetAllReviewsData> allReviewsData = [];
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isPhotoVisible = true;
  var star1 = "0",
      star2 = "0",
      star3 = "0",
      star4 = "0",
      star5 = "0",
      averageRating = "0";
  GetAllReviewsModel? getAllReviewsModel;

  @override
  void initState() {
    getReview();
    controller.addListener(_scrollListener);
    // Future.delayed(Duration.zero, () {
    //   Provider.of<OrderProvider>(context, listen: false)
    //       .fetchOrderDetails(CUR_USERID, "delivered");
    // });

    super.initState();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;
              getReview(from: 'scroll');
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar:
          getAppBar(getTranslated(context, 'CUSTOMER_REVIEW_LBL')!, context),
      body: getAllReviewsModel != null ? _review() : Center(child: Container(
        child: Text('No Reviews'),
      )),
      floatingActionButton: getAllReviewsModel != null ? getAllReviewsModel!.groupReview![0].purchased!.toLowerCase() == 'yes'
          ? FloatingActionButton.extended(
        icon: const Icon(
          Icons.create,
          size: 20,
        ),
        label: Text(
          getTranslated(context, "WRITE_REVIEW_LBL")!,
          style: TextStyle(color: Theme.of(context).colorScheme.white, fontSize: 14),
        ),
        onPressed: () {
          openBottomSheet(context, widget.productID);
        },
      ) : Container()
          : Container()
    );
  }

  Future<void> openBottomSheet(BuildContext context, var productID) async {
    await showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Write_Review(_scaffoldKey.currentContext!, widget.productID!);
        }).then((value) {
      getReview();
    });
  }

  Widget _review() {


    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical:10.0),
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    //mainAxisSize: MainAxisSize.min,
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${getAllReviewsModel!.groupReview![0].avgRating ?? 0}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                      Text("${getAllReviewsModel!.groupReview![0].totalReviews ?? 0}  ${getTranslated(context, "RATINGS")!}")
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
          ),
          // revImgList.length > 0 ?
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal:8),
          //   child: Card(
          //     elevation: 0.0,
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //           Padding(
          //            padding: const EdgeInsets.all(5.0),
          //            child: Text("${getTranslated(context, "REVIEW_BY_CUST")!}",style: const TextStyle(fontWeight: FontWeight.bold),),
          //          ),
          //         const Divider(),
          //         _reviewImg(),
          //       ],
          //     ),
          //   ),
          // ):Container(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "${allReviewsData.length} ${getTranslated(context, "REVIEW_LBL")}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          isPhotoVisible = !isPhotoVisible;
                        });
                      },
                      child: Container(
                        height: 20.0,
                        width: 20.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color:
                                isPhotoVisible ? colors.primary : Theme.of(context).colorScheme.white,
                            borderRadius: BorderRadius.circular(3.0),
                            border: Border.all(
                              color: colors.grad2Color,
                            )),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: isPhotoVisible
                              ? Icon(
                                  Icons.check,
                                  size: 15.0,
                                  color: Theme.of(context).colorScheme.white,
                                )
                              : Container(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                     Text(
                      "${getTranslated(context, "WITH_PHOTO")}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ) 
              ],
            ),
          ),
         allReviewsData.length == 0 ? Container(
          child : Text('No Reviews')
         ) : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              controller: controller,
              itemCount: allReviewsData.length,
              physics: BouncingScrollPhysics(),
              // separatorBuilder: (BuildContext context, int index) => Divider(),
              itemBuilder: (context, index) {
              DateTime parseDate =
    new DateFormat("yyyy-MM-dd hh:mm:ss").parse(allReviewsData[index].review![0].reviewDate!);
    var inputDate = DateTime.parse(parseDate.toString());
var outputFormat = DateFormat('MM/dd/yyyy');
var outputDate = outputFormat.format(inputDate);
                if (index ==allReviewsData.length && isLoadingmore) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Container(
                      child: 
                      Stack(
                        children: [
                        Container(
                          child: Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    allReviewsData[index].review![0].custName!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RatingBarIndicator(
                                        rating:
                                        double.parse(getRatingFromResponse(index: index)),
                                        itemBuilder: (context, index) => const Icon(
                                          Icons.star,
                                          color: colors.yellow,
                                        ),
                                        itemCount: 5,
                                        itemSize: 12.0,
                                        direction: Axis.horizontal,
                                      ),
                                      Spacer(),
                                      Text(
                                        parseDate.toString(),
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.lightBlack2,
                                            fontSize: 11),
                                      )
                                    ],
                                  ),
                                  allReviewsData[index].review![0].comments != null &&
                                      allReviewsData[index].review![0].comments!.isNotEmpty
                                      ? Text(
                                    allReviewsData[index].review![0].comments ?? '',
                                    textAlign: TextAlign.left,
                                  )
                                      : Container(),
                                  isPhotoVisible ? reviewImage(index) : Container()
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
              }
           }),
        ],
      ),
    );
  }

  String getRatingFromResponse({int index = 0}){
    if (allReviewsData[index].review![0].r1! != '0') {
      return '1';
    } else if (allReviewsData[index].review![0].r2! != '0') {
       return '2';
    }
    else if (allReviewsData[index].review![0].r3! != '0') {
       return '3';
    }
    else if (allReviewsData[index].review![0].r4! != '0') {
       return '4';
    }
    else if (allReviewsData[index].review![0].r5! != '0') {
       return '5';
    }
    return '0';
  }

  // _reviewImg() {
  //   return revImgList.length > 0
  //       ? Container(
  //           height: 100,
  //           child: ListView.builder(
  //             itemCount: revImgList.length > 5 ? 5 : revImgList.length,
  //             scrollDirection: Axis.horizontal,
  //             shrinkWrap: true,
  //             physics: AlwaysScrollableScrollPhysics(),
  //             itemBuilder: (context, index) {
  //               return Padding(
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
  //                 child: GestureDetector(
  //                   onTap: () async {
  //                     if (index == 4) {
  //                       Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                               builder: (context) =>
  //                                   ReviewGallary(model: widget.model)));
  //                     } else {
  //                       Navigator.push(
  //                           context,
  //                           PageRouteBuilder(
  //                               // transitionDuration: Duration(seconds: 1),
  //                               pageBuilder: (_, __, ___) => ReviewPreview(
  //                                     index: index,
  //                                     model: widget.model,
  //                                   )));
  
  //                     }
  //                   },
  //                   child: Stack(
  //                     children: [
  //                       FadeInImage(
  //                         fadeInDuration: Duration(milliseconds: 150),
  //                         image: NetworkImage(
  //                           revImgList[index].img!,
  //                         ),
  //                         height: 100.0,
  //                         width: 80.0,
  //                         fit: BoxFit.cover,
  //                         //  errorWidget: (context, url, e) => placeHolder(50),
  //                         placeholder: placeHolder(80),
  //                         imageErrorBuilder: (context, error, stackTrace) =>
  //                             erroWidget(80),
  //                       ),
  //                       index == 4
  //                           ? Container(
  //                               height: 100.0,
  //                               width: 80.0,
  //                               color: colors.black54,
  //                               child: Center(
  //                                   child: Text(
  //                                 "+${revImgList.length - 5}",
  //                                 style: TextStyle(
  //                                     color: Theme.of(context).colorScheme.white,
  //                                     fontWeight: FontWeight.bold),
  //                               )),
  //                             )
  //                           : Container()
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         )
  //       : Container();
  // }

  reviewImage(int i) {
    
    return Container(
      height: allReviewsData[i].images!.isNotEmpty ? 100 : 0,
      child: ListView.builder(
        itemCount: allReviewsData[i].images!.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          print(reviewImageBaseurl + allReviewsData[i].images![index]);
          return Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 10, bottom: 5.0, top: 5),
            child: InkWell(
              onTap: () {
                print(allReviewsData[i].images!.length);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductPreview(
                        pos: index,
                        secPos: 0,
                        index: 0,
                        id: "$index",
                        from: 'review',
                        imgList: allReviewsData[i].images!,
                      ),
                    ));
              },
              child: Hero(
                tag: '$index${allReviewsData[i].review![0].id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: FadeInImage(
                    image: NetworkImage(reviewImageBaseurl + allReviewsData[i].images![index]),
                    height: 70.0,
                    width: 70.0,
                    placeholder: placeHolder(50),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        erroWidget(50),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getReview({String? from}) async {
    _isNetworkAvail = await isNetworkAvailable();
    
    
    if (_isNetworkAvail) {
      try {
        var parameter = {
          'productID': widget.productID,
          'startPosition': allReviewsData.length == 0 ? '0' : '${allReviewsData.length}',
          'customerID': CUR_USERID,
        };
        print(parameter);
        Response response =
            await post(getAllReviewsApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];

        if (error == 200) {
          print(getdata);
          setState(() {
            getAllReviewsModel = GetAllReviewsModel.fromJson(getdata);
            var data = getdata['data'];
            allReviewsData.addAll((data as List).map((data) => new GetAllReviewsData.fromJson(data)).toList());
            print(data);
            star1 = getAllReviewsModel!.groupReview![0].reviews1.toString();
            star2 = getAllReviewsModel!.groupReview![0].reviews2.toString();
            star3 = getAllReviewsModel!.groupReview![0].reviews3.toString();
            star4 = getAllReviewsModel!.groupReview![0].reviews4.toString();
            star5 = getAllReviewsModel!.groupReview![0].reviews5.toString();
          });

          // var groupReview = getdata["groupReview"];
          // print(groupReview);
          // setState(() {
          //   getAllReviewsModel?.groupReview?.addAll((groupReview as List).map((groupReview) => GroupReview.fromJson(groupReview)).toList());
          //   getAllReviewsModel?.data?.addAll((data as List).map((data) => GetAllReviewsData.fromJson(data)).toList());
          // });
          
        } else {
          //setSnackbar(msg!);
          star1 = '0';
          star2 = '0';
          star3 = '0';
          star4 = '0';
          star5 = '0';
          isLoadingmore = false;
        }
        if (mounted) if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        //textDirection: TextDirection.rtl,
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
