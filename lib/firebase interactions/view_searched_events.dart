import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewFirebaseEventDetails extends StatefulWidget {
  const ViewFirebaseEventDetails({
    super.key,
    required this.trip,
    required this.tripevent,
  });

  final trip;
  final tripevent;

  @override
  State<ViewFirebaseEventDetails> createState() =>
      _ViewFirebaseEventDetailsState();
}

class _ViewFirebaseEventDetailsState extends State<ViewFirebaseEventDetails> {
  late List dateTimeList = widget.tripevent["dateTime"].split('T');
  late var _time = DateFormat.Hm().parse(dateTimeList[1].substring(0, 5));
  late var time = DateFormat.jm().format(_time);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '${widget.tripevent["eventName"]}',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
      backgroundColor: Colors.blue,
      body: Center(
        child: Container(
          height: 700,
          width: 300,
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: Text(
                  'Name: ${widget.tripevent["eventName"]}',
                  style: TextStyle(
                    fontSize: 20,
                    letterSpacing: .5,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Time ' + '${time}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Location: ${widget.tripevent["eventFullAddress"]}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  'Description: ${widget.tripevent["eventDescription"]}',
                  style: TextStyle(
                      //fontSize: 20,
                      //letterSpacing: .5,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
