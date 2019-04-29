import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/pages/my_jobs/tasks/coc/coc_functions.dart';
import 'package:k2e/pages/my_jobs/tasks/coc/coc_card.dart';
import 'package:k2e/pages/my_jobs/tasks/coc/coc_header.dart';
import 'package:k2e/pages/my_jobs/tasks/coc/edit_coc.dart';
import 'package:k2e/styles.dart';
import 'package:k2e/widgets/buttons.dart';
import 'package:k2e/widgets/common_widgets.dart';

class AssignSampleNumbers extends StatefulWidget {
  AssignSampleNumbers({Key key, this.acm}) : super(key: key);
  final Map<String, dynamic> acm;
  @override
  _AssignSampleNumbersState createState() => new _AssignSampleNumbersState();
}

class _AssignSampleNumbersState extends State<AssignSampleNumbers> {
  String _title = "Assign Sample Numbers";

  Map<String, dynamic> acm = new Map<String, dynamic>();
  // images

  @override
  void initState() {
    acm = widget.acm;
    _loadSampleNumbers();
    super.initState();
  }

  Widget build(BuildContext context) {
    return new Scaffold(
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
                    // Assign
                  })
            ]),
        body: new Container(
          padding: new EdgeInsets.all(8.0),
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              new StreamBuilder(
                  stream: Firestore.instance
                      .collection('lab').document('asbestosbulk').collection('labs').document('k2environmental')
                      .collection('cocs')
                      .where('jobNumber',
                          isEqualTo: DataManager.get().currentJobNumber)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return LoadingPage(loadingText: 'Loading Chains of Custody');
                    if (snapshot.data.documents.length == 0)
                      return EmptyList(text: 'This job has no Chains of Custody.');
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (context, index) {
                          return CocHeader(
                            doc: snapshot.data.documents[index]
                          );
                        });
                  }),
              FunctionButton(
                text: "Add New Chain of Custody",
                onClick: () { addNewCoc(context); },
              ),
              Divider(),
              Container(
                  padding: EdgeInsets.fromLTRB(32.0, 16.0, 32.0, 16.0),
                  child: Text(
                      'Add historic samples if there have been any samples previously tested by K2 Environmental or any other testing lab.',
                      style: Styles.comment)),
              new StreamBuilder(
                  stream: Firestore.instance
                      .document(DataManager.get().currentJobPath)
                      .collection('historicsamples')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Container(
                          padding: EdgeInsets.only(top: 16.0),
                          alignment: Alignment.center,
                          color: Colors.white,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new CircularProgressIndicator(),
                                Container(
                                    alignment: Alignment.center,
                                    height: 64.0,
                                    child: Text('Loading Historic Samples'))
                              ]));
                    if (snapshot.data.documents.length == 0)
                      return EmptyList(text: 'This job has no historic samples.');
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (context, index) {
                          return Text(
                              snapshot.data.documents[index]['jobNumber']);
                        });
                  }),
              FunctionButton(
                text: "Add Historic Chain of Custody",
                onClick: () { addHistoricCoc(context); },
              ),
            ],
          ),
        ));
  }

  void _loadSampleNumbers() {
    Firestore.instance
        .collection('cocs')
        .where('jobNumber', isEqualTo: DataManager.get().currentJobNumber)
        .getDocuments()
        .then((doc) {
      if (doc.documents.length == 0) {
        // No COC
        print('No COC for this job');
      } else {
        // Get samples from CoCs
        doc.documents.forEach((doc) {
          print(doc.data.toString());
        });
      }
    });
  }
}