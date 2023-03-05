import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewFirebaseEvent extends StatefulWidget {
  const ViewFirebaseEvent(
      {super.key,
      required this.trip,
      required this.tripevent,
      required this.onTap});

  final trip;
  final tripevent;
  final VoidCallback onTap;

  @override
  State<ViewFirebaseEvent> createState() => _ViewFirebaseEventState();
}

class _ViewFirebaseEventState extends State<ViewFirebaseEvent> {
  late List dateTimeList = widget.tripevent["dateTime"].split('T');
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.onTap();
        },
        child: Container(
            height: 175,
            width: MediaQuery.of(context).size.height,
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Row(children: <Widget>[
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text(
                        'Name: ${widget.tripevent["eventName"]}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text(
                        'At ' + '${time}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: Text(
                        'Location: ' +
                            '${widget.tripevent["eventFullAddress"]}',
                        style: TextStyle(
                            //fontSize: 20,
                            //letterSpacing: .5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ])));
  }
}
