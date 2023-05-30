import 'dart:convert';
class rfid {
    rfid({       
       required this.dato,   
       required this.usuario         
    });   
    String dato;  
    String usuario;  
    factory rfid.fromJson(String str) => rfid.fromMap(json.decode(str));
    String toJson() => json.encode(toMap());
    factory rfid.fromMap(Map<String, dynamic> json) => rfid(
        dato: json["dato"],
        usuario: json["usuario"],
    );
    Map<String, dynamic> toMap() => {
        "dato": dato,      
        "usuario": usuario,                  
    };
}