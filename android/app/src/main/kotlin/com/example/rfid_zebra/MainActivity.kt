package com.example.rfid_zebra

import android.content.*
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.Bundle
import android.os.Parcelable
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*


class MainActivity: FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"

    private val COMMANDCHANNEL = "sample.servibarras/command"
    private val SCANCHANNEL = "com.darryncampbell.datawedgeflutter/scan"
    private val PROFILEINTENTACTION = "com.zebra.rfid.servibarras"
    private val PROFILEINTENTBROADCAST = "2"
    private val dwInterface = DWInterface()



    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor, SCANCHANNEL).setStreamHandler(
            object : StreamHandler {
                private var dataWedgeBroadcastReceiver: BroadcastReceiver? = null
                override fun onListen(arguments: Any?, events: EventSink?) {
                    dataWedgeBroadcastReceiver = createDataWedgeBroadcastReceiver(events)
                    val intentFilter = IntentFilter()
                    intentFilter.addAction(PROFILEINTENTACTION)
                    intentFilter.addAction(DWInterface.DATAWEDGE_RETURN_ACTION)
                    intentFilter.addCategory(DWInterface.DATAWEDGE_RETURN_CATEGORY)
                    registerReceiver(
                        dataWedgeBroadcastReceiver, intentFilter)
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(dataWedgeBroadcastReceiver)
                    dataWedgeBroadcastReceiver = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            // This method is invoked on the main thread.
                call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()

                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor, COMMANDCHANNEL).setMethodCallHandler {
            // This method is invoked on the main thread.
                call, result ->
            if (call.method == "sendDataWedgeCommandStringParameter")
            {
                val arguments = JSONObject(call.arguments.toString())
                val command: String = arguments.get("command") as String
                val parameter: String = arguments.get("parameter") as String
                dwInterface.sendCommandString(applicationContext, command, parameter)
                //  result.success(0);  //  DataWedge does not return responses
            }
            else if (call.method == "createDWProfile")
            {
                createDataWedgeProfile2("a")
                //result.success("al fin")
            }
            else {
                result.notImplemented()
            }
        }

    }

    private fun createDataWedgeBroadcastReceiver(events: EventSink?): BroadcastReceiver? {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action.equals(PROFILEINTENTACTION))
                {
                    //  A barcode has been scanned
                    var scanData = intent.getStringExtra(DWInterface.DATASTRINGTAG)
                    var symbology = intent.getStringExtra(DWInterface.DATAWEDGE_SCAN_EXTRA_LABEL_TYPE)
                    var date = Calendar.getInstance().time
                    var df = SimpleDateFormat("dd/MM/yyyy HH:mm:ss")
                    var dateTimeString = df.format(date)
                    var currentScan = scanData?.let { symbology?.let { it1 ->
                        Scan(it,
                            it1, dateTimeString)
                    } };
                    if (currentScan != null) {
                        events?.success(currentScan.toJson())
                    }
                }
                //  Could handle return values from DW here such as RETURN_GET_ACTIVE_PROFILE
                //  or RETURN_ENUMERATE_SCANNERS
            }
        }
    }

    private fun createDataWedgeProfile2(toString: String) {

        var profileName = "servibarras01";
        dwInterface.sendCommandString(this, DWInterface.DATAWEDGE_SEND_CREATE_PROFILE, profileName)
        val profileConfig = Bundle()
        profileConfig.putString("PROFILE_NAME", profileName)
        profileConfig.putString("PROFILE_ENABLED", "true") //  These are all strings
        profileConfig.putString("CONFIG_MODE", "UPDATE")
        //se habilita el RFID en el profile
        val rfidConfigParamList = Bundle()
        rfidConfigParamList.putString("rfid_input_enabled", "true")
        rfidConfigParamList.putString("rfid_beeper_enable", "true")
        rfidConfigParamList.putString("rfid_led_enable", "true")
        rfidConfigParamList.putString("rfid_antenna_transmit_power", "30")
        rfidConfigParamList.putString("rfid_memory_bank", "2")
        rfidConfigParamList.putString("rfid_session", "1")
        rfidConfigParamList.putString("rfid_trigger_mode", "1")
        rfidConfigParamList.putString("rfid_filter_duplicate_tags", "true")
        rfidConfigParamList.putString("rfid_hardware_trigger_enabled", "true")
        rfidConfigParamList.putString("rfid_tag_read_duration", "250")
        val rfidConfigBundle = Bundle()
        rfidConfigBundle.putString("PLUGIN_NAME", "RFID")
        rfidConfigBundle.putString("RESET_CONFIG", "true")
        rfidConfigBundle.putBundle("PARAM_LIST", rfidConfigBundle)
        profileConfig.putBundle("PLUGIN_CONFIG", rfidConfigParamList)

        val appConfig = Bundle()
        appConfig.putString("PACKAGE_NAME", packageName)      //  Associate the profile with this app
        appConfig.putStringArray("ACTIVITY_LIST", arrayOf("*"))
        profileConfig.putParcelableArray("APP_LIST", arrayOf(appConfig))
        dwInterface.sendCommandBundle(this, DWInterface.DATAWEDGE_SEND_SET_CONFIG, profileConfig)
        //  You can only configure one plugin at a time in some versions of DW, now do the intent output
        profileConfig.remove("PLUGIN_CONFIG")
        val intentConfig = Bundle()
        intentConfig.putString("PLUGIN_NAME", "INTENT")
        intentConfig.putString("RESET_CONFIG", "true")
        val intentProps = Bundle()
        intentProps.putString("intent_output_enabled", "true")
        intentProps.putString("intent_action", PROFILEINTENTACTION)
        intentProps.putString("intent_delivery", PROFILEINTENTBROADCAST)
        intentProps.putString("intent_category", "android.intent.category.DEFAULT");//  "2"
        intentConfig.putBundle("PARAM_LIST", intentProps)
        profileConfig.putBundle("PLUGIN_CONFIG", intentConfig)
        dwInterface.sendCommandBundle(this, DWInterface.DATAWEDGE_SEND_SET_CONFIG, profileConfig)

    }


    private fun createDataWedgeProfile(toString: String) {

        var profileName = "servibarras01";
        dwInterface.sendCommandString(this, DWInterface.DATAWEDGE_SEND_CREATE_PROFILE, profileName)
        val profileConfig = Bundle()
        profileConfig.putString("PROFILE_NAME", profileName)
        profileConfig.putString("PROFILE_ENABLED", "true") //  These are all strings
        profileConfig.putString("CONFIG_MODE", "UPDATE")
        val rfidConfigParamList = Bundle()
        rfidConfigParamList.putString("rfid_input_enabled", "true")
        rfidConfigParamList.putString("rfid_beeper_enable", "true")
        rfidConfigParamList.putString("rfid_led_enable", "true")
        rfidConfigParamList.putString("rfid_antenna_transmit_power", "30")
        rfidConfigParamList.putString("rfid_memory_bank", "2")
        rfidConfigParamList.putString("rfid_session", "1")
        rfidConfigParamList.putString("rfid_trigger_mode", "1")
        rfidConfigParamList.putString("rfid_filter_duplicate_tags", "true")
        rfidConfigParamList.putString("rfid_hardware_trigger_enabled", "true")
        rfidConfigParamList.putString("rfid_tag_read_duration", "250")
        val rfidConfigBundle = Bundle()
        rfidConfigBundle.putString("PLUGIN_NAME", "RFID")
        rfidConfigBundle.putString("RESET_CONFIG", "true")
        rfidConfigBundle.putBundle("PARAM_LIST", rfidConfigParamList)
        profileConfig.putBundle("PLUGIN_CONFIG", rfidConfigParamList)
        val appConfig = Bundle()
        appConfig.putString("PACKAGE_NAME", packageName)      //  Associate the profile with this app
        appConfig.putStringArray("ACTIVITY_LIST", arrayOf("*"))
        profileConfig.putParcelableArray("APP_LIST", arrayOf(appConfig))
        dwInterface.sendCommandBundle(this, DWInterface.DATAWEDGE_SEND_SET_CONFIG, profileConfig)
        //  You can only configure one plugin at a time in some versions of DW, now do the intent output
        profileConfig.remove("PLUGIN_CONFIG")
        val intentConfig = Bundle()
        intentConfig.putString("PLUGIN_NAME", "INTENT")
        intentConfig.putString("RESET_CONFIG", "true")
        val intentProps = Bundle()
        intentProps.putString("intent_output_enabled", "true")
        intentProps.putString("intent_action", PROFILEINTENTACTION)
        intentProps.putString("intent_delivery", PROFILEINTENTBROADCAST)  //  "2"
        intentConfig.putBundle("PARAM_LIST", intentProps)
        profileConfig.putBundle("PLUGIN_CONFIG", intentConfig)
        dwInterface.sendCommandBundle(this, DWInterface.DATAWEDGE_SEND_SET_CONFIG, profileConfig)

    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
        return batteryLevel
    }




}
