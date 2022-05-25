import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/style.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:collection/collection.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pseudo Roomba App',
      theme: ThemeData(),
      home: const MyHomePage(title: 'Pseudo Roomba Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ARKitController arkitController;
  vector.Vector3? lastPosition;
  vector.Vector3? secondLastPosition;
  vector.Vector3? firstPosition;
  List<ARKitNode> nodes = [];

  bool undoAllowed = false;
  bool finishAllowed = false;
  bool finishPressed = false;
  int nodeCount = 0;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Measure Sample'),
        ),
        body: Stack(
          children: [
            ARKitSceneView(
              enableTapRecognizer: true,
              onARKitViewCreated: onARKitViewCreated,
            ),
            finishPressed ? Center(child: PlaneBuilder(nodes)) : Container(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                if (nodeCount > 0 && undoAllowed) {
                  if (nodeCount == 1) {
                    arkitController.remove('0');
                    lastPosition = null;
                    firstPosition = null;
                    nodeCount = 0;
                  } else {
                    arkitController.remove((nodeCount - 1).toString());
                    arkitController.remove((nodeCount - 1).toString());
                    lastPosition = secondLastPosition;
                    nodeCount -= 1;
                  }
                  setState(() {
                    undoAllowed = false;
                  });
                }
              },
              child: const Icon(Icons.cancel_outlined),
              backgroundColor: undoAllowed ? Colors.blueGrey : Colors.red,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            FloatingActionButton(
              onPressed: () async {
                if (nodeCount > 2) {
                  final line = ARKitLine(
                    fromVector: lastPosition!,
                    toVector: firstPosition!,
                    materials: [
                      ARKitMaterial(
                        lightingModelName: ARKitLightingModel.constant,
                        diffuse: ARKitMaterialProperty.color(Colors.red),
                      ),
                    ],
                  );
                  final lineNode =
                      ARKitNode(geometry: line, name: nodeCount.toString());
                  arkitController.add(lineNode);
                  setState(() {
                    finishAllowed = false;
                  });
                  setState(() {
                    finishPressed = true;
                  });
                } else {
                  null;
                }
              },
              child: const Icon(Icons.add_task_outlined),
              backgroundColor: finishAllowed ? Colors.blueGrey : Colors.red,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            FloatingActionButton(
              onPressed: () {
                if (nodeCount > 0) {
                  arkitController.remove('0');
                  for (int i = 1; i < nodeCount; i++) {
                    arkitController.remove(i.toString());
                    arkitController.remove(i.toString());
                  }
                  firstPosition = null;
                  lastPosition = null;
                  nodeCount = 0;
                  setState(() {
                    undoAllowed = false;
                  });
                }
              },
              child: const Icon(Icons.refresh),
              backgroundColor: Colors.blueGrey,
            ),
          ],
        ),
      );

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onARTap = (ar) {
      final point = ar.firstWhereOrNull(
        (o) => o.type == ARKitHitTestResultType.featurePoint,
      );
      if (point != null) {
        _onARTapHandler(point);
      }
    };
  }

  void _onARTapHandler(ARKitTestResult point) {
    final position = vector.Vector3(
      point.worldTransform.getColumn(3).x,
      point.worldTransform.getColumn(3).y,
      point.worldTransform.getColumn(3).z,
    );
    if (lastPosition != null) {
      final material = ARKitMaterial(
          lightingModelName: ARKitLightingModel.constant,
          diffuse: ARKitMaterialProperty.color(Colors.blue));
      final sphere = ARKitSphere(
        radius: 0.1,
        materials: [material],
      );
      final node = ARKitNode(
        geometry: sphere,
        position: position,
        name: nodeCount.toString(),
      );
      arkitController.add(node);
      nodes.add(node);

      final line = ARKitLine(
        fromVector: lastPosition!,
        toVector: position,
        materials: [
          ARKitMaterial(
            lightingModelName: ARKitLightingModel.constant,
            diffuse: ARKitMaterialProperty.color(Colors.red),
          ),
        ],
      );
      final lineNode = ARKitNode(geometry: line, name: nodeCount.toString());
      arkitController.add(lineNode);
      final distance = _calculateDistanceBetweenPoints(position, lastPosition!);
      //final point = _getMiddleVector(position, lastPosition!);
      //_drawText(distance, point);
      secondLastPosition = lastPosition;
      lastPosition = position;
      nodeCount += 1;
      setState(() {
        undoAllowed = true;
      });
    } else {
      final material = ARKitMaterial(
          lightingModelName: ARKitLightingModel.constant,
          diffuse: ARKitMaterialProperty.color(Colors.blue));
      final sphere = ARKitSphere(
        radius: 0.1,
        materials: [material],
      );
      final node = ARKitNode(
        geometry: sphere,
        position: position,
        name: nodeCount.toString(),
      );
      arkitController.add(node);
      nodes.add(node);
      firstPosition = position;
      lastPosition = position;
      nodeCount += 1;
      setState(() {
        undoAllowed = true;
      });
    }
    if (nodeCount > 2) {
      finishAllowed = true;
    }
  }

  String _calculateDistanceBetweenPoints(vector.Vector3 A, vector.Vector3 B) {
    final length = A.distanceTo(B);
    return '${(length * 100).toStringAsFixed(2)} cm';
  }

  vector.Vector3 _getMiddleVector(vector.Vector3 A, vector.Vector3 B) {
    return vector.Vector3((A.x + B.x) / 2, (A.y + B.y) / 2, (A.z + B.z) / 2);
  }

  void _drawText(String text, vector.Vector3 point) {
    final textGeometry = ARKitText(
      text: text,
      extrusionDepth: 1,
      materials: [
        ARKitMaterial(
          diffuse: ARKitMaterialProperty.color(Colors.red),
        )
      ],
    );
    const scale = 0.01;
    final vectorScale = vector.Vector3(scale, scale, scale);
    final node = ARKitNode(
      geometry: textGeometry,
      position: point,
      scale: vectorScale,
      name: nodeCount.toString(),
    );
    arkitController.add(node);
  }

  Widget PlaneBuilder(List<ARKitNode> planes) {
    return Stack(
      children: const [
        CircularProgressIndicator(),
      ],
    );
  }
}
