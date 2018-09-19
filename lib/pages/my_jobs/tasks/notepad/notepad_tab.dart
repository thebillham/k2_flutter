import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/pages/my_jobs/tasks/notepad/edit_note.dart';
import 'package:k2e/widgets/note_card.dart';

// The base page for any type of job. Shows address, has cover photo,

class NotepadTab extends StatefulWidget {
  NotepadTab() : super();
  @override
  _NotepadTabState createState() => new _NotepadTabState();
}

class _NotepadTabState extends State<NotepadTab> {
  String _loadingText = 'Loading notes...';

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    return new Scaffold(
        body: new Container(
            alignment: Alignment.center,
            padding: new EdgeInsets.all(8.0),
            child: StreamBuilder(
                stream: Firestore.instance.document(DataManager.get().currentJobPath).collection('notes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return
                    Container(
                        padding: EdgeInsets.only(top: 16.0),
                        alignment: Alignment.center,
                        color: Colors.white,

                        child: Column(
                            mainAxisAlignment: MainAxisAlignment
                                .center,
                            children: <Widget>[
                              new CircularProgressIndicator(),
                              Container(
                                  alignment: Alignment.center,
                                  height: 64.0,
                                  child:
                                  Text(_loadingText)
                              )
                            ]));
                  if (snapshot.data.documents.length == 0) return
                    Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.not_interested, size: 64.0),
                              Container(
                                  alignment: Alignment.center,
                                  height: 64.0,
                                  child:
                                  Text('This job has no notes.')
                              )
                            ]
                        )
                    );
                  return ListView.builder(
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, index) {
                        print(snapshot.data.documents[index]['jobnumber']);
                        return NoteCard(
                          note: snapshot.data.documents[index],
                          onCardClick: () async {
                            Navigator.of(context).push(
                              new MaterialPageRoute(builder: (context) =>
                                  EditNote(
                                      note: snapshot.data.documents[index]
                                          .documentID)),
                            );
                          },
//                          onCardLongPress: () {
//                            // Delete
//                            // Bulk add /clone etc.
//                          },
                        );
                      }
                  );
                }
            ),
          ),
    );
  }
}