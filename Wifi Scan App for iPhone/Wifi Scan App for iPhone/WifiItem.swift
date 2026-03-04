//
//  WifiItem.swift
//  Wifi Scan App for iPhone
//
//  Created by Adib Anwar on 4/3/26.
//


import Foundation

struct WifiItem {
    let ssid: String?
    let bssid: String?

    let ipv4: String?
    let subnetMask: String?
    let router: String?
    let dnsServers: [String]?

    let pathUsesWiFi: Bool
    let isExpensive: Bool
    let isConstrained: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool

    var displayName: String { ssid ?? "Current Wi-Fi" }

    var subtitle: String {
        if let ipv4 { return "IP: \(ipv4)" }
        return "Tap to view details"
    }
}
