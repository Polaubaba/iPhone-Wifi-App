import SwiftUI

struct ContentView: View {
    @StateObject private var vm = WifiViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section(header: Text("Networks")) {
                        // iOS public APIs cannot list nearby Wi-Fi SSIDs.
                        // So we present the "current Wi-Fi" as the selectable network.
                        if let current = vm.currentWifiItem {
                            NavigationLink(destination: WifiDetailView(item: current)) {
                                HStack {
                                    Image(systemName: "wifi")
                                    VStack(alignment: .leading) {
                                        Text(current.displayName)
                                            .font(.headline)
                                        Text(current.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "wifi.slash")
                                VStack(alignment: .leading) {
                                    Text("Not connected to Wi-Fi")
                                        .font(.headline)
                                    Text(vm.statusMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Section(header: Text("Path / Device Network")) {
                        ForEach(vm.pathSummaryItems, id: \.title) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title).font(.headline)
                                Text(row.value).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Bottom refresh bar
                HStack {
                    Button {
                        vm.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        vm.openHotspotSettings()
                    } label: {
                        Label("Rehost", systemImage: "personalhotspot")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Wi-Fi Inspector")
            .onAppear { vm.start() }
        }
    }
}

struct WifiDetailView: View {
    let item: WifiItem
    
    var body: some View {
        List {
            Section(header: Text("Wi-Fi Identity")) {
                KeyValueRow("SSID", item.ssid ?? "Unknown / Not Available")
                KeyValueRow("BSSID", item.bssid ?? "Unknown / Not Available")
                Section(header: Text("Wi-Fi Identity")) {
                    KeyValueRow("SSID", item.ssid ?? "Unknown / Not Available")
                    KeyValueRow("BSSID", item.bssid ?? "Unknown / Not Available")
                }
                
                Section(header: Text("IP Configuration")) {
                    KeyValueRow("IPv4", item.ipv4 ?? "—")
                    KeyValueRow("Subnet Mask", item.subnetMask ?? "—")
                    KeyValueRow("Router (Gateway)", item.router ?? "—")
                    KeyValueRow("DNS", item.dnsServers?.joined(separator: ", ") ?? "—")
                }
                
                Section(header: Text("System Path (NWPath)")) {
                    KeyValueRow("Using Wi-Fi", item.pathUsesWiFi ? "Yes" : "No")
                    KeyValueRow("Expensive", item.isExpensive ? "Yes" : "No")
                    KeyValueRow("Constrained", item.isConstrained ? "Yes" : "No")
                    KeyValueRow("IPv4 Support", item.supportsIPv4 ? "Yes" : "No")
                    KeyValueRow("IPv6 Support", item.supportsIPv6 ? "Yes" : "No")
                }
            }
            .navigationTitle(item.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct KeyValueRow: View {
        let key: String
        let value: String
        
        init(_ key: String, _ value: String) {
            self.key = key
            self.value = value
        }
        
        var body: some View {
            HStack(alignment: .top) {
                Text(key)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
