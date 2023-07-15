import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Screen/Product_Detail.dart';

class ProductTileListView extends StatelessWidget {
  String sellingPrice;
  String mrp;
  String index;
  String image;
  String productId;
  String title;

  ProductTileListView({required this.title,required this.productId, required this.sellingPrice,required this.mrp,required this.index,required this.image});
  

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
          child: Padding(
            padding: EdgeInsets.all(15.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                          height: 100,
                          width: 100,
          fit: BoxFit.contain,
          imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                "assets/images/placeholder.png",
                //fit: BoxFit.cover,
                height: 100,
              ),
          placeholderErrorBuilder: (context, error, stackTrace) =>
              Image.asset(
                "assets/images/placeholder.png",
                //fit: BoxFit.cover,
                height: 100,
              ),
          placeholder: AssetImage("assets/images/placeholder.png")
                        ),
                      )),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left : 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          
                          child: Text(title,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold)),
                        ),
                        Text(" " + CUR_CURRENCY! + " " + price.toString(),
                        style: TextStyle(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold)),
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
                                Text(" | " + discount.toStringAsPrecision(3).replaceAll("-", "") + '%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .overline!
                                        .copyWith(
                                            color: colors.primary,
                                            letterSpacing: 0)),
                              ],
                            )
                          : Container(
                              height: 5,
                            ),
                    )
                     ],
               ),
                  ),
                )
              ],
            ),
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