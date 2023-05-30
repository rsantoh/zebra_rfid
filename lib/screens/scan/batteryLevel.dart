import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class BatteryLevelScreen extends StatefulWidget {
  const BatteryLevelScreen({ Key? key }) : super(key: key);

  @override
  _BatteryLevelScreenState createState() => _BatteryLevelScreenState();
}

class _BatteryLevelScreenState extends State<BatteryLevelScreen> {
  var platform = MethodChannel('samples.flutter.dev/battery');   
  String hitext = '';
  @override
  Widget build(BuildContext context) {
     //Se utiliza el mismo en la parte nativa para relacionar flutter con la parte nativa

    return Scaffold(
       appBar: AppBar(
        title: Text("Servibarras"),
      ),
       body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(onPressed: (){
            _hi();
            
          }, child: Text('Get Battery Level')),
          Center(
            child: Text(hitext),
          )

        ],
      ),
      
    );
  }

    //esto es un isolate, crea un hilo a parte que funciona con su propio nucleo
   Future<void> _hi()async{
    //Saluda al sistema operativo, se utiliza el methodChannel creado anteriormente e invoca un metodo
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e)  {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }
    print(batteryLevel);

    setState(() {
      hitext = batteryLevel;
    });

  }
}