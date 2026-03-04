//
//  WifiViewModel.swift
//  Wifi Scan App for iPhone
//
//  Created by Adib Anwar on 4/3/26.
//


import Foundation
import SwiftUI
import Network
import NetworkExtension
import CoreLocation
import UIKit
import Combine


final class WifiViewModel: NSObject, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    @Published var currentWifiItem: WifiItem?
    @Published var pathSummaryItems: [PathSummaryRow] = []
    @Published var statusMessage: String = "—"
    
    
    private let monitor = Network.NWPathMonitor()
    
    private let queue = DispatchQueue(label: "NWPathMonitorQueue")
    private let locationManager = CLLocationManager()

    
    
    override init() {
        super.init()
        locationManager.delegate = self
    }

    func start() {
        // Ask for permission; iOS often requires Location permission for SSID.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        startPathMonitor()
        refresh()
    }

    func refresh() {
        updatePathSummary()

        Task { @MainActor in
            let wifiIdentity = await WifiIdentity.fetchCurrent()
            let ipInfo = NetworkInfo.currentIPInfo()

            let item = WifiItem(
                ssid: wifiIdentity.ssid,
                bssid: wifiIdentity.bssid,
                ipv4: ipInfo.ipv4,
                subnetMask: ipInfo.subnetMask,
                router: ipInfo.router,
                dnsServers: ipInfo.dnsServers,
                pathUsesWiFi: lastPath?.usesInterfaceType(Network.NWInterface.InterfaceType.wifi) ?? false,
                isExpensive: lastPath?.isExpensive ?? false,
                isConstrained: lastPath?.isConstrained ?? false,
                supportsIPv4: lastPath?.supportsIPv4 ?? false,
                supportsIPv6: lastPath?.supportsIPv6 ?? false
            )

            // If not on Wi-Fi, ssid will be nil and pathUsesWiFi likely false
            self.currentWifiItem = (item.pathUsesWiFi ? item : nil)

            if item.pathUsesWiFi == false {
                self.statusMessage = "Connect to Wi-Fi to view SSID details. (iOS may still hide SSID depending on permissions/policy.)"
            } else {
                self.statusMessage = "Connected"
            }
        }
    }

    func openHotspotSettings() {
        // You cannot enable/disable Personal Hotspot programmatically.
        // This opens Settings app (best-effort).
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - NWPath
    private var lastPath: Network.NWPath?

    private func startPathMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.lastPath = path
                self?.updatePathSummary()
            }
        }
        monitor.start(queue: queue)
    }

    private func updatePathSummary() {
        guard let path = lastPath else {
            pathSummaryItems = [
                .init(title: "Network Status", value: "Unknown (monitor starting…)"),
            ]
            return
        }

        let status: String = {
            switch path.status {
            case .satisfied: return "Satisfied"
            case .unsatisfied: return "Unsatisfied"
            case .requiresConnection: return "Requires Connection"
            @unknown default: return "Unknown"
            }
        }()

        pathSummaryItems = [
            .init(title: "Status", value: status),
            .init(title: "Interfaces", value: interfaceSummary(path)),
            .init(title: "Expensive", value: path.isExpensive ? "Yes" : "No"),
            .init(title: "Constrained", value: path.isConstrained ? "Yes" : "No"),
            .init(title: "Supports IPv4", value: path.supportsIPv4 ? "Yes" : "No"),
            .init(title: "Supports IPv6", value: path.supportsIPv6 ? "Yes" : "No"),
        ]
    }

    private func interfaceSummary(_ path: Network.NWPath) -> String {
        var parts: [String] = []

        if path.usesInterfaceType(Network.NWInterface.InterfaceType.wifi) { parts.append("Wi-Fi") }
        if path.usesInterfaceType(Network.NWInterface.InterfaceType.cellular) { parts.append("Cellular") }
        if path.usesInterfaceType(Network.NWInterface.InterfaceType.wiredEthernet) { parts.append("Ethernet") }
        if path.usesInterfaceType(Network.NWInterface.InterfaceType.loopback) { parts.append("Loopback") }

        return parts.isEmpty ? "Other/Unknown" : parts.joined(separator: ", ")
    }
}

struct PathSummaryRow {
    let title: String
    let value: String
}
