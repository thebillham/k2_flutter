import 'package:flutter/material.dart';
import 'package:k2e/model/jobs/job_header.dart';
import 'package:k2e/styles.dart';
import 'package:k2e/theme.dart';

class JobCard extends StatefulWidget {

  JobCard({
    this.jobHeader,
    @required this.onCardClick,
    @required this.onCardLongPress,
  });

  final JobHeader jobHeader;

  final VoidCallback onCardClick;
  final VoidCallback onCardLongPress;

  @override
  _JobCardState createState() => new _JobCardState();

}

class _JobCardState extends State<JobCard>{
  Icon icon;
  @override
  Widget build(BuildContext context) {
    if (widget.jobHeader.type.toLowerCase().contains("asbestos")){
      icon = CompanyColors.asbestosIcon;
    } else if (widget.jobHeader.type.toLowerCase().contains("meth")){
      icon = CompanyColors.methIcon;
    } else if (widget.jobHeader.type.toLowerCase().contains("noise")){
      icon = CompanyColors.noiseIcon;
    } else if (widget.jobHeader.type.toLowerCase().contains("stack")){
      icon = CompanyColors.stackIcon;
    } else if (widget.jobHeader.type.toLowerCase().contains("bio")){
      icon = CompanyColors.bioIcon;
    } else {
      icon = CompanyColors.generalIcon;
    }
    return new ListTile(
      leading: icon,
      title: Row(children: <Widget> [
        Text(widget.jobHeader.jobNumber + ': ', style: Styles.h2,),
        Flexible(
            child: Text(' ' + widget.jobHeader.clientName, overflow: TextOverflow.ellipsis,))]),
      subtitle: Text(widget.jobHeader.address),
      // Tap -> go through to job task
      onTap: widget.onCardClick,
      // Long tap -> add options to sync or delete
      onLongPress: widget.onCardLongPress,
    );
  }
}