import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:trip_reminder/main.dart';

Widget failedAlertBuilder(
    BuildContext context, String message, String response1, String response2) {
  return AlertDialog(
    title: Text(message),
    actions: <Widget>[
      TextButton(
        child: Text(response1),
        onPressed: () async {
          setState() {}
        },
      ),
      TextButton(
        child: const Text('Return Home'),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Home(),
              ));
        },
      ),
    ],
  );
}
