import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/theme.dart';
import 'package:k2e/utils/camera.dart';
import 'package:k2e/utils/common_functions.dart';
import 'package:k2e/widgets/buttons.dart';
import 'package:k2e/widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class EditNote extends StatefulWidget {
  final String note;
  EditNote({Key key, this.note}) : super(key: key);
  @override
  _EditNoteState createState() => new _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  String _title;
  bool isLoading = true;

  // images
  bool localPhoto = false;
  Map<String, dynamic> noteObj = new Map<String, dynamic>();

  DocumentReference note;
  var _formKey = GlobalKey<FormState>();

  // Create list of focus nodes
  final _focusNodes = List<FocusNode>.generate(
    200,
    (i) => FocusNode(),
  );

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
                    print(noteObj.toString());
                    Firestore.instance
                        .document(DataManager.get().currentJobPath)
                        .collection('notes')
                        .document(noteObj['path'])
                        .setData(noteObj, merge: true);
                    Navigator.pop(context);
                  }
                })
          ]),
      body: isLoading
          ? LoadingPage(loadingText: 'Loading note...')
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: new EdgeInsets.all(8.0),
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
                                  localPhoto = true;
                                  _handleImageUpload(image);
                                });
                              },
//                                    child: (_imageFile != null)
//                                        ? Image.file(_imageFile)
                              child: localPhoto
                                  ? new Image.file(
                                      new File(noteObj['path_local']))
                                  : (noteObj['path_remote'] != null)
                                      ? new CachedNetworkImage(
                                          imageUrl: noteObj['path_remote'],
                                          placeholder: (context, url) =>
                                              new CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
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
                    new Container(
                      child: new TextFormField(
                        decoration: new InputDecoration(
                          labelText: "Title",
                        ),
                        onSaved: (String value) {
                          noteObj["title"] = value.trim();
                        },
                        validator: (String value) {},
                        focusNode: _focusNodes[0],
                        initialValue: noteObj["title"],
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (v) {
                          FocusScope.of(context).requestFocus(_focusNodes[1]);
                        },
                      ),
                    ),
                    new Container(
                      child: new TextFormField(
                        decoration: new InputDecoration(
                          labelText: "Note",
                        ),
                        onSaved: (String value) {
                          noteObj["note"] = value.trim();
                        },
                        validator: (String value) {},
                        focusNode: _focusNodes[1],
                        initialValue: noteObj["note"],
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        onFieldSubmitted: (v) {
//                                    FocusScope.of(context).requestFocus(_focusNodes[2]);
                        },
                      ),
                    ),
                    widget.note != null
                        ? FunctionButton(
                      text: "Delete Note",
                        onClick: () => deleteDialog(
                          title: 'Delete Note',
                          query: 'Are you sure you wish to delete this note?',
                          docPath: Firestore.instance
                              .document(DataManager.get().currentJobPath)
                              .collection('notes')
                              .document(widget.note),
                          imagePath: noteObj['storage_ref'] != null ? FirebaseStorage.instance.ref().child(noteObj['storage_ref']) : null,
                          context: context,
                        )
                    ) : new Container(),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void initState() {
    if (widget.note != null)
      note = Firestore.instance
          .document(DataManager.get().currentJobPath)
          .collection('notes')
          .document(widget.note);
    _loadNote();
    super.initState();
  }

  void _handleImageUpload(File image) async {
    String storageRef = noteObj['storage_ref'];
    String path = widget.note;

    setState(() {
      noteObj["path_local"] = image.path;
    });

    ImageSync(image, 50, "note_" + noteObj['path'],
            "jobs/" + DataManager.get().currentJobNumber, note)
        .then((refs) {
      // Delete old photo
      if (storageRef != null)
        FirebaseStorage.instance.ref().child(storageRef).delete();

      if (this.mounted) {
        setState(() {
          noteObj['path_remote'] = refs['downloadURL'];
          noteObj['storage_ref'] = refs['storageRef'];
          localPhoto = false;
        });
      } else {
        // User has left the page, upload url straight to firestore
        Firestore.instance
            .document(DataManager.get().currentJobPath)
            .collection('notes')
            .document(path)
            .setData({
          "path_remote": refs['downloadURL'],
          'storage_ref': refs['storageRef'],
        }, merge: true);
      }
    });
  }

  void _loadNote() async {
    if (widget.note == null) {
      _title = "Add Note";
      noteObj = {
        'title': null,
        'note': null,
        'path_local': null,
        'path_remote': null,
        'path': new Uuid().v1(),
      };

      setState(() {
        isLoading = false;
      });
    } else {
      print("Loading note: " + widget.note);
      _title = "Edit Note";

      note.get().then((doc) {
        noteObj = doc.data;
        noteObj['path'] = doc.documentID;
        // image
        if (doc.data['path_local'] != null && doc.data['path_remote'] == null) {
          // only local image available (e.g. when taking photos with no internet)
          localPhoto = true;
          _handleImageUpload(File(doc.data['path_local']));
        } else if (doc.data['path_remote'] != null) {
          localPhoto = false;
        }

        setState(() {
          isLoading = false;
        });
      });
    }
  }
}
