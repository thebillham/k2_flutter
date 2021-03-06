import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/styles.dart';
import 'package:k2e/widgets/buttons.dart';
import 'package:k2e/widgets/common_widgets.dart';
import 'package:k2e/widgets/custom_auto_complete.dart';
import 'package:k2e/widgets/custom_typeahead.dart';
import 'package:k2e/widgets/date_picker.dart';
import 'package:uuid/uuid.dart';

class EditHistoricCoc extends StatefulWidget {
  EditHistoricCoc({Key key, this.cocObj}) : super(key: key);
  Map<String, dynamic> cocObj = new Map<String, dynamic>();
  @override
  _EditHistoricCocState createState() => new _EditHistoricCocState();
}

class _EditHistoricCocState extends State<EditHistoricCoc> {
  String _title = "Edit Chain of Custody";
  bool isLoading = true;
  Map<String, dynamic> cocObj = new Map<String, dynamic>();

  // images
  String version;
  final Map constants = DataManager.get().constants;
  GlobalKey key = new GlobalKey<AutoCompleteTextFieldState<String>>();

  List rooms;
  List items;
  List materials;
  List<String> personnelSelected = <String>[];
  List<DateTime> datesSelected = <DateTime>[];
  Map<String, dynamic> samples = new Map<String, dynamic>();
  int samplesLength = 10;

  var _formKey = GlobalKey<FormState>();

//  GlobalKey formFieldKey = new GlobalKey<AutoCompleteFormFieldState<String>>();

  ScrollController _scrollController;

  // Create list of focus nodes
  final _focusNodes = List<FocusNode>.generate(
    200,
        (i) => FocusNode(),
  );

  @override
  void initState() {
    _loadCoc();
    _scrollController = ScrollController();

    items = constants['buildingitems'];
    materials = constants['buildingmaterials'];
    super.initState();
  }

  Future<Null> _selectDate(BuildContext context) async {
    final List<DateTime> picked = await showMultiDatePicker(
        context: context,
        initialDates: datesSelected,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(new Duration(days: 365)));
    if (picked != null)
      picked.sort();
    setState(() {
      datesSelected = picked;
    });
  }

  Widget build(BuildContext context) {
    print(samples.toString());
    if (cocObj['currentVersion'] == null)
      version = 'Not yet issued';
    else {
      version = 'Latest version: ' + cocObj['currentVersion'].toString();
      if (!cocObj['versionUpToDate']) version = version + ' (needs reissue)';
    }
    // TODO add in text edits to add name of testing company, who it was for, date, type of survey etc. etc.
    print(personnelSelected.toString());
    print(datesSelected.toString());
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
                    cocObj['personnel'] = personnelSelected;
                    cocObj['dates'] = datesSelected;
                    Firestore.instance
                        .collection('lab').document('asbestos')
                        .collection('cocs')
                        .document(cocObj['uid'])
                        .setData(cocObj);
                    Navigator.pop(context);
                  }
                })
          ]),
      body: isLoading
          ? LoadingPage(loadingText: 'Loading Chain of Custody...')
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
                Container(
                  height: 16.0,
                ),
                Text(
                  cocObj['client'],
                  style: Styles.h2,
                ),
                Text(
                  cocObj['address'],
                  style: Styles.h3,
                ),
                Text(version, style: Styles.comment),
                new Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.only(top: 14.0, bottom: 8.0),
                  child: new Text(
                    "Sample Date(s)",
                    style: Styles.label,
                  ),
                ),
                Text(datesSelected.length > 0 ? datesSelected.map((date) => new DateFormat('d MMMM yyyy').format(date)).join("\n") : 'No dates selected'),
                FunctionButton(
                  text: "Select Dates",
                  onClick: () => _selectDate(context)
                ),
                new Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.only(
                    top: 14.0,
                  ),
                  child: new Text(
                    "Sampled By",
                    style: Styles.label,
                  ),
                ),

                ExpansionTile(
                  initiallyExpanded: true,
                  title: new Text(
                    "Samples",
                    style: Styles.h2,
                  ),
                  children: <Widget>[
                    FunctionButton(
                      text: "Add 10 More Rows",
                      onClick: () => setState(() { samplesLength = samplesLength + 10; }),
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: samplesLength,
                        itemBuilder: (context, index) {
                          return buildSamples(index + 1);
                        }),
                  ],
                ),
              ]),
        ),
      ),
    );
  }

  buildSamples(index) {
    var i = index.toString();
    var item = samples[i];
    print(item.toString());
    if (item == null) {
      samples[i] = {
        'description': '',
        'material': '',
      };
    }
    if (samples[(index + 1).toString()] == null) {
      samples[(index + 1).toString()] = {
        'description': '',
        'material': '',
      };
    }

    TextEditingController labelController =
    TextEditingController(text: item == null ? '' : item['description']);
    TextEditingController materialController =
    TextEditingController(text: item == null ? '' : item['material']);
    Widget widget = new Row(children: <Widget>[
      new Container(
          width: 30.0,
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(
            right: 14.0,
          ),
//          child: new Text(item["label"], style: Styles.label,),
          child: Text((index).toString())),
      new Container(
        width: 150.0,
        alignment: Alignment.topLeft,
        padding: EdgeInsets.only(
          right: 14.0,
        ),
//          child: new Text(item["label"], style: Styles.label,),
        child: CustomTypeAhead(
          controller: labelController,
          capitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
//          label: 'Item',
          suggestions: items,
          onSaved: (value) => samples[i]["description"] = value.trim(),
          validator: (value) {},
          focusNode: _focusNodes[(index * 2) + 2],
          nextFocus: _focusNodes[(index * 2) + 3],
        ),
      ),
      new Flexible(
        child: CustomTypeAhead(
          controller: materialController,
          capitalization: TextCapitalization.none,
          textInputAction: TextInputAction.next,
//            label: 'Material',
          suggestions: materials,
          onSaved: (value) => samples[i]["material"] = value.trim(),
          validator: (value) {},
          focusNode: _focusNodes[(index * 2) + 3],
          nextFocus: (samples.length - 1 != index &&
              samples[(index + 1).toString()] != null &&
              samples[(index + 1).toString()]["description"].trim().length >
                  0)
              ? _focusNodes[((index + 1) * 2) + 3]
              : _focusNodes[((index + 1) * 2) + 2],
        ),
      )
    ]);
    return widget;
  }

  void applyTemplate(cocObj) {
    this.setState(() {
      cocObj = cocObj;
    });
  }

  void _loadCoc() async {
    if (widget.cocObj['uid'] == null) {
      _title = "Add New Chain of Custody";
      cocObj['deleted'] = false;
      if (widget.cocObj == null) {
        // New room requires us to create a path so it doesn't need internet to get one from Firestore
        print('Making random uid...');
        cocObj['uid'] = 'HISTORIC_' + new Uuid().v1();
      } else {
        cocObj = widget.cocObj;
        print('Making uid out of information...');
        cocObj['uid'] = 'HISTORIC_' + cocObj['client'].toString().toUpperCase() + '-' + Uuid().v1().toString();
      }

      setState(() {
        isLoading = false;
      });
    } else {
//      print('Edit room is ' + room.toString());
      _title = "Edit Chain of Custody";
      Map<String, dynamic> sample_temp = new Map<String, dynamic>();
      Firestore.instance
          .collection('lab').document('asbestos')
          .collection('samples')
          .where('jobNumber', isEqualTo: cocObj['jobNumber'])
          .getDocuments()
          .then((docList) {
        docList.documents.forEach(
                (doc) => sample_temp[doc.data['sampleNumber'].toString()] = doc.data);

        print('Edit coc');
        setState(() {
          samples = sample_temp;

          if (cocObj['dates'] != null) {
            cocObj['dates'].forEach((d) {
              print(d.toString());
              datesSelected.add(d.toDate());
            });
          }
          isLoading = false;
        });
      });
      // image
//      });
    }
//    print(_title.toString());
  }


  void _handleCocSubmit() {
    print(samples.toString());
    var sampleList = new List();
    if (samples != null) {
      samples.forEach((number, sample) {
        //todo Change samples to list of cards that can be clicked on
        if ((sample['cocUid'] == cocObj['uid'] || sample['cocUid'] == null) && ((sample['description'] != null && sample['description'].trim() != '') || (sample['material'] != null && sample['description'].trim() != ''))) {
          if (sample['uid'] == null) {
            var dateString = new DateFormat('dd_MM_yy_HH_mm').format(DateTime.now());
            var uid = 'HISTORIC-SAMPLE-' + number + '-CREATED-' + dateString + Uuid().v1().toString();
            print('UID for new sample is ' + uid);
            sample['uid'] = uid;
          }
          sampleList.add(sample['uid']);
          if (sample['description'] != null && sample['description'].trim() != '') {
            if (sample['description'].trim().length > 1) {
              sample['description'] = sample['description'][0].toUpperCase() + sample['description'].trim().substring(1);
            } else {
              sample['description'] = sample['description'].toUpperCase().trim();
            }
          } else {
            sample['description'] = 'No description';
          }
          sample['cocUid'] = cocObj['uid'];
          sample['jobNumber'] = 'HISTORIC';
          sample['sampleNumber'] = number;
          Firestore.instance
              .collection('lab').document('asbestos')
              .collection('samples')
              .document(sample['uid'])
              .setData(sample);
        }
      });
    }

    cocObj['sampleList'] = sampleList;

    Firestore.instance
        .collection('lab').document('asbestos')
        .collection('cocs')
        .document(cocObj['uid'])
        .setData(cocObj);
  }
}
