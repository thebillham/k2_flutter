import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k2e/autocomplete.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/pages/my_jobs/tasks/coc/assign_sample_numbers.dart';
import 'package:k2e/styles.dart';
import 'package:k2e/theme.dart';
import 'package:k2e/tooltips.dart';
import 'package:k2e/utils/camera.dart';
import 'package:k2e/utils/sample_painter.dart';
import 'package:k2e/widgets/buttons.dart';
import 'package:k2e/widgets/custom_auto_complete.dart';
import 'package:k2e/widgets/loading.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:k2e/utils/firebase_conversion_functions.dart';

class EditACM extends StatefulWidget {
  EditACM({Key key, this.acm}) : super(key: key);
  final String acm;
  @override
  _EditACMState createState() => new _EditACMState();
}

class _EditACMState extends State<EditACM> {
  // TITLE
  String _title;

  // DOCUMENT IDS
  DocumentReference sample;
  DocumentReference acm;
  Map<String,String> _room;
  List<List<Offset>> arrowPaths = new List<List<Offset>>();
  List<List<Offset>> shadePaths = new List<List<Offset>>();
  List<Offset> offsetPoints; //List of points in one Tap or ery point or path is kept here

  Map<String,dynamic> acmObj = new Map<String,dynamic>();

  var _formKey = GlobalKey<FormState>();
  // Create list of focus nodes
  final _focusNodes = List<FocusNode>.generate(
    9,
        (i) => FocusNode(),
  );

  // UI STATE
  bool isLoading = true;
  bool isSampled = false;
  bool stronglyPresumed = false;
  String presumedText = 'Presumed';
  List<Map<String, String>> roomlist = new List();
  List<Map<String, String>> samplelist = new List();
  bool showMaterialRisk = true;
  bool showPriorityRisk = false;
  bool arrowOn = false;
  bool shadeOn = false;

  ScrollController _scrollController;

  // GENERAL INFO
  final controllerSampleNumber = TextEditingController();
  final controllerNotes = TextEditingController();

  // IMAGES
  bool localPhoto = false;

  // ACCESSIBILITY
  int accessibilityScore;

  // MATERIAL RISK
  int materialDamageScore;
  int materialSurfaceScore;
  int materialProductScore;
  int materialAsbestosScore;
//  final controllerDamageDesc = TextEditingController();
//  final controllerSurfaceDesc = TextEditingController();

  int materialRiskScore;
  String materialRiskText;
  int materialRiskLevel;

  // PRIORITY RISK
  int priorityActivityMain;
  int priorityActivitySecond;
  int priorityDisturbanceLocation;
  int priorityDisturbanceAccessibility;
  int priorityDisturbanceExtent;
  int priorityExposureOccupants;
  int priorityExposureUseFreq;
  int priorityExposureAvgTime;
  int priorityMaintType;
  int priorityMaintFreq;

  int priorityRiskScore;
  String priorityRiskText;
  int priorityRiskLevel;

  // MATERIAL AUTOCOMPLETE
  List<String> materials = AutoComplete.materials.split(';');
  GlobalKey<AutoCompleteTextFieldState<String>> keyMaterial = new GlobalKey();
  List<String> items = AutoComplete.items.split(';');
  GlobalKey<AutoCompleteTextFieldState<String>> keyItems = new GlobalKey();
  List<String> damage = ['A few scratches and surface marks', 'No visible damage','High delamination of material','Chipped edges',];
  GlobalKey<AutoCompleteTextFieldState<String>> keyDamage = new GlobalKey();
  List<String> surface = ['Painted','Pitch-bonded material','Resin-bonded material','Unpainted','Unsealed','Laminated'];
  GlobalKey<AutoCompleteTextFieldState<String>> keySurface = new GlobalKey();

//  String initialDescription;
//  String initialMaterial;
//  String initialDamage;
//  String initialSurface;

  @override
  void initState() {
    // init text controllers
//    controllerSampleNumber.addListener(_updateSampleNumber);
//    controllerNotes.addListener(_updateNotes);
    _scrollController = ScrollController();

    // set paths
    if (widget.acm != null) {
      acm = Firestore.instance.document(DataManager
          .get()
          .currentJobPath).collection('acm').document(widget.acm);
      _title = "Edit ACM";
    } else {
      _title = "Add New ACM";
    }
      _loadACM();

      super.initState();
  }

  Widget build(BuildContext context) {
    // Calculate material totals
    bool materialRiskSet = true;
    materialRiskScore = 0;
    if (materialProductScore != null)
      materialRiskScore = materialRiskScore + materialProductScore;
    else materialRiskSet = false;
    if (materialDamageScore != null)
      materialRiskScore = materialRiskScore + materialDamageScore;
    else materialRiskSet = false;
    if (materialSurfaceScore != null)
      materialRiskScore = materialRiskScore + materialSurfaceScore;
    else materialRiskSet = false;
    if (materialAsbestosScore != null)
      materialRiskScore = materialRiskScore + materialAsbestosScore;
    else materialRiskSet = false;

    if (materialRiskScore > 9) {
      materialRiskLevel = 3;
      materialRiskText = 'High (' + materialRiskScore.toString() + ')';
    } else if (materialRiskScore > 6) {
      materialRiskLevel = 2;
      materialRiskText = 'Medium (' + materialRiskScore.toString() + ')';
    } else if (materialRiskScore > 3) {
      materialRiskLevel = 1;
      materialRiskText = 'Low (' + materialRiskScore.toString() + ')';
    } else {
      materialRiskLevel = 0;
      materialRiskText = 'Very low (' + materialRiskScore.toString() + ')';
    }
  // Calculate priority risk
    bool priorityRiskSet = true;
  // Calculate priority totals
    priorityRiskScore = 0;
    int i = 0;
    int priorityActivity = 0;
    int priorityDisturbance = 0;
    int priorityExposure = 0;
    int priorityMaint = 0;

    // Activity
    if (priorityActivityMain != null) {
      priorityActivity = priorityActivity + priorityActivityMain;
      i = i + 1;
    }
    if (priorityActivitySecond != null) {
      priorityActivity = priorityActivity + priorityActivitySecond;
      i = i + 1;
    }
    if (i == 0) {
      i = 1;
      priorityRiskSet = false;
    }
    (i > 1) ? priorityRiskScore = priorityRiskScore + ((priorityActivity + 0.9) / i).round() : priorityRiskScore = priorityRiskScore + priorityActivity;
      print ('Average: ' + ((priorityActivity + 0.9) / i).round().toString() + 'Activity: ' + priorityActivity.toString() + ', Counter: ' + i.toString() + ' PriorityRisk ' + priorityRiskScore.toString());
      i = 0;


      // Disturbance
      if (priorityDisturbanceLocation != null) {
        priorityDisturbance = priorityDisturbance + priorityDisturbanceLocation;
        i = i + 1;
      }
      if (priorityDisturbanceAccessibility != null) {
        priorityDisturbance = priorityDisturbance + priorityDisturbanceAccessibility;
        i = i + 1;
      }
      if (priorityDisturbanceExtent != null) {
        priorityDisturbance = priorityDisturbance + priorityDisturbanceExtent;
        i = i + 1;
      }
      if (i == 0) {
        i = 1;
        priorityRiskSet = false;
      }
    (i > 1) ? priorityRiskScore = priorityRiskScore + ((priorityDisturbance + 0.9) / i).round() : priorityRiskScore = priorityRiskScore + priorityDisturbance;
      print ('Average: ' + ((priorityDisturbance + 0.9) / i).round().toString() + 'Disturbance: ' + priorityDisturbance.toString() + ', Counter: ' + i.toString() + ' PriorityRisk ' + priorityRiskScore.toString());
      i = 0;

      // Exposure
      if (priorityExposureOccupants != null) {
        priorityExposure = priorityExposure + priorityExposureOccupants;
        i = i + 1;
      }
      if (priorityExposureUseFreq != null) {
        priorityExposure = priorityExposure + priorityExposureUseFreq;
        i = i + 1;
      }
      if (priorityExposureAvgTime != null) {
        priorityExposure = priorityExposure + priorityExposureAvgTime;
        i = i + 1;
      }
      if (i == 0) {
        i = 1;
        priorityRiskSet = false;
      }
    (i > 1) ? priorityRiskScore = priorityRiskScore + ((priorityExposure + 0.9) / i).round() : priorityRiskScore = priorityRiskScore + priorityExposure;
      print ('Average: ' + ((priorityExposure + 0.9) / i).round().toString() + 'Exposure: ' + priorityExposure.toString() + ', Counter: ' + i.toString() + ' PriorityRisk ' + priorityRiskScore.toString());
      i = 0;

      // Maint
      if (priorityMaintType != null) {
        priorityMaint = priorityMaint + priorityMaintType;
        i = i + 1;
      }
      if (priorityMaintFreq != null) {
        priorityMaint = priorityMaint + priorityMaintFreq;
        i = i + 1;
      }
      if (i == 0) {
        i = 1;
        priorityRiskSet = false;
      }
    (i > 1) ? priorityRiskScore = priorityRiskScore + ((priorityMaint + 0.9) / i).round() : priorityRiskScore = priorityRiskScore + priorityMaint;
      print ('Average: ' + ((priorityMaint + 0.9) / i).round().toString() + 'Maint: ' + priorityMaint.toString() + ', Counter: ' + i.toString() + ' PriorityRisk ' + priorityRiskScore.toString());
      i = 0;

      if (priorityRiskScore > 9) {
        priorityRiskLevel = 3;
        priorityRiskText = 'High (' + priorityRiskScore.toString() + ')';
      } else if (priorityRiskScore > 6) {
        priorityRiskLevel = 2;
        priorityRiskText = 'Medium (' + priorityRiskScore.toString() + ')';
      } else if (priorityRiskScore > 3) {
        priorityRiskLevel = 1;
        priorityRiskText = 'Low (' + priorityRiskScore.toString() + ')';
      } else {
        priorityRiskLevel = 0;
        priorityRiskText = 'Very low (' + priorityRiskScore.toString() + ')';
      }

    int totalRiskScore;
    int totalRiskLevel;
    String totalRiskText;
    bool totalRiskSet;
    // Calculate total
    if (!showMaterialRisk && !showPriorityRisk) {
      totalRiskSet = false;
      totalRiskText = 'No Risk Assessment Done';
    } else if (materialRiskSet && !showPriorityRisk) {
      totalRiskSet = true;
      totalRiskScore = materialRiskScore;
      totalRiskLevel = materialRiskLevel;
      totalRiskText = materialRiskText;
    } else if (priorityRiskSet && materialRiskSet){
      totalRiskSet = true;
      totalRiskScore = priorityRiskScore + materialRiskScore;
      if (totalRiskScore > 18) {
        totalRiskLevel = 3;
        totalRiskText = 'High (' + totalRiskScore.toString() + ')';
      } else if (totalRiskScore > 12) {
        totalRiskLevel = 2;
        totalRiskText = 'Medium (' + totalRiskScore.toString() + ')';
      } else if (totalRiskScore > 6) {
        totalRiskLevel = 1;
        totalRiskText = 'Low (' + totalRiskScore.toString() + ')';
      } else {
        totalRiskLevel = 0;
        totalRiskText = 'Very low (' + totalRiskScore.toString() + ')';
      }
    } else totalRiskSet = false;

      return new Scaffold(
//        resizeToAvoidBottomPadding: false,
          appBar:
          new AppBar(title: Text(_title),
              leading: new IconButton(
                icon: new Icon(Icons.clear),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: <Widget>[
                new IconButton(icon: const Icon(Icons.check), onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    if (arrowPaths.length > 0) {
                      // Convert List of Lists of Offsets into a format Firebase can store
                      // Firebase can't do Lists of Lists
                      acmObj['arrowPaths'] = convertListListOffsetToFirestore(arrowPaths);
                    }

                    Firestore.instance.document(DataManager.get().currentJobPath).collection('acm').document(acmObj['path']).setData(
                        acmObj, merge: true);
                    Navigator.pop(context);
                  }
                })
              ]
          ),
          body: isLoading ?
          loadingPage(loadingText: 'Loading ACM...')
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
  //                padding: new EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 500.0),
  //                child: new Column(
      //                            controller: _scrollController,
      //                            padding: new EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 500.0),
                    children: <Widget>[
                      // SAMPLE PHOTO
                        new Container(
                          alignment: Alignment.center,
                          height: 312.0,
                          width: 240.0,
                          margin: EdgeInsets.only(left: 54.0, right: 54.0,),
                          decoration: BoxDecoration(border: new Border.all(color: Colors.black)),
                          child: SamplePainter(
                            arrowOn: arrowOn,
                            shadeOn: shadeOn,
                            arrowPaths: arrowPaths,
                            shadePaths: shadePaths,
                            pathColour: CompanyColors.resultMid,
                            photo: localPhoto ?
                              new Image.file(new File(acmObj['path_local']))
                                  : (acmObj['path_remote'] != null) ?
                              new CachedNetworkImage(
                                imageUrl: acmObj['path_remote'],
                                placeholder: new CircularProgressIndicator(),
                                errorWidget: new Column(children: <Widget>[Icon(Icons.error), Text('Image Not Found')]),
                                fadeInDuration: new Duration(seconds: 1),
                              )
                              :  new Container(child: Text('NO PHOTO')),
                            updatePaths: (List<Offset> points) {
                              setState(() {
                                offsetPoints = points;
                                arrowPaths.add(offsetPoints);
                              });
                              print('Update Paths: ' + arrowPaths.toString());
                              print('Update Paths ' + offsetPoints.toString());
                            },
                            updatePoints: (List<Offset> points) {
                              setState(() {
                                offsetPoints = points;
                              });
                              print('Update Points: ' + arrowPaths.toString());
                              print('Update Points ' + offsetPoints.toString());
                            },
                          ),
                        ),
                        new Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(bottom: 14.0,),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget> [
                            IconButton(
                              icon: new Icon(Icons.camera, color: CompanyColors.accentRippled, size: 32.0,),
                              onPressed: () {_handleCamera();},
                              padding: EdgeInsets.all(14.0),
                              tooltip: Tip.camera,
                            ),
                            IconButton(
                              icon: new Icon(Icons.image, color: CompanyColors.accentRippled, size: 32.0,),
                              onPressed: () {_handleGallery();},
                              padding: EdgeInsets.all(14.0),
                              tooltip: Tip.gallery,
                            ),
                            IconButton(
                              icon: new Icon(Icons.arrow_forward, color: arrowOn ? CompanyColors.accentRippled : Colors.grey, size: 32.0,),
                              onPressed: () {acmObj['path_local'] != null ? setState((){ arrowOn = !arrowOn; shadeOn = false; }) : null;},
                              padding: EdgeInsets.all(14.0),
                              tooltip: Tip.arrow,
                            ),
                            IconButton(
                              icon: new Icon(Icons.brush, color: shadeOn ? CompanyColors.accentRippled : Colors.grey, size: 32.0,),
                              onPressed: () {acmObj['path_local'] != null ? setState((){ shadeOn = !shadeOn; arrowOn = false; }) : null;},
                              padding: EdgeInsets.all(14.0),
                              tooltip: Tip.shade,
                            ),
                            IconButton(
                              icon: new Icon(Icons.format_color_reset, color: acmObj['path_local'] != null ? CompanyColors.accentRippled : Colors.grey, size: 32.0,),
                              onPressed: () {acmObj['path_local'] != null ? setState((){
                                arrowPaths = new List<List<Offset>>();
                                acmObj['arrowPaths'] = new List<List<Offset>>();
                                acmObj['shadePaths'] = new List<List<Offset>>();
                                print('Paths: ' + acmObj['arrowPaths'].toString());
                              }) : null;},
                              padding: EdgeInsets.all(14.0),
                              tooltip: Tip.reset,
                            ),

                          ])
                        ),

                        // SAMPLE TYPE SELECTORS
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                                onClick: () {
                                  setState(() {
                                    isSampled = false;
                                    acmObj['idkey'] = 'p';
                                  });
                                },
                                dialogHeight: 300.0,
                                selected: acmObj['idkey'] == 'p',
                                score: 1,
                                text: 'P',
                                tooltip: Tip.presume
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                                onClick: () {
                                  setState(() {
                                    isSampled = false;
                                    acmObj['idkey'] = 's';
                                  });
                                },
                                dialogHeight: 300.0,
                                selected: acmObj['idkey'] == 's',
                                score: 2,
                                text: 'S',
                                tooltip: Tip.stronglypresume
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                                onClick: () {
                                  setState(() {
                                    isSampled = true;
                                    acmObj['idkey'] = 'i';
                                  });
                                },
                                dialogHeight: 300.0,
                                selected: acmObj['idkey'] == 'i',
                                score: 3,
                                text: 'I',
                                tooltip: Tip.sample
                            ),),
                          ],
                        ),

                        // Add sample number if sampled
                        acmObj['idkey'] == 'i' ?
                          new Row(children: <Widget>[
                          new Expanded(child:
                          new Column(
                            children: <Widget> [
                              new Container(
                                padding: new EdgeInsets.only(top: 14.0),
                                child: new Text(acmObj['samplenumber'] != null ? 'Sample ' + acmObj['samplenumber'] : 'Sample Number Not Assigned', style: Styles.samplenumber,)
                              ),
                              new Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.only(top: 14.0,),
                                child:
                                new ToolTipButton(
                                    text: "Assign Sample Number",
                                    tooltip: Tip.assignSample,
                                    onClick: () {
                                      Navigator.of(context).push(
                                        new MaterialPageRoute(builder: (context) =>
                                            AssignSampleNumbers(
                                                acm: acmObj)),
                                      );
                                    }
                                ),
                              )
                            ]
                          ))],) : new Container(),

                        // Add option to presume as if strongly presumed
                        acmObj['idkey'] == 's' ?
                            new Row(children: <Widget>[
                            new Expanded(child:
                            new Column(
                              children: <Widget> [
                              acmObj['samplenumber'] != null ?
                              new Container( child: new Text('Sample as ' + acmObj['samplenumber'])) :
                              new Container(),
                              new Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.only(top: 14.0,),
                                child:
                                new ToolTipButton(
                                    text: "Presume As Sample",
                                    tooltip: Tip.presumeAs,
                                    onClick: () {
                                      Navigator.of(context).push(
                                        new MaterialPageRoute(builder: (context) =>
                                            AssignSampleNumbers(
                                                acm: acmObj)),
                                      );
                                    }
                                ),
                              )
                            ]
                          ))],) : new Container(),
                        ExpansionTile(
                          title: new Text("General Information", style: Styles.h2,),
                          initiallyExpanded: true,
                          children: <Widget>[
                            new Container(
                              alignment: Alignment.topLeft,
                              child: new Text("Room Name", style: Styles.label,),
                            ),
                            new Container(
                              alignment: Alignment.topLeft,
                              child: DropdownButton<String>(
                                value: (_room == null) ? null : _room['path'],
                                iconSize: 24.0,
                                items: roomlist.map((Map<String,String> room) {
                                  String val = "Untitled";
                                  if (room['name'] != null && room['roomcode'] != null) {
                                    val = room['name'] + "(" + room['roomcode'] + ")";
                                  } else if (room['name'] != null) {
                                    val = room['name'];
                                  } else if (room['roomcode'] != null) {
                                    val = room['roomcode'];
                                  }
                                  return new DropdownMenuItem<String>(
                                    value: room["path"],
                                    child: new Text(val),
                                  );
                                }).toList(),
                                hint: Text("Room"),
                                onChanged: (value) {
                                  setState(() {
                                    _room = roomlist.firstWhere((e) => e['path'] == value);
                                    acmObj["roompath"] = _room["path"];
                                    acmObj["roomname"] = _room["name"];
                                    DataManager.get().currentRoom = _room['path'];
                                    //                              acm.setData({"room": _room}, merge: true);
                                  });
                                },
                              ),
                            ),
                            new Container(
                              alignment: Alignment.topLeft,
                              child: new TextFormField(
                                decoration: new InputDecoration(
                                    hintText: "e.g. Ceiling, Walls, Floor (2nd layer)",
                                    labelText: "Description/Item"
                                ),
                                onSaved: (String value) {
                                  acmObj["description"] = value.trim();
                                },
                                validator: (String value) {
                                  return value.isEmpty ? 'The description cannot be empty.' : null;
                                },
                                focusNode: _focusNodes[0],
                                initialValue: acmObj["description"],
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.sentences,
                                onFieldSubmitted: (v) {
                                  FocusScope.of(context).requestFocus(_focusNodes[1]);
                                },
                              ),
                            ),
                            new Container(
                              alignment: Alignment.topLeft,
                              child: new TextFormField(
                                decoration: new InputDecoration(
                                    hintText: "e.g. textured plaster, paper-backed vinyl",
                                    labelText: "Material"
                                ),
                                onSaved: (String value) {
                                  acmObj["material"] = value.trim();
                                },
                                validator: (String value) {
                                  return value.isEmpty ? 'The material cannot be empty.' : null;
                                },
                                focusNode: _focusNodes[1],
                                initialValue: acmObj["material"],
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                onFieldSubmitted: (v) {
                                  FocusScope.of(context).requestFocus(_focusNodes[2]);
                                },
                              ),
                            ),

                          ],
                        ),
                    ExpansionTile(
                      title: new Text("Extent", style: Styles.h2,),
                      children: <Widget>[
                      new Container(
                        child: new TextFormField(
                          decoration: new InputDecoration(
                              hintText: "e.g. All plasterboard joins",
                              labelText: "Extent Description"
                          ),
                          onSaved: (String value) {
                            acmObj["extentdesc"] = value.trim();
                          },
                          validator: (String value) {
//                            return value.isEmpty ? 'The extent cannot be empty.' : null;
                          },
                          focusNode: _focusNodes[2],
                          initialValue: acmObj["extentdesc"],
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          autocorrect: true,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(_focusNodes[3]);
                          },
                        ),
                      ),
                      new Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Container(
                            width: 100.0,
                            child: new TextFormField(
                              decoration: new InputDecoration(
                                  labelText: "Extent"
                              ),
                              onSaved: (String value) {
                                acmObj["extent"] = value.trim();
                              },
                              validator: (String value) {
    //                            return value.isEmpty ? 'The material cannot be empty.' : null;
                              },
                              focusNode: _focusNodes[3],
                              initialValue: acmObj["extent"],
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              autocorrect: false,
                              onFieldSubmitted: (v) {
                                if (isSampled)
                                  FocusScope.of(context).requestFocus(_focusNodes[5]);
                                else FocusScope.of(context).requestFocus(_focusNodes[4]);
                              },
                            ),
                          ),
                          new Container(
                            width: 100.0,
//                            padding: EdgeInsets.only(top: 14.0),
                            child: DropdownButton<String>(
                            value: (acmObj["extentunits"] == null) ? "m\u00B2" : acmObj["extentunits"],
                            iconSize: 24.0,
                            items: ["m\u00B2","m","lm","items","m","m\u00B3"].map((unit) {
                              return new DropdownMenuItem<String>(
                                value: unit,
                                child: new Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                acmObj["extentunits"] = value;
                                print(acmObj["extentunits"]);
                                //                              acm.setData({"room": _room}, merge: true);
                              });
                            },
                          ),
                          ),

                        ]
                      ),]),

                      ExpansionTile(
                        title: new Text("Condition", style: Styles.h2,),
                        children: <Widget>[

                      new Container(
                        child: new TextFormField(
                          decoration: new InputDecoration(
                              hintText: "e.g. Chipped edges, exposed fibres",
                              labelText: "Damage Description"
                          ),
                          onSaved: (String value) {
                            acmObj["materialrisk_damagedesc"] = value.trim();
                          },
                          validator: (String value) {
//                            return value.isEmpty ? 'The extent cannot be empty.' : null;
                          },
                          focusNode: _focusNodes[6],
                          initialValue: acmObj["materialrisk_damagedesc"],
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          autocorrect: true,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(_focusNodes[7]);
                          },
                        ),
                      ),

                      new Container(
                        child: new TextFormField(
                          decoration: new InputDecoration(
                              hintText: "e.g. Painted on the outside face",
                              labelText: "Surface Treatment"
                          ),
                          onSaved: (String value) {
                            acmObj["materialrisk_surfacedesc"] = value.trim();
                          },
                          validator: (String value) {
//                            return value.isEmpty ? 'The extent cannot be empty.' : null;
                          },
                          focusNode: _focusNodes[7],
                          initialValue: acmObj["materialrisk_surfacedesc"],
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.sentences,
                          autocorrect: true,
                          onFieldSubmitted: (v) {
//                                  FocusScope.of(context).requestFocus(_focusNodes[3]);
                          },
                        ),
                      ),]),

                    ExpansionTile(
                      title: new Text("Notes", style: Styles.h2,),
                      children: <Widget>[
                      !isSampled ? new Container(
                        child: new TextFormField(
                          decoration: new InputDecoration(
                              hintText: "e.g. The power was not confirmed to be in a zero-energy state",
                              labelText: "Reason for Not Sampling"
                          ),
                          onSaved: (String value) {
                            acmObj["reasonfornotsampling"] = value.trim();
                          },
                          validator: (String value) {
//                            return value.isEmpty ? 'The extent cannot be empty.' : null;
                          },
                          focusNode: _focusNodes[4],
                          initialValue: acmObj["reasonfornotsampling"],
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          autocorrect: true,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(_focusNodes[5]);
                          },
                        ),
                      ) : new Container(),
                      new Container(
                        alignment: Alignment.topLeft,
                        child: new TextFormField(
                          decoration: new InputDecoration(
                              labelText: "Notes"
                          ),
                          onSaved: (String value) {
                            acmObj["notes"] = value.trim();
                          },
                          focusNode: _focusNodes[5],
                          initialValue: acmObj["notes"],
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          autocorrect: true,
                          maxLines: null,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(_focusNodes[6]);
                          },
                        )
  //                      child: TextField(
  //                        decoration: const InputDecoration(
  //                            labelText: "Notes"),
  //                        autocorrect: false,
  //                        controller: controllerNotes,
  //                        textCapitalization: TextCapitalization.sentences,
  //                        keyboardType: TextInputType.multiline,
  //                        maxLines: null,
  //                      ),
                      ),]),
                ExpansionTile(
                  title: new Text("Risk Assessments", style: Styles.h2,),
                  children: <Widget>[
                      // Accessibility Section
                      new Container(alignment: Alignment.bottomLeft,
                          height: 25.0,
                          margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                          child: new Text('Accessibility', style: Styles.h3,)
                      ),
                      new Row(children: <Widget>[
                        new Expanded(child:
                        new ScoreButton(
                            onClick: () {
                              // firestore change score
                              setState(() {
                                if (accessibilityScore == 1) { accessibilityScore = null; }
                                else { accessibilityScore = 1; }
                                acmObj["accessibility"] = accessibilityScore;
  //                              acm.setData({"accessibility": accessibilityScore}, merge: true);
                              });
                            },
                            selected: accessibilityScore == 1,
                            score: 1,
                            text: 'Easy',
                            tooltip: Tip.accessibility_easy
                        ),),
                        new Expanded(child:
                        new ScoreButton(
                            onClick: () {
                              // firestore change score
                              setState(() {
                                if (accessibilityScore == 2) { accessibilityScore = null; }
                                else { accessibilityScore = 2; }
                                acmObj["accessibility"] = accessibilityScore;
  //                              acm.setData({"accessibility": accessibilityScore}, merge: true);
                              });
                            },
                            selected: accessibilityScore == 2,
                            score: 2,
                            text: 'Medium',
                            tooltip: Tip.accessibility_medium
                        ),),
                        new Expanded(child:
                        new ScoreButton(
                            onClick: () {
                              // firestore change score
                              setState(() {
                                if (accessibilityScore == 3) { accessibilityScore = null; }
                                else { accessibilityScore = 3; }
                                acmObj["accessibility"] = accessibilityScore;
  //                              acm.setData({"accessibility": accessibilityScore}, merge: true);
                              });
                            },
                            selected: accessibilityScore == 3,
                            score: 3,
                            text: 'Difficult',
                            tooltip: Tip.accessibility_difficult
                        ),),
                      ],
                      ),

                      // Material Section
                      new Divider(),
                      new Container(
                          child: new Row(children: <Widget>[
                            new Container(
                                width: 200.0,
                              child: Row(children: <Widget>[
                            new Switch(
                              value: showMaterialRisk,
                              onChanged: (bool show) {
                                setState(() {
                                  showMaterialRisk = show;
                                });
                              },
                            ),
                            new Text("Material Risk"),])
                            ),
                            new Container(
                                width: 120.0,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: ScoreButton(
                                  bordercolor: materialRiskSet ? Colors.black26 : Colors.white,
                                  onClick: () {},
                                  selected: true,
                                  score: materialRiskSet ? materialRiskLevel : -1,
                                  textcolor: Colors.black54,
                                  text: materialRiskSet? materialRiskText : 'Incomplete',
                                  radius: 0.0,
                                )
                            ),
                          ],)
                      ),
                      showMaterialRisk ?
                      new Container(
                          child: new Column(children: <Widget>[

                            // PRODUCT SCORE

                            new Container(alignment: Alignment.bottomLeft,
                                height: 25.0,
                                margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                                child: new Text('Product', style: Styles.h3,)
                            ),
                            new Row(children: <Widget>[
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {

                                },
                                selected: false,
                                // -1 = disabled button
                                score: -1,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialProductScore == 1) { materialProductScore = null; }
                                    else { materialProductScore = 1; }
                                    acmObj["materialrisk_productscore"] = materialProductScore;
  //                                  acm.setData({"materialrisk_productscore": materialProductScore}, merge: true);
                                  });
                                },
                                selected: materialProductScore == 1,
                                score: 1,
                                tooltip: Tip.material_product_1,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialProductScore == 2) { materialProductScore = null; }
                                    else { materialProductScore = 2; }
                                    acmObj["materialrisk_productscore"] = materialProductScore;
  //                                  acm.setData({"materialrisk_productscore": materialProductScore}, merge: true);
                                  });
                                },
                                selected: materialProductScore == 2,
                                score: 2,
                                tooltip: Tip.material_product_2,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialProductScore == 3) { materialProductScore = null; }
                                    else { materialProductScore = 3; }
                                    acmObj["materialrisk_productscore"] = materialProductScore;
  //                                  acm.setData({"materialrisk_productscore": materialProductScore}, merge: true);
                                  });
                                },
                                selected: materialProductScore == 3,
                                score: 3,
                                tooltip: Tip.material_product_3,
                              ),),

                            ],
                            ),

                            // DAMAGE SCORE

                            new Container(alignment: Alignment.bottomLeft,
                                height: 25.0,
                                margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                                child: new Text('Damage', style: Styles.h3,)
                            ),
                            new Row(children: <Widget>[
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change
                                  setState(() {
                                    if (materialDamageScore == 0) { materialDamageScore = null; }
                                    else { materialDamageScore = 0; }
                                    acmObj["materialrisk_damagescore"] = materialDamageScore;
  //                                  acm.setData({"materialrisk_damagescore": materialDamageScore}, merge: true);
                                  });
                                },
                                selected: materialDamageScore == 0,
                                score: 0,
                                tooltip: Tip.material_damage_0,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialDamageScore == 1) { materialDamageScore = null; }
                                    else { materialDamageScore = 1; }
                                    acmObj["materialrisk_damagescore"] = materialDamageScore;
  //                                  acm.setData({"materialrisk_damagescore": materialDamageScore}, merge: true);
                                  });
                                },
                                selected: materialDamageScore == 1,
                                score: 1,
                                tooltip: Tip.material_damage_1,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialDamageScore == 2) { materialDamageScore = null; }
                                    else { materialDamageScore = 2; }
                                    acmObj["materialrisk_damagescore"] = materialDamageScore;
  //                                  acm.setData({"materialrisk_damagescore": materialDamageScore}, merge: true);
                                  });
                                },
                                selected: materialDamageScore == 2,
                                score: 2,
                                tooltip: Tip.material_damage_2,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialDamageScore == 3) { materialDamageScore = null; }
                                    else { materialDamageScore = 3; }
                                    acmObj["materialrisk_damagescore"] = materialDamageScore;
  //                                  acm.setData({"materialrisk_damagescore": materialDamageScore}, merge: true);
                                  });
                                },
                                selected: materialDamageScore == 3,
                                score: 3,
                                tooltip: Tip.material_damage_3,
                              ),),

                            ],
                            ),

                            // SURFACE SCORE

                            new Container(alignment: Alignment.bottomLeft,
                                height: 25.0,
                                margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                                child: new Text('Surface', style: Styles.h3,)
                            ),
                            new Row(children: <Widget>[
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialSurfaceScore == 0) { materialSurfaceScore = null; }
                                    else { materialSurfaceScore = 0; }
                                    acmObj["materialrisk_surfacescore"] = materialSurfaceScore;
  //                                  acm.setData({"materialrisk_surfacescore": materialSurfaceScore}, merge: true);
                                  });
                                },
                                selected: materialSurfaceScore == 0,
                                score: 0,
                                tooltip: Tip.material_surface_0,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialSurfaceScore == 1) { materialSurfaceScore = null; }
                                    else { materialSurfaceScore = 1; }
                                    acmObj["materialrisk_surfacescore"] = materialSurfaceScore;
  //                                  acm.setData({"materialrisk_surfacescore": materialSurfaceScore}, merge: true);
                                  });
                                },
                                selected: materialSurfaceScore == 1,
                                score: 1,
                                tooltip: Tip.material_surface_1,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialSurfaceScore == 2) { materialSurfaceScore = null; }
                                    else { materialSurfaceScore = 2; }
                                    acmObj["materialrisk_surfacescore"] = materialSurfaceScore;
  //                                  acm.setData({"materialrisk_surfacescore": materialSurfaceScore}, merge: true);
                                  });
                                },
                                selected: materialSurfaceScore == 2,
                                score: 2,
                                tooltip: Tip.material_surface_2,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialSurfaceScore == 3) { materialSurfaceScore = null; }
                                    else { materialSurfaceScore = 3; }
                                    acmObj["materialrisk_surfacescore"] = materialSurfaceScore;
  //                                  acm.setData({"materialrisk_surfacescore": materialSurfaceScore}, merge: true);
                                  });
                                },
                                selected: materialSurfaceScore == 3,
                                score: 3,
                                tooltip: Tip.material_surface_3,
                              ),),

                            ],
                            ),

                            // ASBESTOS SCORE

                            new Container(alignment: Alignment.bottomLeft,
                                height: 25.0,
                                margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                                child: new Text('Asbestos Type', style: Styles.h3,)
                            ),
                            new Row(children: <Widget>[
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {

                                },
                                selected: false,
                                // -1 = disabled button
                                score: -1,
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialAsbestosScore == 1) { materialAsbestosScore = null; }
                                    else { materialAsbestosScore = 1; }
                                    acmObj["materialrisk_asbestosscore"] = materialAsbestosScore;
  //                                  acm.setData({"materialrisk_asbestosscore": materialAsbestosScore}, merge: true);
                                  });
                                },
                                selected: materialAsbestosScore == 1,
                                score: 1,
                                tooltip: Tip.material_asbestos_1,
      //                                        text: 'ch'
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialAsbestosScore == 2) { materialAsbestosScore = null; }
                                    else { materialAsbestosScore = 2; }
                                    acmObj["materialrisk_asbestosscore"] = materialAsbestosScore;
  //                                  acm.setData({"materialrisk_asbestosscore": materialAsbestosScore}, merge: true);
                                  });
                                },
                                selected: materialAsbestosScore == 2,
                                score: 2,
                                tooltip: Tip.material_asbestos_2,
      //                                        text: 'am'
                              ),),
                              new Expanded(child:
                              new ScoreButton(
                                onClick: () {
                                  // firestore change score
                                  setState(() {
                                    if (materialAsbestosScore == 3) { materialAsbestosScore = null; }
                                    else { materialAsbestosScore = 3; }
                                    acmObj["materialrisk_asbestosscore"] = materialAsbestosScore;
  //                                  acm.setData({"materialrisk_asbestosscore": materialAsbestosScore}, merge: true);
                                  });
                                },
                                selected: materialAsbestosScore == 3,
                                score: 3,
                                tooltip: Tip.material_asbestos_3,
      //                                        text: 'cr'
                              ),),

                            ],
                            ),
                          ],
                          )
                      )
                          : Container(),

                      // Priority Section
                      new Divider(),
                      new Container(
                          child: new Row(children: <Widget>[
                            new Container(
                                width: 200.0,
                                child: Row(children: <Widget>[
                                  new Switch(
                                    value: showPriorityRisk,
                                    onChanged: (bool show) {
                                      setState(() {
                                        showPriorityRisk = show;
                                      });
                                    },
                                  ),
                                  new Text("Priority Risk"),])
                            ),
                            new Container(
                                width: 120.0,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: ScoreButton(
                                  bordercolor: priorityRiskSet ? Colors.black26 : Colors.white,
                                  onClick: () {},
                                  selected: true,
                                  score: priorityRiskSet ? priorityRiskLevel : -1,
                                  textcolor: Colors.black54,
                                  text: priorityRiskSet ? priorityRiskText : 'Incomplete',
                                  radius: 0.0,
                                )
                            ),
                          ],)
                      ),

                      showPriorityRisk ?
                      new Container(
                        child: new Column(children: <Widget>[
                          // ACTIVITY

                          // MAIN ACTIVITY
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Main Activity', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivityMain == 0) { priorityActivityMain = null; }
                                  else { priorityActivityMain = 0; }
                                  acmObj["priority_activity_main"] = priorityActivityMain;
  //                                acm.setData({"priority_activity_main": priorityActivityMain}, merge: true);
                                });
                              },
                              selected: priorityActivityMain == 0,
                              score: 0,
                              tooltip: Tip.priority_activity_main_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivityMain == 1) { priorityActivityMain = null; }
                                  else { priorityActivityMain = 1; }
                                  acmObj["priority_activity_main"] = priorityActivityMain;
  //                                acm.setData({"priority_activity_main": priorityActivityMain}, merge: true);
                                });
                              },
                              selected: priorityActivityMain == 1,
                              score: 1,
                              tooltip: Tip.priority_activity_main_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivityMain == 2) { priorityActivityMain = null; }
                                  else { priorityActivityMain = 2; }
                                  acmObj["priority_activity_main"] = priorityActivityMain;
  //                                acm.setData({"priority_activity_main": priorityActivityMain}, merge: true);
                                });
                              },
                              selected: priorityActivityMain == 2,
                              score: 2,
                              tooltip: Tip.priority_activity_main_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivityMain == 3) { priorityActivityMain = null; }
                                  else { priorityActivityMain = 3; }
                                  acmObj["priority_activity_main"] = priorityActivityMain;
  //                                acm.setData({"priority_activity_main": priorityActivityMain}, merge: true);
                                });
                              },
                              selected: priorityActivityMain == 3,
                              score: 3,
                              tooltip: Tip.priority_activity_main_3,
                            ),),

                          ],
                          ),

                          // SECOND ACTIVITY
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Secondary Activity', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivitySecond == 0) { priorityActivitySecond = null; }
                                  else { priorityActivitySecond = 0; }
                                  acmObj["priority_activity_second"] = priorityActivitySecond;
  //                                acm.setData({"priority_activity_second": priorityActivitySecond}, merge: true);
                                });
                              },
                              selected: priorityActivitySecond == 0,
                              score: 0,
                              tooltip: Tip.priority_activity_secondary_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivitySecond == 1) { priorityActivitySecond = null; }
                                  else { priorityActivitySecond = 1; }
                                  acmObj["priority_activity_second"] = priorityActivitySecond;
  //                                acm.setData({"priority_activity_second": priorityActivitySecond}, merge: true);
                                });
                              },
                              selected: priorityActivitySecond == 1,
                              score: 1,
                              tooltip: Tip.priority_activity_secondary_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivitySecond == 2) { priorityActivitySecond = null; }
                                  else { priorityActivitySecond = 2; }
                                  acmObj["priority_activity_second"] = priorityActivitySecond;
  //                                acm.setData({"priority_activity_second": priorityActivitySecond}, merge: true);
                                });
                              },
                              selected: priorityActivitySecond == 2,
                              score: 2,
                              tooltip: Tip.priority_activity_secondary_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityActivitySecond == 3) { priorityActivitySecond = null; }
                                  else { priorityActivitySecond = 3; }
                                  acmObj["priority_activity_second"] = priorityActivitySecond;
  //                                acm.setData({"priority_activity_second": priorityActivitySecond}, merge: true);
                                });
                              },
                              selected: priorityActivitySecond == 3,
                              score: 3,
                              tooltip: Tip.priority_activity_secondary_3,
                            ),),

                          ],
                          ),

                          new Divider(),

                          // LOCATION
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Location', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceLocation == 0) { priorityDisturbanceLocation = null; }
                                  else { priorityDisturbanceLocation = 0; }
                                  acmObj["priority_disturbance_location"] = priorityDisturbanceLocation;
  //                                acm.setData({"priority_disturbance_location": priorityDisturbanceLocation}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceLocation == 0,
                              score: 0,
                              tooltip: Tip.priority_disturbance_location_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceLocation == 1) { priorityDisturbanceLocation = null; }
                                  else { priorityDisturbanceLocation = 1; }
                                  acmObj["priority_disturbance_location"] = priorityDisturbanceLocation;
  //                                acm.setData({"priority_disturbance_location": priorityDisturbanceLocation}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceLocation == 1,
                              score: 1,
                              tooltip: Tip.priority_disturbance_location_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceLocation == 2) { priorityDisturbanceLocation = null; }
                                  else { priorityDisturbanceLocation = 2; }
                                  acmObj["priority_disturbance_location"] = priorityDisturbanceLocation;
  //                                acm.setData({"priority_disturbance_location": priorityDisturbanceLocation}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceLocation == 2,
                              score: 2,
                              tooltip: Tip.priority_disturbance_location_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceLocation == 3) { priorityDisturbanceLocation = null; }
                                  else { priorityDisturbanceLocation = 3; }
                                  acmObj["priority_disturbance_location"] = priorityDisturbanceLocation;
  //                                acm.setData({"priority_disturbance_location": priorityDisturbanceLocation}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceLocation == 3,
                              score: 3,
                              tooltip: Tip.priority_disturbance_location_3,
                            ),),

                          ],
                          ),

                          // ACCESS
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Accessibility', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceAccessibility == 0) { priorityDisturbanceAccessibility = null; }
                                  else { priorityDisturbanceAccessibility = 0; }
                                  acmObj["priority_disturbance_accessibility"] = priorityDisturbanceAccessibility;
  //                                acm.setData({"priority_disturbance_accessibility": priorityDisturbanceAccessibility}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceAccessibility == 0,
                              score: 0,
                              tooltip: Tip.priority_disturbance_accessibility_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceAccessibility == 1) { priorityDisturbanceAccessibility = null; }
                                  else { priorityDisturbanceAccessibility = 1; }
                                  acmObj["priority_disturbance_accessibility"] = priorityDisturbanceAccessibility;
  //                                acm.setData({"priority_disturbance_accessibility": priorityDisturbanceAccessibility}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceAccessibility == 1,
                              score: 1,
                              tooltip: Tip.priority_disturbance_accessibility_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceAccessibility == 2) { priorityDisturbanceAccessibility = null; }
                                  else { priorityDisturbanceAccessibility = 2; }
                                  acmObj["priority_disturbance_accessibility"] = priorityDisturbanceAccessibility;
  //                                acm.setData({"priority_disturbance_accessibility": priorityDisturbanceAccessibility}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceAccessibility == 2,
                              score: 2,
                              tooltip: Tip.priority_disturbance_accessibility_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceAccessibility == 3) { priorityDisturbanceAccessibility = null; }
                                  else { priorityDisturbanceAccessibility = 3; }
                                  acmObj["priority_disturbance_accessibility"] = priorityDisturbanceAccessibility;
  //                                acm.setData({"priority_disturbance_accessibility": priorityDisturbanceAccessibility}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceAccessibility == 3,
                              score: 3,
                              tooltip: Tip.priority_disturbance_accessibility_3,
                            ),),

                          ],
                          ),

                          //EXTENT
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Extent', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceExtent == 0) { priorityDisturbanceExtent = null; }
                                  else { priorityDisturbanceExtent = 0; }
                                  acmObj["priority_disturbance_extent"] = priorityDisturbanceExtent;
  //                                acm.setData({"priority_disturbance_extent": priorityDisturbanceExtent}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceExtent == 0,
                              score: 0,
                              tooltip: Tip.priority_disturbance_extent_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceExtent == 1) { priorityDisturbanceExtent = null; }
                                  else { priorityDisturbanceExtent = 1; }
                                  acmObj["priority_disturbance_extent"] = priorityDisturbanceExtent;
  //                                acm.setData({"priority_disturbance_extent": priorityDisturbanceExtent}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceExtent == 1,
                              score: 1,
                              tooltip: Tip.priority_disturbance_extent_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceExtent == 2) { priorityDisturbanceExtent = null; }
                                  else { priorityDisturbanceExtent = 2; }
                                  acmObj["priority_disturbance_extent"] = priorityDisturbanceExtent;
  //                                acm.setData({"priority_disturbance_extent": priorityDisturbanceExtent}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceExtent == 2,
                              score: 2,
                              tooltip: Tip.priority_disturbance_extent_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityDisturbanceExtent == 3) { priorityDisturbanceExtent = null; }
                                  else { priorityDisturbanceExtent = 3; }
                                  acmObj["priority_disturbance_extent"] = priorityDisturbanceExtent;
  //                                acm.setData({"priority_disturbance_extent": priorityDisturbanceExtent}, merge: true);
                                });
                              },
                              selected: priorityDisturbanceExtent == 3,
                              score: 3,
                              tooltip: Tip.priority_disturbance_extent_3,
                            ),),

                          ],
                          ),

                          new Divider(),

                          //OCCUPANTS
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Occupants', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureOccupants == 0) { priorityExposureOccupants = null; }
                                  else { priorityExposureOccupants = 0; }
                                  acmObj["priority_exposure_occupants"] = priorityExposureOccupants;
  //                                acm.setData({"priority_exposure_occupants": priorityExposureOccupants}, merge: true);
                                });
                              },
                              selected: priorityExposureOccupants == 0,
                              score: 0,
                              tooltip: Tip.priority_exposure_occupants_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureOccupants == 1) { priorityExposureOccupants = null; }
                                  else { priorityExposureOccupants = 1; }
                                  acmObj["priority_exposure_occupants"] = priorityExposureOccupants;
  //                                acm.setData({"priority_exposure_occupants": priorityExposureOccupants}, merge: true);
                                });
                              },
                              selected: priorityExposureOccupants == 1,
                              score: 1,
                              tooltip: Tip.priority_exposure_occupants_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureOccupants == 2) { priorityExposureOccupants = null; }
                                  else { priorityExposureOccupants = 2; }
                                  acmObj["priority_exposure_occupants"] = priorityExposureOccupants;
  //                                acm.setData({"priority_exposure_occupants": priorityExposureOccupants}, merge: true);
                                });
                              },
                              selected: priorityExposureOccupants == 2,
                              score: 2,
                              tooltip: Tip.priority_exposure_occupants_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureOccupants == 3) { priorityExposureOccupants = null; }
                                  else { priorityExposureOccupants = 3; }
                                  acmObj["priority_exposure_occupants"] = priorityExposureOccupants;
  //                                acm.setData({"priority_exposure_occupants": priorityExposureOccupants}, merge: true);
                                });
                              },
                              selected: priorityExposureOccupants == 3,
                              score: 3,
                              tooltip: Tip.priority_exposure_occupants_3,
                            ),),

                          ],
                          ),

                          //USEFREQ
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Use Frequency', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureUseFreq == 0) { priorityExposureUseFreq = null; }
                                  else { priorityExposureUseFreq = 0; }
                                  acmObj["priority_exposure_usefreq"] = priorityExposureUseFreq;
  //                                acm.setData({"priority_exposure_usefreq": priorityExposureUseFreq}, merge: true);
                                });
                              },
                              selected: priorityExposureUseFreq == 0,
                              score: 0,
                              tooltip: Tip.priority_exposure_usefreq_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureUseFreq == 1) { priorityExposureUseFreq = null; }
                                  else { priorityExposureUseFreq = 1; }
                                  acmObj["priority_exposure_usefreq"] = priorityExposureUseFreq;
  //                                acm.setData({"priority_exposure_usefreq": priorityExposureUseFreq}, merge: true);
                                });
                              },
                              selected: priorityExposureUseFreq == 1,
                              score: 1,
                              tooltip: Tip.priority_exposure_usefreq_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureUseFreq == 2) { priorityExposureUseFreq = null; }
                                  else { priorityExposureUseFreq = 2; }
                                  acmObj["priority_exposure_usefreq"] = priorityExposureUseFreq;
  //                                acm.setData({"priority_exposure_usefreq": priorityExposureUseFreq}, merge: true);
                                });
                              },
                              selected: priorityExposureUseFreq == 2,
                              score: 2,
                              tooltip: Tip.priority_exposure_usefreq_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureUseFreq == 3) { priorityExposureUseFreq = null; }
                                  else { priorityExposureUseFreq = 3; }
                                  acmObj["priority_exposure_usefreq"] = priorityExposureUseFreq;
  //                                acm.setData({"priority_exposure_usefreq": priorityExposureUseFreq}, merge: true);
                                });
                              },
                              selected: priorityExposureUseFreq == 3,
                              score: 3,
                              tooltip: Tip.priority_exposure_usefreq_3,
                            ),),

                          ],
                          ),

                          //AVG TIME
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Average Time', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureAvgTime == 0) { priorityExposureAvgTime = null; }
                                  else { priorityExposureAvgTime = 0; }
                                  acmObj["priority_exposure_avgtime"] = priorityExposureAvgTime;
  //                                acm.setData({"priority_exposure_avgtime": priorityExposureAvgTime}, merge: true);
                                });
                              },
                              selected: priorityExposureAvgTime == 0,
                              score: 0,
                              tooltip: Tip.priority_exposure_avgtime_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureAvgTime == 1) { priorityExposureAvgTime = null; }
                                  else { priorityExposureAvgTime = 1; }
                                  acmObj["priority_exposure_avgtime"] = priorityExposureAvgTime;
  //                                acm.setData({"priority_exposure_avgtime": priorityExposureAvgTime}, merge: true);
                                });
                              },
                              selected: priorityExposureAvgTime == 1,
                              score: 1,
                              tooltip: Tip.priority_exposure_avgtime_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureAvgTime == 2) { priorityExposureAvgTime = null; }
                                  else { priorityExposureAvgTime = 2; }
                                  acmObj["priority_exposure_avgtime"] = priorityExposureAvgTime;
  //                                acm.setData({"priority_exposure_avgtime": priorityExposureAvgTime}, merge: true);
                                });
                              },
                              selected: priorityExposureAvgTime == 2,
                              score: 2,
                              tooltip: Tip.priority_exposure_avgtime_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityExposureAvgTime == 3) { priorityExposureAvgTime = null; }
                                  else { priorityExposureAvgTime = 3; }
                                  acmObj["priority_exposure_avgtime"] = priorityExposureAvgTime;
  //                                acm.setData({"priority_exposure_avgtime": priorityExposureAvgTime}, merge: true);
                                });
                              },
                              selected: priorityExposureAvgTime == 3,
                              score: 3,
                              tooltip: Tip.priority_exposure_avgtime_3,
                            ),),

                          ],
                          ),

                          new Divider(),

                          //MAINT TYPE
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Maintenance Type', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintType == 0) { priorityMaintType = null; }
                                  else { priorityMaintType = 0; }
                                  acmObj["priority_maint_type"] = priorityMaintType;
  //                                acm.setData({"priority_maint_type": priorityMaintType}, merge: true);
                                });
                              },
                              selected: priorityMaintType == 0,
                              score: 0,
                              tooltip: Tip.priority_maint_type_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintType == 1) { priorityMaintType = null; }
                                  else { priorityMaintType = 1; }
                                  acmObj["priority_maint_type"] = priorityMaintType;
  //                                acm.setData({"priority_maint_type": priorityMaintType}, merge: true);
                                });
                              },
                              selected: priorityMaintType == 1,
                              score: 1,
                              tooltip: Tip.priority_maint_type_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintType == 2) { priorityMaintType = null; }
                                  else { priorityMaintType = 2; }
                                  acmObj["priority_maint_type"] = priorityMaintType;
  //                                acm.setData({"priority_maint_type": priorityMaintType}, merge: true);
                                });
                              },
                              selected: priorityMaintType == 2,
                              score: 2,
                              tooltip: Tip.priority_maint_type_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintType == 3) { priorityMaintType = null; }
                                  else { priorityMaintType = 3; }
                                  acmObj["priority_maint_type"] = priorityMaintType;
  //                                acm.setData({"priority_maint_type": priorityMaintType}, merge: true);
                                });
                              },
                              selected: priorityMaintType == 3,
                              score: 3,
                              tooltip: Tip.priority_maint_type_3,
                            ),),

                          ],
                          ),

                          // MAINT FREQ
                          new Container(alignment: Alignment.bottomLeft,
                              height: 25.0,
                              margin: EdgeInsets.only(left: 12.0, bottom: 2.0),
                              child: new Text('Maintenance Frequency', style: Styles.h3,)
                          ),
                          new Row(children: <Widget>[
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintFreq == 0) { priorityMaintFreq = null; }
                                  else { priorityMaintFreq = 0; }
                                  acmObj["priority_maint_freq"] = priorityMaintFreq;
  //                                acm.setData({"priority_maint_freq": priorityMaintFreq}, merge: true);
                                });
                              },
                              selected: priorityMaintFreq == 0,
                              score: 0,
                              tooltip: Tip.priority_maint_freq_0,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintFreq == 1) { priorityMaintFreq = null; }
                                  else { priorityMaintFreq = 1; }
                                  acmObj["priority_maint_freq"] = priorityMaintFreq;
  //                                acm.setData({"priority_maint_freq": priorityMaintFreq}, merge: true);
                                });
                              },
                              selected: priorityMaintFreq == 1,
                              score: 1,
                              tooltip: Tip.priority_maint_freq_1,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintFreq == 2) { priorityMaintFreq = null; }
                                  else { priorityMaintFreq = 2; }
                                  acmObj["priority_maint_freq"] = priorityMaintFreq;
  //                                acm.setData({"priority_maint_freq": priorityMaintFreq}, merge: true);
                                });
                              },
                              selected: priorityMaintFreq == 2,
                              score: 2,
                              tooltip: Tip.priority_maint_freq_2,
                            ),),
                            new Expanded(child:
                            new ScoreButton(
                              onClick: () {
                                // firestore change score
                                setState(() {
                                  if (priorityMaintFreq == 3) { priorityMaintFreq = null; }
                                  else { priorityMaintFreq = 3; }
                                  acmObj["priority_maint_freq"] = priorityMaintFreq;
  //                                acm.setData({"priority_maint_freq": priorityMaintFreq}, merge: true);
                                });
                              },
                              selected: priorityMaintFreq == 3,
                              score: 3,
                              tooltip: Tip.priority_maint_freq_3,
                            ),),

                          ],
                          ),
                        ]),
                      )
                          : new Container(),
                      new Divider(),

                      // Total Risk
                      new Container(
                          width: 120.0,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: ScoreButton(
                            bordercolor: totalRiskSet ? Colors.black26 : Colors.white,
                            onClick: () {},
                            selected: true,
                            score: totalRiskSet ? totalRiskLevel : -1,
                            textcolor: Colors.black54,
                            text: totalRiskSet ? totalRiskText : 'Incomplete',
                            radius: 0.0,
                          )
                      ),]),
                      widget.acm != null ?
                      new Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.only(top: 14.0,),
                        child: new OutlineButton(
                          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                          child: Text("Delete ACM",
                              style: new TextStyle(color: Theme.of(context).accentColor, fontWeight: FontWeight.bold
                              )
                          ),
//                          color: Colors.white,
                          onPressed: () {
                            _deleteDialog();
                          }
                        ),
                      ) : new Container(),
                  ],)
                )
        ),
      );
  }

  void _deleteDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text('Delete ACM'),
            content: new Text('Are you sure you wish to delete this ACM (' + acmObj['description'] + ' ' + acmObj['material'] + ')?'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel', style: new TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                  child: new Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteACM();
                  }
              ),
            ],
          );
        }
    );
  }

  void _deleteACM() {
    // Remove images
    if (acmObj['storage_ref'] != null)
      FirebaseStorage.instance.ref().child(acmObj['storage_ref']).delete();

    // Remove ACM
    Firestore.instance.document(DataManager.get().currentJobPath).collection('acm').document(widget.acm).delete();

    // Pop
    Navigator.pop(context);
  }

  void _loadACM() async {
    // Load rooms from job
    QuerySnapshot roomSnapshot = await Firestore.instance.document(DataManager.get().currentJobPath).collection('rooms').getDocuments();
    roomSnapshot.documents.forEach((doc) {
      if (doc['roomtype'] != 'group')
        roomlist.add({"name": doc.data['name'], "path": doc.documentID});
    });
//    print('ROOMLIST ' + roomlist.toString());

    // Load samples from job
    QuerySnapshot sampleSnapshot = await Firestore.instance.collection('samplesasbestos').where('jobNumber',isEqualTo: DataManager.get().currentJobNumber).orderBy("samplenumber").getDocuments();
    sampleSnapshot.documents.forEach((doc) => samplelist.add({"name": doc.data['samplenumber'].toString() + ': ' + doc.data['description'],"path": doc.documentID}));
//    print('ROOMLIST ' + roomlist.toString());
//    print('SAMPLE ' + samplelist.toString());

//    roomlist = [{"name": "Lounge","path": "lounge"}];

    if (widget.acm == null) {
      String room = DataManager.get().currentRoom;
      if (room == null || !roomlist.map((room) => room['path']).contains(room)) {
        room = '';
      } else {
        _room = {"path": room, "name": ''};
      }

      acmObj['jobnumber'] = DataManager
          .get()
          .currentJobNumber;
      //      sample.sampleNumber = DataManager.get().getHighestSampleNumber(DataManager.get().currentJob) + 1;
      acmObj['sample'] = null;
      acmObj['idkey'] = 'p';
      acmObj['description'] = null;
      acmObj['material'] = null;
      acmObj['path_local'] = null;
      acmObj['path_remote'] = null;
      acmObj['roompath'] = room;
      acmObj['materialrisk_asbestosscore'] = 3;
      materialAsbestosScore = 3;

      // New room requires us to create a path so it doesn't need internet to get one from Firestore
      acmObj['path'] = new Uuid().v1();
//      acmObj['arrowPaths'] = arrowPaths;
//      acmObj['shadePaths'] = new List<List<Offset>>();

      setState(() {
        isLoading = false;
      });
    } else {
      _title = "Edit ACM";
      acm.get().then((doc) {
        acmObj = doc.data;
        // Get sample details if available
        if (doc.data['sample'] != 'null') {
//          sample =  Firestore.instance.collection('samplesasbestosbulk').document(doc.data['sample']);
        }

        if (acmObj['arrowPaths'] != null) arrowPaths = convertFirestoreToListListOffset(acmObj['arrowPaths']);
          else arrowPaths = new List<List<Offset>>();
        if (acmObj['shadePaths'] != null) shadePaths = convertFirestoreToListListOffset(acmObj['shadePaths']);
          else shadePaths = new List<List<Offset>>();
        if (acmObj['idkey'] == 'i') {
          isSampled = true;
          stronglyPresumed = false;
        } else {
          isSampled = false;
          if (acmObj['idkey'] == 's') {
            stronglyPresumed = true;
          } else {
            stronglyPresumed = false;
          }
        }
        _room = {"path": doc.data['roompath'], "name": doc.data['roomname']};
        print('Loading acm');
//        initialDescription = doc.data['description'];
//        materialText = doc.data['material'];
//        initialMaterial = doc.data['material'];
        controllerNotes.text = doc.data['notes'];

        accessibilityScore = doc.data['accessibility'];

        // Material Risk assessment
        materialProductScore = doc.data['materialrisk_productscore'];
        materialDamageScore = doc.data['materialrisk_damagescore'];
        materialSurfaceScore = doc.data['materialrisk_surfacescore'];
        materialAsbestosScore = doc.data['materialrisk_asbestosscore'];
//        initialDamage = doc.data['materialrisk_damagedesc'];
//        initialSurface = doc.data['materialrisk_surfacedesc'];

        // Priority Risk Assessment
        priorityActivityMain = doc.data['priority_activity_main'];
        priorityActivitySecond = doc.data['priority_activity_second'];
        priorityDisturbanceLocation = doc.data['priority_disturbance_location'];
        priorityDisturbanceAccessibility = doc.data['priority_disturbance_accessibility'];
        priorityDisturbanceExtent = doc.data['priority_disturbance_extent'];
        priorityExposureOccupants = doc.data['priority_exposure_occupants'];
        priorityExposureUseFreq = doc.data['priority_exposure_usefreq'];
        priorityExposureAvgTime = doc.data['priority_exposure_avgtime'];
        priorityMaintType = doc.data['priority_maint_type'];
        priorityMaintFreq = doc.data['priority_maint_freq'];

        // image
        if (doc.data['path_remote'] == null && doc.data['path_local'] != null){
          // only local image available (e.g. when taking photos with no internet)
          _handleImageUpload(File(doc.data['path_local']));
          localPhoto = true;
        } else if (doc.data['path_remote'] != null) {
          localPhoto = false;
        }
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  void _handleImageUpload(File image) async {
    String room_name;
    String item_name;
    String storageRef = acmObj['storage_ref'];
    String path = widget.acm;
    if (_room == null) {
      room_name = 'room';
    } else {
      if (_room['name'] == null)
        room_name = 'room';
      else
        room_name = _room['name'];
      if (acmObj['description'] == null) {
        item_name = 'description';
      } else
        item_name = acmObj['description'];
    }
    setState(() {
      acmObj["path_local"] = image.path;
      acmObj["path_remote"] = '';
      acmObj["storage_ref"] = '';
    });

    ImageSync(
        image,
        50,
        "acm" + room_name + "-" + item_name,
        "jobs/" + DataManager.get().currentJobNumber,
        acm
    ).then((refs) {
      // Delete old photo
      if (storageRef != null) FirebaseStorage.instance.ref().child(storageRef).delete();

      if (this.mounted) {
        setState((){
          acmObj['path_remote'] = refs['downloadURL'];
          acmObj['storage_ref'] = refs['storageRef'];
          localPhoto = false;
        });
      } else {
        // User has left the page, upload url straight to firestore
        Firestore.instance.document(DataManager
            .get()
            .currentJobPath).collection('acm')
            .document(path)
            .setData(
            {"path_remote": refs['downloadURL'], 'storage_ref': refs['storageRef'], }, merge: true);
      }
    });
  }

  void _handleGallery() async {
    var result = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (result != null) {
        localPhoto = true;
        _handleImageUpload(result);
      }
    });
  }

  void _handleCamera() async {
    var result = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      if (result != null) {
        localPhoto = true;
        _handleImageUpload(result);
      }
    });
  }
}