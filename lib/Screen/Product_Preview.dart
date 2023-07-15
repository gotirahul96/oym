import 'package:oym/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../Helper/vimeoplayer.dart';

import '../Helper/Session.dart';
import 'HomePage.dart';


class ProductPreview extends StatefulWidget {
  final int? pos, secPos, index;
  final String? id;
  final List<String?>? imgList;
  final String? from;

  const ProductPreview(
      {Key? key,
      this.pos,
      this.secPos,
      this.from,
      this.index,
      this.id,
      this.imgList,})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StatePreview();
}

class StatePreview extends State<ProductPreview> {
  int? curPos = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      curPos = widget.pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Hero(
      tag: 1,
      child: Stack(
        children: <Widget>[
          // widget.video == ""
          //     ? 
              Container(
                  child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  
                  builder: (BuildContext context, int index) {
                    print(widget.from == 'review' ? reviewImageBaseurl : imageBaseUrl + widget.imgList![index]!);
                    return PhotoViewGalleryPageOptions(
                        initialScale: PhotoViewComputedScale.contained * 0.9,
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        imageProvider: NetworkImage(widget.from == 'review' ? reviewImageBaseurl + widget.imgList![index]! : imageBaseUrl + widget.imgList![index]!));
                  },
                  itemCount: widget.imgList!.length,
                  loadingBuilder: (context, event) => Center(
                    child: Container(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                event.expectedTotalBytes!,
                      ),
                    ),
                  ),
                  backgroundDecoration: BoxDecoration(color: Theme.of(context).colorScheme.white),
                  pageController: PageController(initialPage: curPos!),
                  onPageChanged: (index) {
                    if (mounted)
                      setState(() {
                        curPos = index;
                      });
                  },
                )),
          Positioned(
            top: 34.0,
            left: 5.0,
            child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.all(10),
                  decoration: shadow(),
                  child: Card(
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Icon(
                          Icons.keyboard_arrow_left,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                )),
          ),
          Positioned(
              bottom: 10.0,
              left: 25.0,
              right: 25.0,
              child: SelectedPhoto(
                numberOfDots: widget.imgList!.length,
                photoIndex: curPos,
              )),
        ],
      ),
    ));
  }
}

// class _ControlsOverlay extends StatelessWidget {
//   const _ControlsOverlay({Key? key, this.controller}) : super(key: key);

//   static const _examplePlaybackRates = [
//     0.25,
//     0.5,
//     1.0,
//     1.5,
//     2.0,
//     3.0,
//     5.0,
//     10.0,
//   ];

//   //final VideoPlayerController? controller;

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: <Widget>[
//         AnimatedSwitcher(
//           duration: Duration(milliseconds: 50),
//           reverseDuration: Duration(milliseconds: 200),
//           child: controller!.value.isPlaying
//               ? SizedBox.shrink()
//               : Container(
//                   color: Theme.of(context).colorScheme.black26,
//                   child: Center(
//                     child: Icon(
//                       Icons.play_arrow,
//                       color: Theme.of(context).colorScheme.white,
//                       size: 100.0,
//                     ),
//                   ),
//                 ),
//         ),
//         GestureDetector(
//           onTap: () {
//             controller!.value.isPlaying ? controller!.pause() : controller!.play();
//           },
//         ),
//         Align(
//           alignment: Alignment.topRight,
//           child: PopupMenuButton<double>(
//             initialValue: controller!.value.playbackSpeed,
//             tooltip: 'Playback speed',
//             onSelected: (speed) {
//               controller!.setPlaybackSpeed(speed);
//             },
//             itemBuilder: (context) {
//               return [
//                 for (final speed in _examplePlaybackRates)
//                   PopupMenuItem(
//                     value: speed,
//                     child: Text('${speed}x'),
//                   )
//               ];
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                 // Using less vertical padding as the text is also longer
//                 // horizontally, so it feels like it would need more spacing
//                 // horizontally (matching the aspect ratio of the video).
//                 vertical: 12,
//                 horizontal: 16,
//               ),
//               child: Text('${controller!.value.playbackSpeed}x'),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

class SelectedPhoto extends StatelessWidget {
  final int? numberOfDots;
  final int? photoIndex;

  SelectedPhoto({this.numberOfDots, this.photoIndex});

  Widget _inactivePhoto() {
    return Container(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: 3.0, end: 3.0),
        child: Container(
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4.0)),
        ),
      ),
    );
  }

  Widget _activePhoto() {
    return Container(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
        child: Container(
          height: 10.0,
          width: 10.0,
          decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, spreadRadius: 0.0, blurRadius: 2.0)
              ]),
        ),
      ),
    );
  }

  List<Widget> _buildDots() {
    List<Widget> dots = [];
    for (int i = 0; i < numberOfDots!; i++) {
      dots.add(i == photoIndex ? _activePhoto() : _inactivePhoto());
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildDots(),
      ),
    );
  }
}
