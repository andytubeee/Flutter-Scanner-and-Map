import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.max,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner'),
        backgroundColor: Colors.green,
      ),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(left: 35),
        child: Row(
          children: [
            FloatingActionButton(
              child: Icon(Icons.camera_alt),
              // Provide an onPressed callback.
              onPressed: () async {
                // Take the Picture in a try / catch block. If anything goes wrong,
                // catch the error.
                try {
                  // Ensure that the camera is initialized.
                  await _initializeControllerFuture;

                  // Construct the path where the image should be saved using the
                  // pattern package.
                  final path = join(
                    // Store the picture in the temp directory.
                    // Find the temp directory using the `path_provider` plugin.
                    (await getTemporaryDirectory()).path,
                    '${DateTime.now()}.png',
                  );

                  // Attempt to take a picture and log where it's been saved.
                  await _controller.takePicture(path);

                  // If the picture was taken, display it on a new screen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DisplayPictureScreen(imagePaths: path),
                    ),
                  );
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                }
              },
            ),
            SizedBox(
              width: 210,
            ),
            RaisedButton(
              color: Colors.green,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Gmap(),
                  ),
                );
              },
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.map,
                    color: Colors.greenAccent,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text("Map")
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Gmap extends StatefulWidget {
  @override
  _GmapState createState() => _GmapState();
}

class _GmapState extends State<Gmap> {
  Completer<GoogleMapController> _controller = Completer();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          actions: <Widget>[Container(
            margin: EdgeInsets.only(right: 338),
            child: IconButton(icon: Icon(Icons.arrow_back), onPressed: () {
              Navigator.pop(context);
            },),
          )],
        ),
        body: Stack(
          children: <Widget>[
            _googleMap(context),
            // new Container(
            //   margin: EdgeInsets.only(top: 655, left: 10),
            //     child: new FloatingActionButton.extended(
            //   onPressed: () {
            //   },
            //   label: Text("Back"),
            //   icon: Icon(Icons.arrow_left),
            //   backgroundColor: Colors.green,
            // ))
          ],
        ),
      ),
    );
  }

  Widget _googleMap(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition:
            CameraPosition(target: LatLng(43.4643, -80.5204), zoom: 10),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: {homeMarker, plasticGarbage1, pescatarian},
      ),
    );
  }

  Marker homeMarker = Marker(
      markerId: MarkerId("home"),
      position: LatLng(43.4643, -80.5204),
      infoWindow: InfoWindow(title: "Vegan"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
  Marker plasticGarbage1 = Marker(
      markerId: MarkerId("plasticGarbage1"),
      position: LatLng(43.4722286, -80.5908138),
      infoWindow: InfoWindow(title: "Vegetarian"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan));
  Marker pescatarian = Marker(
      markerId: MarkerId("plasticGarbage1"),
      position: LatLng(43.453180, -80.549796),
      infoWindow: InfoWindow(title: "Pescatarian"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatefulWidget {
  final String imagePaths;

  const DisplayPictureScreen({Key key, this.imagePaths}) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  List _outputs;
  bool _loading = false;
  var outputTypeText;

  @override
  void initState() {
    super.initState();
    _loading = true;

    WidgetsBinding.instance.addPostFrameCallback((_) => pickImage());

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detecting...'),
        backgroundColor: Colors.green,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Container(
        color: Colors.greenAccent,
        child: Column(
          children: <Widget>[
            Image.file(
              File(widget.imagePaths),
              height: 650,
              width: MediaQuery.of(context).size.width,
            ),
            SizedBox(
              height: 9,
            ),
            _outputs != null
                ? Text(
                    //"${_outputs[0]["label"].toString().substring(2)}",
                    outputTypeText +
                        " \nAccuracy: " +
                        (double.parse(_outputs[0]["confidence"].toString()) *
                                100)
                            .toString() +
                        "%",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                    textAlign: TextAlign.center,
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  pickImage() async {
    var image = File(widget.imagePaths);
    if (image == null) return null;
    setState(() {
      _loading = true;
    });
    classifyImage(image);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
      outputTypeText =
          _outputs[0]["label"].toString().substring(2).toString().trim();

      switch (outputTypeText) {
        case "Vegetable-Fruits":
          {
            outputTypeText = "Vegan / Vegetarian / Pescatarian";
          }
          break;
        case "Dairy":
          outputTypeText = "Vegetarian / Pescatarian";
          break;
        case "Egg":
          outputTypeText = "Vegetarian / Pescatarian";
          break;
        case "Seafood":
          outputTypeText = "Pescatarian";
          break;
        default:
          {
            outputTypeText = "Others";
          }
          break;
      }
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
