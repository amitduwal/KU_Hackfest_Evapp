package com.f1soft.esewa.esewa_flutter_sdk

import com.f1soft.esewasdk.ESewaConfiguration
import com.f1soft.esewasdk.ESewaPayment

class PaymentUtils {

    companion object {

        fun initConfig(map: HashMap<String, String>): ESewaConfiguration {
            return ESewaConfiguration()
                .clientId(map["client_id"]?:"")
                .secretKey(map["client_secret"]?:"")
                .environment(map["environment"]?:"")
        }

        fun initPayment(map: HashMap<String, String>): ESewaPayment {
            when {
                map["ebp_no"]!=null -> {
                    return ESewaPayment(
                        map["product_price"]?:"",
                        map["product_name"]?:"",
                        map["product_id"]?:"",
                        map["callback_url"]?:"",
                        HashMap<String,String>().apply {
                            put("ebpNo",map["ebp_no"]!!)
                        }
                    )
                }
                else -> {
                    return ESewaPayment(
                        map["product_price"]?:"",
                        map["product_name"]?:"",
                        map["product_id"]?:"",
                        map["callback_url"]?:"",
                    )
                }
            }

        }

    }
}