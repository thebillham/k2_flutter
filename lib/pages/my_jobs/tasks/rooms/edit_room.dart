import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/pages/my_jobs/tasks/acm/acm_card.dart';
import 'package:k2e/pages/my_jobs/tasks/acm/edit_acm.dart';
import 'package:k2e/pages/my_jobs/tasks/acm/edit_sample_asbestos_air.dart';
import 'package:k2e/styles.dart';
import 'package:k2e/theme.dart';
import 'package:k2e/utils/camera.dart';
import 'package:k2e/utils/common_functions.dart';
import 'package:k2e/widgets/buttons.dart';
import 'package:k2e/widgets/common_widgets.dart';
import 'package:k2e/widgets/custom_auto_complete.dart';
import 'package:k2e/widgets/custom_typeahead.dart';
import 'package:k2e/widgets/dialogs.dart';
import 'package:uuid/uuid.dart';

class EditRoom extends StatefulWidget {
  EditRoom({Key key, this.room}) : super(key: key);
  final String room;
  @override
  _EditRoomState createState() => new _EditRoomState();
}

class _EditRoomState extends State<EditRoom> {
  String _title = "Edit Room";
  bool isLoading = true;
  String initRoomGroup;
  Map<String, dynamic> roomObj = new Map<String, dynamic>();

  // images
  String room;
  bool localPhoto = false;
  List<Map<String, String>> roomgrouplist = new List();
  final Map constants = DataManager.get().constants;
  GlobalKey key = new GlobalKey<AutoCompleteTextFieldState<String>>();

//  final controllerRoomCode = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _roomNameController = TextEditingController();

  List rooms;
  List items;
  List materials;

  var _formKey = GlobalKey<FormState>();
//  GlobalKey formFieldKey = new GlobalKey<AutoCompleteFormFieldState<String>>();

  ScrollController _scrollController;

  // Create list of focus nodes
  final _focusNodes = List<FocusNode>.generate(
    200,
    (i) => FocusNode(),
  );

//  final _bmControllers = List<TextEditingController>.generate(
//      200,
//      (i) => TextEditingController(),
//    );

  @override
  void initState() {
    room = widget.room;
//    controllerRoomCode.addListener(_updateRoomCode);
    _loadRoom();
    _scrollController = ScrollController();

    rooms = constants['roomsuggestions'];
    items = constants['buildingitems'];
    materials = constants['buildingmaterials'];
    super.initState();
  }

  // TODO: Room details
  // If combination survey, select the method for this room
  // If refurbishment, detail planned works? Any sampling restrictions?
  // If demo, detail if there are any restrictions, e.g. room occupied
  // TODO: Add room type

  Widget build(BuildContext context) {
    return new Scaffold(
//        resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
          title: Text(_title),
          leading: new IconButton(
            icon: new Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: <Widget>[
            new IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    // Update room group map if new room has been added or if room's room group has changed
                    Firestore.instance
                        .document(DataManager.get().currentJobPath)
                        .collection('rooms')
                        .document(roomObj['path'])
                        .setData(roomObj);
                    if (roomObj['roomgrouppath'] == null ||
                        roomObj['roomgrouppath'] != initRoomGroup) {
                      updateRoomGroups(initRoomGroup, roomObj, widget.room);
                    } else {
                      updateRoomCard(roomObj['roomgrouppath'], roomObj);
                    }
                    Navigator.pop(context);
                  }
                })
          ]),
      body: isLoading
          ? LoadingPage(loadingText: 'Loading room info...')
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: Form(
                key: _formKey,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: new EdgeInsets.all(8.0),
//                  padding: new EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 200.0),
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Container(
                            alignment: Alignment.center,
                            height: 312.0,
                            width: 240.0,
                            decoration: BoxDecoration(
                                border: new Border.all(color: Colors.black)),
                            child: GestureDetector(
                                onTap: () {
                                  ImagePicker.pickImage(
                                          source: ImageSource.camera)
                                      .then((image) {
//                                          _imageFile = image;
                                    if (image != null) {
                                      localPhoto = true;
                                      _handleImageUpload(image);
                                    }
                                  });
                                },
//                                    child: (_imageFile != null)
//                                        ? Image.file(_imageFile)
                                child: localPhoto
                                    ? new Image.file(
                                        new File(roomObj['path_local']))
                                    : (roomObj['path_remote'] != null)
                                        ? new CachedNetworkImage(
                                            imageUrl: roomObj['path_remote'],
                                            placeholder: (context, url) =>
                                                new CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    new Icon(Icons.error),
                                            fadeInDuration:
                                                new Duration(seconds: 1),
                                          )
                                        : new Icon(
                                            Icons.camera,
                                            color: CompanyColors.accentRippled,
                                            size: 48.0,
                                          )),
                          )
                        ],
                      ),
                      CustomTypeAhead(
                        controller: _roomNameController,
                        //                            initialValue: acmObj['materialrisk_surfacedesc'],
                        capitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        label: 'Room Name',
                        suggestions: rooms,
                        onSaved: (value) => roomObj['name'] = value.trim(),
                        validator: (value) {},
                        focusNode: _focusNodes[0],
                        nextFocus: _focusNodes[1],
                        onSuggestionSelected: (suggestion) {
                          _roomNameController.text = suggestion['label'];
                          if (_roomCodeController.text == '') {
                            _roomCodeController.text = suggestion['code'];
                          }
                        },
                        onSubmitted: (v) {},
                      ),
                      new Container(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Room Code",
                            hintText:
                                "e.g. B1 (use for large surveys with many similar rooms)",
                          ),
                          controller: _roomCodeController,
                          autocorrect: false,
                          onSaved: (String value) =>
                              roomObj["roomcode"] = value.trim(),
                          focusNode: _focusNodes[1],
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      new Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(
                          top: 14.0,
                        ),
                        child: new Text(
                          "Room Group/Building/Level",
                          style: Styles.label,
                        ),
                      ),
                      new Container(
                        alignment: Alignment.topLeft,
                        child: DropdownButton<String>(
                          value: (roomObj['roomgrouppath'] == null)
                              ? null
                              : roomObj['roomgrouppath'],
                          iconSize: 24.0,
                          items: roomgrouplist
                              .map((Map<String, String> roomgroup) {
                            print(roomgroup.toString());
                            String val = "Untitled";
                            if (roomgroup['name'] != null)
                              val = roomgroup['name'];
                            return new DropdownMenuItem<String>(
                              value: roomgroup["path"],
                              child: new Text(val),
                            );
                          }).toList(),
                          hint: Text("-"),
                          onChanged: (value) {
                            setState(() {
//                            _roomgroup = roomgrouplist.firstWhere((e) => e['path'] == value);
                              if (value == '') {
                                roomObj['roomtype'] = 'orphan';
                              } else
                                roomObj['roomtype'] = null;
                              roomObj["roomgroupname"] =
                                  roomgrouplist.firstWhere(
                                      (e) => e['path'] == value)['name'];
                              ;
                              roomObj["roomgrouppath"] = value;
                              DataManager.get().currentRoomGroup = value;
//                              acm.setData({"room": _room}, merge: true);
                            });
                          },
                        ),
                      ),
                      ExpansionTile(
                          initiallyExpanded: true,
                          title: new Text(
                            "Presumed and Sampled Materials",
                            style: Styles.h2,
                          ),
                          children: <Widget>[
                            CheckLabel(
                              value: roomObj['presume'],
                              onClick: (value) => setState(() {
                                roomObj['presume'] =
                                roomObj['presume'] != null
                                    ? !roomObj['presume']
                                    : true;
                              }),
                              text: "Presume Entire Room (Inaccessible)",
                            ),
                            widget.room != null
                                ? new StreamBuilder(
                                    stream: Firestore.instance
                                        .document(
                                            DataManager.get().currentJobPath)
                                        .collection('acm')
                                        .where("roompath",
                                            isEqualTo: widget.room)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData)
                                        return Container(
                                            padding: EdgeInsets.only(top: 16.0),
                                            alignment: Alignment.center,
                                            color: Colors.white,
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  new CircularProgressIndicator(),
                                                  Container(
                                                      alignment:
                                                          Alignment.center,
                                                      height: 64.0,
                                                      child: Text(
                                                          "Loading ACM items..."))
                                                ]));
                                      if (snapshot.data.documents.length == 0)
                                        return EmptyList(
                                          text: 'This job has no ACM items.'
                                        );
                                      return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount:
                                              snapshot.data.documents.length,
                                          itemBuilder: (context, index) {
                                            var doc = snapshot
                                                .data.documents[index].data;
                                            doc['path'] = snapshot.data
                                                .documents[index].documentID;
                                            return AcmCard(
                                              doc: snapshot
                                                  .data.documents[index],
                                              onCardClick: () async {
                                                if (snapshot.data
                                                            .documents[index]
                                                        ['sampleType'] ==
                                                    'air') {
                                                  Navigator.of(context).push(
                                                    new MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditSampleAsbestosAir(
                                                                sample: snapshot
                                                                    .data
                                                                    .documents[
                                                                        index]
                                                                    .documentID)),
                                                  );
                                                } else {
                                                  Navigator.of(context).push(
                                                    new MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditACM(
                                                                acm: snapshot
                                                                    .data
                                                                    .documents[
                                                                        index]
                                                                    .documentID)),
                                                  );
                                                }
                                              },
                                              onCardLongPress: () {
                                                // Delete
                                                // Bulk add /clone etc.
                                              },
                                            );
                                          });
                                    })
                                : EmptyList(text: 'This job has no ACM items.')
                          ]),
//                    new Container(padding: EdgeInsets.only(top: 14.0)),
//                    new Divider(),
                    // TODO ok for now but there should be a quicker way to add b.m.s for room. Possibly a screen you select all the materials and swipe left or right for ACM or no? Or just a list of common materials that you can click on grouped in 3 layers, e.g. top coat, main layer, substrate
                      ExpansionTile(
                        initiallyExpanded: true,
                        title: new Text(
                          "Building Materials",
                          style: Styles.h2,
                        ),
                        children: <Widget>[
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FunctionButton(
                                text: "Load New Template",
                                onClick: () {
                                  showRoomTemplateDialog(
                                    context,
                                    roomObj,
                                    applyTemplate,
                                  );
                                }),
                              FunctionButton(
                                text: "Clear Empty Rows",
                                onClick: () {
                                  if (roomObj["buildingmaterials"] != null &&
                                      roomObj["buildingmaterials"].length >
                                          0) {
                                    this.setState(() {
                                      roomObj["buildingmaterials"] =
                                          roomObj["buildingmaterials"]
                                              .where((bm) =>
                                          bm["material"] == null ||
                                              bm["material"]
                                                  .trim()
                                                  .length >
                                                  0)
                                              .toList();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          (roomObj['buildingmaterials'] != null &&
                                  roomObj['buildingmaterials'].length > 0)
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount:
                                      roomObj['buildingmaterials'].length,
                                  itemBuilder: (context, index) {
                                    return buildBuildingMaterials(index);
                                  })
                              : new Container(),
//                    buildBuildingMaterials(),
                        ],
                      ),
                      widget.room != null
                          ? FunctionButton(
                        text: "Delete Room",
                          onClick: () => deleteDialog(
                            title: 'Delete Room',
                            query: 'Are you sure you wish to delete this room (' +
                                roomObj['name'] +
                                ')?\nNote: This will not delete any ACM linked to this room.',
                            actions: _removeRoomRefs,
                            docPath: Firestore.instance
                                .document(DataManager.get().currentJobPath)
                                .collection('rooms')
                                .document(widget.room),
                            imagePath: roomObj['storage_ref'] != null ? FirebaseStorage.instance.ref().child(roomObj['storage_ref']) : null,
                            context: context,
                          )
                      ) : new Container(),
                    ]),
              ),
            ),
    );
  }

  void _removeRoomRefs() {
    // Remove from room group
    var initRoomGroup = roomObj['roomgrouppath'];
    roomObj['roomgrouppath'] = null;
    updateRoomGroups(initRoomGroup, roomObj, room);

    // Remove ACM references
    Firestore.instance
        .document(DataManager.get().currentJobPath)
        .collection('acm')
        .where('roompath', isEqualTo: widget.room)
        .getDocuments()
        .then((doc) {
      doc.documents.forEach((doc) {
        Firestore.instance
            .document(DataManager.get().currentJobPath)
            .collection('acm')
            .document(doc.documentID)
            .setData({
          'roomname': null,
          'roompath': null,
        }, merge: true);
      });
    });
  }

  buildBuildingMaterials(index) {
    var item = roomObj['buildingmaterials'][index];
    var label = items.firstWhere((i) { print(i.toString()); print(item.toString()); print(i['label'] == item['label']); return i["label"] == item['label']; },
        orElse: () => print('No hint'));
    var hint = '';
    print(label.toString());
    if (label != null && label['hint'] != null) {
      hint = label['hint'];
      print(hint);
    }
    TextEditingController labelController =
        TextEditingController(text: item['label']);
    TextEditingController materialController =
        TextEditingController(text: item['material']);
    Widget widget = new Row(children: <Widget>[
      new Container(
        width: 150.0,
        alignment: Alignment.topLeft,
        padding: EdgeInsets.only(
          right: 14.0,
          left: 8.0,
        ),
//          child: new Text(item["label"], style: Styles.label,),
        child: CustomTypeAhead(
          controller: labelController,
          capitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
//          label: 'Item',
          suggestions: items,
          onSaved: (value) =>
              roomObj['buildingmaterials'][index]["label"] = value.trim(),
          validator: (value) {},
          focusNode: _focusNodes[(index * 2) + 2],
          nextFocus: _focusNodes[(index * 2) + 3],
        ),
      ),
      new Flexible(
        child: CustomTypeAhead(
          controller: materialController,
          capitalization: TextCapitalization.none,
          textInputAction: roomObj['buildingmaterials'].length - 1 != index
              ? TextInputAction.next
              : TextInputAction.done,
//            label: 'Material',
          suggestions: materials,
          hint: hint,
          onSaved: (value) =>
              roomObj['buildingmaterials'][index]["material"] = value.trim(),
          validator: (value) {},
          focusNode: _focusNodes[(index * 2) + 3],
          nextFocus: (roomObj['buildingmaterials'].length - 1 != index &&
                  roomObj['buildingmaterials'][index + 1] != null &&
                  roomObj['buildingmaterials'][index + 1]["label"]
                          .trim()
                          .length >
                      0)
              ? _focusNodes[((index + 1) * 2) + 3]
              : _focusNodes[((index + 1) * 2) + 2],
        ),
      ),
      new Container(
        width: 8.0
      ),
    ]);
    return widget;
  }

  void applyTemplate(roomObj) {
    this.setState(() {
      roomObj = roomObj;
    });
  }

  void _loadRoom() async {
//    print('room is ' + room.toString());
    // Load roomgroups from job
    roomgrouplist = [
      {
        "name": '-',
        "path": '',
      }
    ];
    QuerySnapshot roomSnapshot = await Firestore.instance
        .document(DataManager.get().currentJobPath)
        .collection('rooms')
        .where('roomtype', isEqualTo: 'group')
        .getDocuments();
    roomSnapshot.documents.forEach((doc) =>
        roomgrouplist.add({"name": doc.data['name'], "path": doc.documentID}));
//    print('ROOMGROUPLIST ' + roomgrouplist.toString());

//    print("Loading room");
    if (room == null) {
      _title = "Add New Room";
      roomObj['name'] = null;
      roomObj['path_local'] = null;
      roomObj['path_remote'] = null;
      roomObj['buildingmaterials'] = null;
      roomObj['roomtype'] = 'orphan';
      roomObj['roomgrouppath'] = DataManager.get().currentRoomGroup;

      // New room requires us to create a path so it doesn't need internet to get one from Firestore
      roomObj['path'] = new Uuid().v1();

      setState(() {
        isLoading = false;
      });
    } else {
//      print('Edit room is ' + room.toString());
      _title = "Edit Room";
      Firestore.instance
          .document(DataManager.get().currentJobPath)
          .collection('rooms')
          .document(room)
          .get()
          .then((doc) {
        // image
        if (doc.data['path_remote'] == null && doc.data['path_local'] != null) {
          // only local image available (e.g. when taking photos with no internet)
          localPhoto = true;
          _handleImageUpload(File(doc.data['path_local']));
        } else if (doc.data['path_remote'] != null) {
          localPhoto = false;
        }
        setState(() {
          roomObj = doc.data;
          _roomNameController.text = roomObj['name'];
          _roomCodeController.text = roomObj['roomcode'];
          initRoomGroup = doc.data['roomgrouppath'];
          isLoading = false;
        });
      });
    }
//    print(_title.toString());
  }

  void _handleImageUpload(File image) async {
    String path = roomObj['path'];
    String roomGroupPath = roomObj['roomgrouppath'];
    String storageRef = roomObj['storage_ref'];

    print(image.path);

    updateRoomCard(
        roomGroupPath, {'path_local': image.path, 'path': roomObj['path']});
    setState(() {
      roomObj["path_local"] = image.path;
    });
//    Firestore.instance.document(DataManager.get().currentJobPath)
//        .collection('rooms').document(room).setData({"path_local": image.path},merge: true).then((_) {
//      setState((){});
//    });
    String roomGroup = roomObj["roomgroupname"];
    String name = roomObj["name"];
    String roomCode = roomObj["roomcode"];
    if (roomGroup == null) roomGroup = 'RoomGroup';
    if (name == null) name = "Untitled";
    if (roomCode == null) roomCode = "RG-U";
    ImageSync(
            image,
            50,
            roomGroup + name + "(" + roomCode + ")-" + roomObj['path'],
            "jobs/" + DataManager.get().currentJobNumber,
            Firestore.instance
                .document(DataManager.get().currentJobPath)
                .collection('rooms')
                .document(room))
        .then((refs) {
      // Delete old photo
      print('Printing refs');
      print(refs['downloadURL']);
      print(refs['storageRef']);
      if (storageRef != null)
        FirebaseStorage.instance.ref().child(storageRef).delete();

      updateRoomCard(roomGroupPath, {
        'path_remote': refs['downloadURL'],
        'storage_ref': refs['storageRef'],
        'path': roomObj['path']
      });
      if (this.mounted) {
        setState(() {
          roomObj["path_remote"] = refs['downloadURL'];
          roomObj['storage_ref'] = refs['storageRef'];
          localPhoto = false;
        });
      } else {
        print('Path after leaving page: ' + path);
        // User has left the page, upload url straight to firestore
        Firestore.instance
            .document(DataManager.get().currentJobPath)
            .collection('rooms')
            .document(path)
            .setData({
          "path_remote": refs['downloadURL'],
          "storage_ref": refs['storageRef'],
        }, merge: true);
      }
    });
  }
}

void updateRoomGroups(
    String initRoomGroup, Map<String, dynamic> roomObj, String room) {
  print("Update room groups " + initRoomGroup.toString());
  if (roomObj['roomgrouppath'] != null)
    Firestore.instance
        .document(DataManager.get().currentJobPath)
        .collection('rooms')
        .document(roomObj['roomgrouppath'])
        .get()
        .then((doc) {
      var initChildren = new List.from(doc.data['children']);
      print("Adding to room group: " + initChildren.toString());
      initChildren
        ..addAll([
          {
            "name": roomObj['name'],
            "path": roomObj['path'],
            "path_local": roomObj['path_local'],
            "path_remote": roomObj['path_remote'],
          }
        ]);
      Firestore.instance
          .document(DataManager.get().currentJobPath)
          .collection('rooms')
          .document(roomObj['roomgrouppath'])
          .setData({"children": initChildren}, merge: true);
    });
  if (initRoomGroup != null) {
    // Remove from previous room group
    Firestore.instance
        .document(DataManager.get().currentJobPath)
        .collection('rooms')
        .document(initRoomGroup)
        .get()
        .then((doc) {
      var initChildren = doc.data['children']
          .where((child) => child['path'] != roomObj['path'])
          .toList();
      print("Removing from room group " + initChildren.toString());
      Firestore.instance
          .document(DataManager.get().currentJobPath)
          .collection('rooms')
          .document(initRoomGroup)
          .setData({"children": initChildren}, merge: true);
    });
  }
}

void updateRoomCard(String roomGroupPath, Map<String, dynamic> updateObj) {
  if (roomGroupPath != null)
    Firestore.instance
        .document(DataManager.get().currentJobPath)
        .collection('rooms')
        .document(roomGroupPath)
        .get()
        .then((doc) {
      var list = new List.from(doc.data['children']).map((doc) {
        if (doc['path'] == updateObj['path']) {
          return {
            "name": updateObj['name'] != null ? updateObj['name'] : doc['name'],
            "path": updateObj['path'] != null ? updateObj['path'] : doc['path'],
            "path_remote": updateObj['path_remote'] != null
                ? updateObj['path_remote']
                : doc['path_remote'],
            "path_local": updateObj['path_local'] != null
                ? updateObj['path_local']
                : doc['path_local'],
          };
        } else {
          return doc;
        }
      }).toList();
      Firestore.instance
          .document(DataManager.get().currentJobPath)
          .collection('rooms')
          .document(roomGroupPath)
          .setData({"children": list}, merge: true);
    });
}
