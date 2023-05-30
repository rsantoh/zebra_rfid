// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import '../../models/rfid_reader.dart';
import '../../providers/scanProvider.dart';


class ScanScreen extends StatefulWidget {
  const ScanScreen({ Key? key }) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

List<rfid> rfidList = [];


class _ScanScreenState extends State<ScanScreen> {
 late WebViewController controller;
var platform = MethodChannel('samples.flutter.dev/battery'); 
    var methodChannel  = MethodChannel('sample.servibarras/command');
  static const EventChannel scanChannel =
      EventChannel('com.darryncampbell.datawedgeflutter/scan');

  //  This example implementation is based on the sample implementation at
  //  https://github.com/flutter/flutter/blob/master/examples/platform_channel/lib/main.dart
  //  That sample implementation also includes how to return data from the method
  Future<void> _sendDataWedgeCommand(String command, String parameter) async {
    try {
      String argumentAsJson =
          jsonEncode({"command": command, "parameter": parameter});

      await methodChannel.invokeMethod(
          'sendDataWedgeCommandStringParameter', argumentAsJson);
    } on PlatformException {
      //  Error invoking Android method
    }
  }

 Future<void> _createProfile(String profileName) async {
    try {
        await methodChannel.invokeMethod('createDWProfile', profileName);
        
      //  final int result = await platform.invokeMethod('getBatteryLevel');
      //  print(result);
    } on PlatformException {
      //  Error invoking Android method
    }
  }
    String urlHeader = '';
 String username = '';
  String _rfidString = "rfid will be shown here";
  String _rfidSymbology = "Symbology will be shown here";
  String _scanTime = "Scan Time will be shown here";
String zoom = '60%';
  @override
  void initState() {
    super.initState();
    scanChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    _createProfile("servibarras01");
  }

  void _onEvent(event) async {
    EasyLoading.show(status: 'Guardando...');
    
    rfidList = [];
    if(username == ''){
      controller.runJavascriptReturningResult(
      """  
      let span_Text = document.getElementById("lblUsuario").innerText;
      messageHandler.postMessage(span_Text);  
      """
      );
      await Future.delayed(Duration(seconds: 2));
    }
    
      Map valueScan = jsonDecode(event);    

       setState(() {
          print(rfidList);
            _rfidString = "red: " + valueScan['scanData'];
          _rfidString =  valueScan['scanData'];
            _rfidSymbology = "CONSECUTIVO LEIDO : " + rfidList.length.toString();     
        });

      if(valueScan['scanData'] != '' || valueScan['scanData'] != '\n'){
        var splitted = valueScan['scanData'].split('\n');
        for (var i = 0; i < splitted.length; i++) {
          if(splitted[i]!=""){
             rfidList.add(new rfid(dato:splitted[i], usuario: username ));   
          }                         
        }   

        final rfidprovider = Provider.of<ScanProvider>(context, listen: false);
       final resp = await rfidprovider.fetchProducts(rfidList);
        String respuesta = resp.toString();
        if(resp == 'XX'){
            EasyLoading.dismiss();
            await Future.delayed(Duration(seconds: 2));
            //TODO: Agregar delayed antes de click de 3s
            controller.runJavascript(
              """
              document.getElementById("btnCapturar").click();
              """);

          }
          else{
            EasyLoading.dismiss();
            controller.runJavascript(
              """
              alert("$respuesta");
              """);            
          }

        
      }    

   
  }

  void _onError(Object error) {
    setState(() {
      _rfidString = "Barcode: error";
      _rfidSymbology = ": error";
      _scanTime = "At: error";
    });
  }

  void startScan() {
    setState(() {
      _sendDataWedgeCommand(
          "com.symbol.datawedge.api.SOFT_SCAN_TRIGGER", "START_SCANNING");
    });
  }

  void stopScan() {
    setState(() {
      _sendDataWedgeCommand(
          "com.symbol.datawedge.api.SOFT_SCAN_TRIGGER", "STOP_SCANNING");
    });
  }
  
  @override
  Widget build(BuildContext context) {
    String json = jsonEncode(rfidList);
    
    // ignore: unnecessary_new
    return new Scaffold(
     appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
          child: AppBar(
            elevation: 0,
          ),          
       ), 
      body: Column(
        children :[          
          Expanded(   
            // flex: 9,         
            child: Container(
               child: WebView(
                navigationDelegate: _interceptNavigation,
                javascriptMode: JavascriptMode.unrestricted,
                 initialUrl: 'http://10.127.16.122/Corona/App/',//--PRODUCCION
                  //  initialUrl: 'http://158.85.8.108/Corona/App/',//Pruebas
                onWebViewCreated: (controller) {
                  this.controller = controller;
                },
                onPageStarted: (url) {
                  print('website was open $url');
                  urlHeader = url;
                  setState(() {
                      urlHeader = url.toString();
                  });
                },
                 javascriptChannels: <JavascriptChannel>{
                  JavascriptChannel(
                      name: 'messageHandler',
                      onMessageReceived: (JavascriptMessage message) {
                        username = message.message;
                        print(username);
                      },
                  )
                },
              ),
            ),
          ) , 
          // Expanded(flex:1,child: Container(
          //  padding: EdgeInsets.only(right: 70),
          //   child: Center(child: Text(
          //  json
          // ),),))
          
        ] 
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_arrow,
        children: [
          SpeedDialChild(
            child: Icon(Icons.zoom_in),
            label: 'Acercar',
            onTap: (){
              print(zoom);
              String acjs = '''document.body.style.zoom = "50%";''';
              
              if(zoom == "60%"){
                zoom = "70%";
                acjs = '''document.body.style.zoom = "70%";''';
              }
              else if(zoom == "70%"){
                zoom = "90%";
                acjs = '''document.body.style.zoom = "90%";''';
              }
              else if(zoom == "90%"){
                zoom = "100%";
                 acjs = '''document.body.style.zoom = "100%";''';
              } 
              else if(zoom == "100%"){
                zoom = "100%";
                 acjs = '''document.body.style.zoom = "100%";''';
              }               

              controller.runJavascript(acjs);
            }
          ),
           SpeedDialChild(
            child: Icon(Icons.zoom_out),
            label: 'Alejar',
             onTap: (){
               print(zoom);
              String acjs = '''document.body.style.zoom = "60%";''';
              if(zoom == "100%"){
                zoom = "90%";
                acjs = '''document.body.style.zoom = "90%";''';
              }
              else if(zoom == "90%"){
                zoom = "70%";
                acjs = '''document.body.style.zoom = "70%";''';
              }
              else if(zoom == "70%"){
                zoom = "60%";
                 acjs = '''document.body.style.zoom = "60%";''';
              } 
              else if(zoom == "60%"){
                zoom = "60%";
                 acjs = '''document.body.style.zoom = "60%";''';
              }               
              controller.runJavascript(acjs);
            }
          ),
          // SpeedDialChild(
          //   child: Icon(Icons.link),
          //   label: 'URL',
          //    onTap: ()async{
          //        final url = await controller.currentUrl();
          //       setState(() {
          //         urlHeader = url.toString();
          //       });              
          //   }
          // ),
           SpeedDialChild(
            child: Icon(Icons.delete),
            label: 'Limpiar Cache',
             onTap: ()async{
              rfidList = [];
              username = '';
                controller.clearCache();         
            }
          ),
        ],
       ) 
      
      
    );

    
  }

  NavigationDecision _interceptNavigation(NavigationRequest request) {      
     setState(() {
       urlHeader = request.url.toString();  
     });
   return NavigationDecision.navigate;
  }


}

