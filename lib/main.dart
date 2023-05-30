import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'dart:async';

import 'package:provider/provider.dart';

import 'providers/scanProvider.dart';
import 'screens/scan/batteryLevel.dart';
import 'screens/scan/rfid_scan.dart';
import 'screens/scan/scan_screen.dart';


void main() {
  
  
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
WidgetsFlutterBinding.ensureInitialized();
print("Our background job ran!");
}

  var platform = MethodChannel('samples.flutter.dev/battery'); //Se utiliza el mismo en la parte nativa para relacionar flutter con la parte nativa
 
  Future<void> initialize(final Function callbackDispatcher) async {
    final callback = PluginUtilities.getCallbackHandle(callbackDispatcher);
    await platform.invokeMethod('initialize', callback?.toRawHandle());
  }
  runApp(const MyApp());
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
    //..customAnimation = CustomAnimation();
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
       providers: [
        ChangeNotifierProvider(create: (_) => ScanProvider()),    
      ],
       child: MaterialApp(
         title: 'Multibarras', 
         theme: ThemeData.light(),
          debugShowCheckedModeBanner: false,
          initialRoute: 'captura',
          routes: {      
            'rfid': (_) => RFIDScreen(),    
            'captura': (_) => ScanScreen(),    
          },
        builder: EasyLoading.init(),
       )
    );
  }
}



