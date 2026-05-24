package com.motalindo.gymku

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.content.Context
import android.content.Intent
import android.util.Log

class MyHceService : HostApduService() {

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            return byteArrayOf(0x6A.toByte(), 0x82.toByte()) // File not found
        }

        val hexCommand = bytesToHex(commandApdu)
        
        // Single prefs declaration for the entire function scope
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val nfcActive = prefs.getBoolean("flutter.nfc_active", false)
        Log.d("MyHceService", "Command received: $hexCommand, active: $nfcActive")

        if (!nfcActive) {
            Log.d("MyHceService", "HCE is not active. Rejecting command.")
            return byteArrayOf(0x6A.toByte(), 0x82.toByte()) // File not found
        }

        // Send a broadcast intent to MainActivity to trigger Flutter UI updates
        val intent = Intent("com.motalindo.gymku.HCE_TAP")
        sendBroadcast(intent)

        // Check if it is a SELECT AID command: 00 A4 04 00 ...
        if (commandApdu.size >= 4 && commandApdu[0] == 0x00.toByte() && commandApdu[1] == 0xA4.toByte() && commandApdu[2] == 0x04.toByte() && commandApdu[3] == 0x00.toByte()) {
            val payload = prefs.getString("flutter.nfc_payload", null)
            Log.d("MyHceService", "SELECT AID command. Payload: $payload")

            if (payload != null && payload.isNotEmpty()) {
                val payloadBytes = payload.toByteArray(Charsets.US_ASCII)
                // Return payload bytes followed by 90 00 (Success)
                val response = ByteArray(payloadBytes.size + 2)
                System.arraycopy(payloadBytes, 0, response, 0, payloadBytes.size)
                response[response.size - 2] = 0x90.toByte()
                response[response.size - 1] = 0x00.toByte()
                return response
            } else {
                return byteArrayOf(0x90.toByte(), 0x00.toByte())
            }
        }

        // Trigger command or other commands: send payload
        val payload = prefs.getString("flutter.nfc_payload", null)
        if (payload != null && payload.isNotEmpty()) {
            val payloadBytes = payload.toByteArray(Charsets.US_ASCII)
            val response = ByteArray(payloadBytes.size + 2)
            System.arraycopy(payloadBytes, 0, response, 0, payloadBytes.size)
            response[response.size - 2] = 0x90.toByte()
            response[response.size - 1] = 0x00.toByte()
            return response
        }

        return byteArrayOf(0x6D.toByte(), 0x00.toByte()) // Instruction not supported
    }

    override fun onDeactivated(reason: Int) {
        Log.d("MyHceService", "Deactivated with reason: $reason")
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val hexChars = CharArray(bytes.size * 2)
        for (i in bytes.indices) {
            val v = bytes[i].toInt() and 0xFF
            hexChars[i * 2] = "0123456789ABCDEF"[v ushr 4]
            hexChars[i * 2 + 1] = "0123456789ABCDEF"[v and 0x0F]
        }
        return String(hexChars)
    }
}
