import 'package:flutter/material.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Screen/Product_Detail.dart';

class HomeScreenProductTile extends StatelessWidget {
  String sellingPrice;
  String mrp;
  String index;
  String image;
  String productId;

  HomeScreenProductTile({required this.productId, required this.sellingPrice,required this.mrp,required this.index,required this.image});
  

  @override
  Widget build(BuildContext context) {

      double price = double.parse(sellingPrice);
      double discount = ((double.parse(sellingPrice) / double.parse(mrp)) * 100) - 100;

      double width = deviceWidth! * 0.5;

    return 
     Card(
        elevation: 0.0,
        margin: EdgeInsetsDirectional.only(bottom: 2, end: 2),
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
                          child: Hero(
                            transitionOnUserGestures: true,
                            tag: "$index",
                            child: FadeInImage(
                              fadeInDuration: Duration(milliseconds: 150),
                              image: NetworkImage(image),
                              height: double.maxFinite,
                              width: double.maxFinite,
                              imageErrorBuilder: (context, error, stackTrace) =>
                                  erroWidget(double.maxFinite),
                              //fit: BoxFit.fill,
                              placeholder: placeHolder(width),
                            ),
                          )),
                    ),
                  ],
                ),
              ),
              Text(" " + CUR_CURRENCY! + " " + price.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 5.0, bottom: 5, top: 3),
                child: discount.round() != 0
                    ? Row(
                        children: <Widget>[
                          Text(
                            discount !=
                                    0
                                ? CUR_CURRENCY! +
                                    "" +
                                    mrp.toString()
                                : "",
                            style: Theme.of(context)
                                .textTheme
                                .overline!
                                .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0),
                          ),
                          Flexible(
                            child: Text(" | " + discount.toString().replaceAll("-", "") + '%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .overline!
                                    .copyWith(
                                        color: colors.primary,
                                        letterSpacing: 0)),
                          ),
                        ],
                      )
                    : Container(
                        height: 5,
                      ),
              )
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                  // transitionDuration: Duration(milliseconds: 150),
                  pageBuilder: (_, __, ___) => ProductDetail(
                      productId: this.productId,
                      index: int.parse(this.index),
                      )),
            );
          },
        ),
      );
    } 
      
  
  
}