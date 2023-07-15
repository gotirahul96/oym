import 'dart:convert';
import 'dart:io';

import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/Section_Model.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Screen/MyOrder.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:oym/Screen/NotificationLIst.dart';
import 'package:oym/Screen/Sale.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screen/All_Category.dart';
import '../Screen/Chat.dart';
import '../Screen/Customer_Support.dart';
import '../Screen/My_Wallet.dart';
import '../Screen/Product_Detail.dart';
import '../Screen/Splash.dart';
import '../main.dart';
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;

class PushNotificationService {
  late BuildContext context;


  PushNotificationService({required this.context});

  Future initialise() async {
    iOSPermission();
    messaging.getToken().then((token) async {
      SettingProvider settingsProvider = Provider.of<SettingProvider>(this.context, listen: false);
      print('This is fcm Token : $token');
      if (settingsProvider.userId != null &&
          settingsProvider.userId != "") _registerToken(token);
    });

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/notificationicon');
    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();
    final MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      if (payload != null) {
        print(payload);
        List<String> pay = payload.split(",");
        pay.forEach((val){
          print(val);
        });
        print(pay[0]);
        if (pay[0] == "products") {
          getProduct(pay[1], 0, 0, true);
        } else if (pay[0] == "categories") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AllCategory()),
          );
        } else if (pay[0] == "product") {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => ProductDetail(
                productId: pay[2],
                index: 1,
                secPos: 0,
                list: true,
              ))));
        } 
        else if (pay[0] == 'news') {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => NotificationList())));
              } 
        else if (pay[0] == 'sale') {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Sale(
                      discount : pay[1],
                    ),
                  ));
        } 
        // else if (pay[0] == "ticket_message") {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) => Chat(
        //               id: pay[1],
        //               status: "",
        //             )),
        //   );
        // } 
        // else if (pay[0] == "ticket_status") {
        //   Navigator.push(context,
        //       MaterialPageRoute(builder: (context) => CustomerSupport()));
        //} 
        else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Splash()),
          );
        }
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyApp(sharedPreferences: prefs)),
        );
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(this.context, listen: false);
      print(message);
      var data = message.notification!;
      var title = data.title.toString();
      var body = data.body.toString();
      var image = message.data['image'] ?? '';

      var type = message.data['type'] ?? '';
      var percentage = '';
      percentage = message.data['percent'] ?? '';
      var productId = message.data['prodID'] ?? '';
      print(percentage);
      print(productId);
      if (type == "ticket_status") {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CustomerSupport()));
      } 
      else if (type == "ticket_message") {
        if (CUR_TICK_ID == percentage) {
          if (chatstreamdata != null) {
            var parsedJson = json.decode(message.data['chat']);
            parsedJson = parsedJson[0];

            Map<String, dynamic> sendata = {
              "id": parsedJson[ID],
              "title": parsedJson[TITLE],
              "message": parsedJson[MESSAGE],
              "user_id": parsedJson[USER_ID],
              "name": parsedJson[NAME],
              "date_created": parsedJson[DATE_CREATED],
              "attachments": parsedJson["attachments"]
            };
            var chat = {};

            chat["data"] = sendata;
            if (parsedJson[USER_ID] != settingsProvider.userId)
              chatstreamdata!.sink.add(jsonEncode(chat));
          }
        } else {
          if (image != null && image != 'null' && image != '') {
            generateImageNotication(title, body, image, type, percentage,productId);
          } else {
            generateSimpleNotication(title, body, type, percentage,productId);
          }
        }
      } else if (image != null && image != 'null' && image != '') {
        generateImageNotication(title, body, image, type, percentage,productId);
      } else {
        generateSimpleNotication(title, body, type, percentage,productId);
      }
    });

    messaging.getInitialMessage().then((RemoteMessage? message) async {
      // bool back = await getPrefrenceBool(ISFROMBACK);
      bool back = await Provider.of<SettingProvider>(context, listen: false)
          .getPrefrenceBool(ISFROMBACK);

      if (message != null && back) {
        var type = message.data['type'] ?? '';
        var percent = '';
        percent = message.data['percent'] ?? '';
        var prodID = message.data['prodID'] ?? '';
        print(percent);
      print(prodID);
        if (type == "products") {
          getProduct(percent, 0, 0, true);
        } else if (type == "categories") {
          Navigator.push(context,
              (MaterialPageRoute(builder: (context) => AllCategory())));
        } else if (type == "wallet") {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => MyWallet())));
        } else if (type == 'order') {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => MyOrder())));
              
        }
        else if (type == 'news') {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => NotificationList())));
              } 
        else if (type == "ticket_message") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                      id: percent,
                      status: "",
                    )),
          );
        } else if (type == "ticket_status") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CustomerSupport()));
        } else if (type == "product") {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => ProductDetail(
                productId: prodID,
                index: 1,
                secPos: 0,
                list: true,
              ))));
        } 
        else if (type == 'sale') {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Sale(
                      discount : percent,
                    ),
                  ));
        } 
        
        else {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => Splash())));
        }
        Provider.of<SettingProvider>(context, listen: false)
            .setPrefrenceBool(ISFROMBACK, false);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (message != null) {
        var type = message.data['type'] ?? '';
        var percent = '';

        percent = message.data['percent'] ?? '';
        var prodID = message.data['prodID'] ?? '';
        print(percent);
      print(prodID);
        if (type == "products") {
          getProduct(percent, 0, 0, true);
        } else if (type == "categories") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AllCategory()),
          );
        } else if (type == "wallet") {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => MyWallet())));
        } else if (type == 'order') {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => MyOrder())));
        } else if (type == 'news') {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => NotificationList())));
              } 
        else if (type == "product") {
          Navigator.push(
              context, (MaterialPageRoute(builder: (context) => ProductDetail(
                productId: prodID,
                index: 1,
                secPos: 0,
                list: true,
              ))));
        } 
        else if (type == 'sale') {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Sale(
                      discount : percent,
                    ),
                  ));
        } 
        
        else if (type == "ticket_message") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                      id: percent,
                      status: "",
                    )),
          );
        } else if (type == "ticket_status") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CustomerSupport()));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MyApp(
                      sharedPreferences: prefs,
                    )),
          );
        }
        Provider.of<SettingProvider>(context, listen: false)
            .setPrefrenceBool(ISFROMBACK, false);
      }
    });
  }

  void iOSPermission() async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _registerToken(String? token) async {

    SettingProvider settingsProvider =
    Provider.of<SettingProvider>(this.context, listen: false);
    var parameter = {'custID': settingsProvider.userId, 'tokenNotification' : token};

    Response response =
        await post(updateFCMtoken, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

    var getdata = json.decode(response.body);
    print(response.body);
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    try {
      var parameter = {
        ID: id,
      };

      Response response =
          await post(getProductApi, headers: headers, body: parameter)
              .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];

        List<Product> items = [];

        items =
            (data as List).map((data) => new Product.fromJson(data)).toList();

        // Navigator.of(context).push(MaterialPageRoute(
        //     builder: (context) => ProductDetail(
        //           index: int.parse(id),

        //           model: items[0],
        //           secPos: secPos,
        //           list: list,
        //         )));
      } else {

      }
    } catch (Exception) {}
  }
}

Future<dynamic> myForgroundMessageHandler(RemoteMessage message) async {


  setPrefrenceBool(ISFROMBACK, true);

  return Future<void>.value();
}

Future<String> _downloadAndSaveImage(String url, String fileName) async {
  var directory = await getApplicationDocumentsDirectory();
  var filePath = '${directory.path}/$fileName';
  var response = await http.get(Uri.parse(url));

  var file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

Future<void> generateImageNotication(
    String title, String msg, String image, String type, String id,String productId) async {
  var largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
  var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
  var bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id',
      'big text channel name',
      channelDescription: 'big text channel description',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation);
  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin
      .show(0, title, msg, platformChannelSpecifics, payload: type + "," + id + "," + productId);
}

Future<void> generateSimpleNotication(
    String title, String msg, String type, String id,String productId) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name', channelDescription: 'your channel description',
      importance: Importance.max, priority: Priority.high, ticker: 'ticker');
  var iosDetail = IOSNotificationDetails();

  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iosDetail);
  await flutterLocalNotificationsPlugin
      .show(0, title, msg, platformChannelSpecifics, payload: type + "," + id + "," + productId);
}
