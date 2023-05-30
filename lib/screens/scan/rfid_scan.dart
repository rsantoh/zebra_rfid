import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import '../../models/rfid_reader.dart';
import '../../providers/scanProvider.dart';

class RFIDScreen extends StatefulWidget {
  const RFIDScreen({ Key? key }) : super(key: key);

  @override
  State<RFIDScreen> createState() => _RFIDScreenState();
}
List<rfid> rfidList = [];
class _RFIDScreenState extends State<RFIDScreen> {
 late WebViewController controller;
  String urlHeader = '';
  String username = '';
  String zoom = '60%';
  @override
  Widget build(BuildContext context) {
    return Scaffold(  
       appBar: PreferredSize(

        preferredSize: Size.fromHeight(0),
          child: AppBar(
            elevation: 0,
          ),          
       ),           
       body: Column(
         children: [
          
           Expanded(
             flex: 9,
             child: Container(      
               child: WebView(
                javascriptMode: JavascriptMode.unrestricted,
                 initialUrl: 'http://158.85.8.108/CoronaPrueba/App/',
                onWebViewCreated: (controller) { 
                  this.controller = controller;
                },
                onPageStarted: (url)async{      
                  print(url);             
                  setState(() {
                      urlHeader = url.toString();
                  });
                  // await Future.delayed(Duration(seconds: 1));
                  // controller.runJavascript(
                  // """
                  //  document.body.style.zoom = "60%"
                  // """);

                },
                 navigationDelegate: _interceptNavigation,
                
                //Retunr value from 
                javascriptChannels: <JavascriptChannel>{
                  JavascriptChannel(
                      name: 'messageHandler',
                      onMessageReceived: (JavascriptMessage message) {
                        username = message.message;
                        print(username);
                      },
                  )
                },
                gestureNavigationEnabled: true,
              

                
              ),

             ),
              ),
             Expanded(
               flex: 1,
               child: Container(
                 child: Container(
                  child:   MaterialButton(
                    child: Container(
                      child: Text('web scrapping'),
                    ),
                    onPressed: ()async{
                    controller.runJavascriptReturningResult(
                  """  
                  var span_Text = document.getElementById("lblUsuario").innerText;
                  messageHandler.postMessage(span_Text);  
                  """
                  );
                  await Future.delayed(Duration(seconds: 1));

// EasyLoading.show(status: 'Loading...');

  rfidList = [];
  for (var i = 0; i < 5; i++) {
      rfidList.add(new rfid(dato:'000000000000939999999999', usuario: "Administrator User"));                      
 }

var json = jsonEncode(rfidList);


final rfidprovider = Provider.of<ScanProvider>(context, listen: false);
final resp = await rfidprovider.fetchProducts(rfidList);
print(resp);

   

                    },
                  ),
                  

                 ),
               )
              )
         ],
       ),
       floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_arrow,
        children: [
          SpeedDialChild(
            child: Icon(Icons.zoom_in),
            label: 'Acercar',
            onTap: (){
              if(zoom == "60%"){
                zoom = "80%";
              }
              else if(zoom == "80%"){
                zoom = "100%";
              }
              else if(zoom == "100"){
                 zoom = "60%";
              }
              else {
                zoom = "50%";
              }

              controller.runJavascript(
              """
             document.body.style.zoom = "100%"
              """);
            }
          ),
           SpeedDialChild(
            child: Icon(Icons.zoom_out),
            label: 'Alejar',
             onTap: (){

              controller.runJavascript(
              """
             document.body.style.zoom = "60%"
              """);
            }
          ),
          SpeedDialChild(
            child: Icon(Icons.link),
            label: 'URL',
             onTap: ()async{
                 final url = await controller.currentUrl();
                setState(() {
                  urlHeader = url.toString();
                });              
            }
          ),
           SpeedDialChild(
            child: Icon(Icons.delete),
            label: 'Limpiar Cache',
             onTap: ()async{
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

