import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MapCard extends StatefulWidget {

  MapCard({
    this.map,
    @required this.onCardClick,
//    @required this.onCardLongPress,
  });

  final DocumentSnapshot map;
  final VoidCallback onCardClick;
//  final VoidCallback onCardLongPress;

  @override
  _MapCardState createState() => new _MapCardState();

}

class _MapCardState extends State<MapCard>{
  String title;
  String map;

  bool hasPhoto;
  bool photoSynced;
  @override
  Widget build(BuildContext context) {
    // todo is there a better way to assert this stuff
    if (widget.map['title'] == null || widget.map['title'] == '') {
      title = 'Untitled';
    } else {
      title = widget.map['title'];
    }
    if (widget.map['map'] == null) {
      map = '';
    } else {
      map = widget.map['map'];
    }

    if (widget.map['path_local'] == null && widget.map['path_remote'] == null) {
      hasPhoto = false;
    } else {
      hasPhoto = true;
      if (widget.map['path_remote'] == null) {
        photoSynced = false;
      } else {
        photoSynced = true;
      }
    }


    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0),
    padding: EdgeInsets.fromLTRB(8.0,0.0,4.0,0.0),
    decoration: new BoxDecoration(
    color: Colors.white,
    border: new Border.all(color: Colors.black38, width: 2.0),
    borderRadius: new BorderRadius.circular(16.0),
    ),
    child:
    new ListTile(

        contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
//      leading: const Icon(Icons.whatshot),
        title: Text(title),
        subtitle: Text(map, overflow: TextOverflow.ellipsis, maxLines: 3,),

        // Tap -> go through to job task
        onTap: widget.onCardClick,
        // Long tap -> add options to sync or delete
//        onLongPress: widget.onCardLongPress,
        // TODO: Icons display whether sample has photo or not
        trailing:
        hasPhoto ? photoSynced ? Icon(Icons.camera_alt, color: Colors.green,)
            : Icon(Icons.camera_alt, color: Colors.orange)
            : Icon(Icons.camera_alt, color: Colors.red)
    ),
    );
  }
}