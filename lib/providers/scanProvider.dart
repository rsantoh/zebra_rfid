import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rfid_zebra/models/rfid_reader.dart';
import 'package:http/http.dart' as http;
//ChangeNotifier va permitinos que la clase sea puesta en un multiprovider o un checkprovider
class ScanProvider extends ChangeNotifier{

 
  String resp = '';

   Future<String> SaveRFID(List<rfid> json) async {         
      await Future.delayed(Duration(seconds: 1));
      for (var i = 0; i < json.length; i++) {
        resp = json[i].dato + ' - ' + json[i].usuario;
      }
      // var jsondecode = jsonDecode(json);
      // for (var i = 0; i < jsondecode.length; i++) {
      //   resp = jsondecode[i]['dato'];
      // }  
    try {
      
    } catch (e) {
      
    }
    return resp;
  }

  Future<String> fetchProducts(List<rfid> JsonRe) async {
    String respuestaOut = 'XX';
   
    try {
      for (var i = 0; i < JsonRe.length; i++) {
        // respuestaOut = JsonRe[i].dato + ' - ' + JsonRe[i].usuario;

        var headers = {
          'Content-Type': 'application/json'
        };
        //http://158.85.8.108/coronaprueba/service/api/SetGuardarDatosRFID
        var request = http.Request('POST', Uri.parse('http://10.127.16.122/corona/service/api/SetGuardarDatosRFID')); //Produccion
        //var request = http.Request('POST', Uri.parse('http://158.85.8.108/coronaprueba/service/api/SetGuardarDatosRFID')); // Pruebas
        request.body = json.encode({
          "usuario": JsonRe[i].usuario,
          "dato": JsonRe[i].dato
        });
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send().timeout(
           const Duration(seconds: 15)     
         );
       
        if (response.statusCode == 200) {
          final resp = await response.stream.bytesToString();
          final respuesta = jsonDecode(resp);
          final resp2 = respuesta['table'];  
          String respAPI =  resp2[0]['respuesta'];
          print(resp2[0]['respuesta']);
          if(respAPI == ''){
              String respuestaOut = 'XX';
          }
          else{
             respuestaOut = resp2[0]['respuesta'].toString() + " - dato: " +  resp2[0]['dato'].toString();
          }
         
          break;
        }
        else {
          respuestaOut = response.reasonPhrase.toString();
         
          break;
        }


        
    }
    } catch (e) {
      respuestaOut = 'Ha ocurrido un error' + e.toString();
    }
    return respuestaOut;
  }

}