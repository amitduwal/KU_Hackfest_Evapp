import Flutter
import UIKit
import EsewaSDK

public class SwiftEsewaFlutterSdkPlugin: NSObject, FlutterPlugin, EsewaSDKPaymentDelegate {
   
    var result: FlutterResult?
    var sdk: EsewaSDK?
    static var channel : FlutterMethodChannel?
    static let METHOD_CHANNEL_NAME = "flutter_sdk_channel"
    let PAYMENT_METHOD_SUCCESS = "payment_success"
    let PAYMENT_METHOD_FAILURE = "payment_failure"
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: METHOD_CHANNEL_NAME, binaryMessenger: registrar.messenger())
    let instance = SwiftEsewaFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
       case "initPayment":
        initPayment(args: call.arguments)
        break
       default:
           result(FlutterMethodNotImplemented)
         break
       }
  }
    
    func initPayment(args: Any?) {
        
        let controller = UIApplication.shared.keyWindow!.rootViewController as! FlutterViewController

        let argsMap = args as! NSDictionary
        let config = argsMap.value(forKey: "config") as! NSDictionary
        let clientId = config.value(forKey: "client_id") as! String
        let secretKey = config.value(forKey: "client_secret") as! String
        let env = (config.value(forKey: "environment") as! String) == "live" ? EsewaSDKEnvironment.production : EsewaSDKEnvironment.development

        let payment = argsMap.value(forKey: "payment") as! NSDictionary
        let amount = payment.value(forKey: "product_price") as! String
        let productName = payment.value(forKey: "product_name") as! String
        let productId = payment.value(forKey: "product_id") as! String
        let callBackURL = payment.value(forKey: "callback_url") as! String
        let ebpNo = payment.value(forKey: "ebp_no") as? String

        print(clientId)
        print(secretKey)
        print(env)
        print(payment)
        print(amount)
        print(productName)
        print(productId)
        print(callBackURL)
        print(ebpNo==nil)

        sdk = EsewaSDK(inViewController: controller, environment: env, delegate: self)
        
        sdk?.initiatePayment(merchantId: clientId,
                                 merchantSecret: secretKey,
                                 productName: productName,
                                 productAmount: amount,
                                 productId: productId,
                                 callbackUrl: callBackURL,
                                 paymentProperties: ebpNo==nil ? nil : ["ebpNo":ebpNo!]
                                 
            )
        
    }
    
    public func onEsewaSDKPaymentSuccess(info: [String : Any]) {
        print("SUCCESS")
        SwiftEsewaFlutterSdkPlugin.channel?.invokeMethod(PAYMENT_METHOD_SUCCESS,arguments: info)
    }
       
    public func onEsewaSDKPaymentError(errorDescription: String) {
        print("FAILURE")
        SwiftEsewaFlutterSdkPlugin.channel?.invokeMethod(PAYMENT_METHOD_FAILURE,arguments: errorDescription)
    }
       
       
}
