import Foundation
import NetworkExtension

enum WifiIdentity {
    static func fetchCurrent() async -> (ssid: String?, bssid: String?) {
        if let network = await NEHotspotNetwork.fetchCurrent() {
            return (network.ssid, network.bssid)
        }
        return (nil, nil)
    }
}
