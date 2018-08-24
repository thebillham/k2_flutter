import 'package:flutter/material.dart';
import 'package:k2e/data/datamanager.dart';
import 'package:k2e/model/jobs/job.dart';
import 'package:k2e/styles.dart';

// The base page for any type of job. Shows address, has cover photo,

class RoomsTab extends StatefulWidget {
  RoomsTab() : super();
  @override
  _RoomsTabState createState() => new _RoomsTabState();
}

class _RoomsTabState extends State<RoomsTab> {

  final Job job = DataManager.get().currentJob;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    return new Scaffold(
        body:
        new Container(
            padding: new EdgeInsets.all(24.0),
            alignment: Alignment.center,
            child: Column(
                children: <Widget> [
                  Text('Rooms', style: Styles.h1,),
                  Text('Get all your rooms in order!.',
                      style: Styles.comment),
                ]
            )
        )
    );
  }
}