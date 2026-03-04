import Foundation

enum NetworkInfo {

    struct IPInfo {
        let ipv4: String?
        let subnetMask: String?
        let router: String?
        let dnsServers: [String]?
    }

    static func currentIPInfo() -> IPInfo {
        let ipv4 = ipv4Address(interface: "en0") ?? ipv4Address(interface: nil)
        let subnet = ipv4Netmask(interface: "en0") ?? ipv4Netmask(interface: nil)

        // Default gateway + system DNS are not reliably accessible via public iOS APIs.
        return IPInfo(ipv4: ipv4, subnetMask: subnet, router: nil, dnsServers: nil)
    }

    // MARK: - IPv4 address/netmask (getifaddrs)

    private static func ipv4Address(interface: String?) -> String? {
        var address: String?
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let ifa = ptr.pointee
            guard let sa = ifa.ifa_addr else { continue }
            if sa.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: ifa.ifa_name)
                if let interface, name != interface { continue }

                var addr = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr }
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                inet_ntop(AF_INET, &addr, &buffer, socklen_t(INET_ADDRSTRLEN))
                address = String(cString: buffer)

                if interface != nil { break }
            }
        }
        return address
    }

    private static func ipv4Netmask(interface: String?) -> String? {
        var mask: String?
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let ifa = ptr.pointee
            guard let sa = ifa.ifa_netmask else { continue }
            if sa.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: ifa.ifa_name)
                if let interface, name != interface { continue }

                var addr = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr }
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                inet_ntop(AF_INET, &addr, &buffer, socklen_t(INET_ADDRSTRLEN))
                mask = String(cString: buffer)

                if interface != nil { break }
            }
        }
        return mask
    }
}
