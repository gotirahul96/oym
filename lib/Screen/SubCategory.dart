
import 'package:oym/Helper/Session.dart';
import 'package:oym/Model/Section_Model.dart';
import 'package:oym/Provider/CategoryProvider.dart';
import 'package:flutter/material.dart';
import 'package:oym/Helper/Color.dart';
import 'All_Category.dart';
import 'ProductList.dart';
import 'package:provider/provider.dart';



class SubCategory extends StatelessWidget {
  final List<Product>? subList;
final String title;
  const SubCategory({Key? key,this.subList, required this.title}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: getAppBar(title, context),
      body: Center(
        child: GridView.count(
            padding: EdgeInsets.all(20),
            crossAxisCount: 3,
            shrinkWrap: true,
            childAspectRatio: .75,
            children: List.generate(
              subList!.length,
                  (index) {
                return subCatItem(index, context);
              },
            )),
      ),
    );
  }


  subCatItem(int index, BuildContext context) {


    return GestureDetector(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                    image: NetworkImage(subList![index].image!),
                    fadeInDuration: Duration(milliseconds: 150),
                    imageErrorBuilder: (context, error, stackTrace) =>
                        erroWidget(50),
                    placeholder: placeHolder(50),
                  )),
            ),
          ),
          Text(
            subList![index].name! + "\n",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),
      onTap: () {
        if (subList![index].subList == null ||
            subList![index].subList!.length == 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductList(
                  keyword : subList![index].name,
                  id: subList![index].id,
                ),
              ));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubCategory(
                  subList: subList![index].subList,
                  title: subList![index].name ?? "",
                ),
              ));
        }
      },
    );
  }

}
