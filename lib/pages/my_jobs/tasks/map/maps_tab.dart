import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/pages/my_jobs/tasks/map/edit_map.dart';
import 'package:k2e/pages/my_jobs/tasks/map/map_card.dart';
import 'package:k2e/styles.dart';
import 'package:k2e/widgets/common_widgets.dart';

// The base page for any type of job. Shows address, has cover photo,

class MapsTab extends StatefulWidget {
  MapsTab() : super();
  @override
  _MapsTabState createState() => new _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  String _loadingText = 'Loading maps...';

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    return new Scaffold(
      body: new Container(
        padding: new EdgeInsets.all(8.0),
        child: new ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(14.0),
              child: Text('Maps', style: Styles.h1),
            ),
            new StreamBuilder(
                stream: Firestore.instance
                    .document(DataManager.get().currentJobPath)
                    .collection('maps')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    LoadingPage(loadingText: _loadingText);
                  if (snapshot.data.documents.length == 0)
                    return EmptyList(
                      text: 'This job has no maps.'
                    );
                  return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, index) {
                        print(snapshot.data.documents[index]['jobNumber']);
                        return MapCard(
                          map: snapshot.data.documents[index],
                          onCardClick: () async {
                            Navigator.of(context).push(
                              new MaterialPageRoute(
                                  builder: (context) => EditMap(
                                      map: snapshot
                                          .data.documents[index].documentID)),
                            );
                          },
//                          onCardLongPress: () {
//                            // Delete
//                            // Bulk add /clone etc.
//                          },
                        );
                      });
                }),
          ],
        ),
      ),
    );
  }
}
