import 'package:flutter/material.dart';

void main() {
  runApp(LandingPage());
}

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: Container(
          child: new Center(child: Text("AI Vegan Camera Scanner"),)
        ),
        floatingActionButton: FloatingActionButton(onPressed: null, child: Icon(Icons.camera),),
      ),      
    );
  }
}
