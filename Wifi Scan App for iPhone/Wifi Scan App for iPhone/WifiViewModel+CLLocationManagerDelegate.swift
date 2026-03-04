//
//  WifiViewModel+CLLocationManagerDelegate.swift
//  Wifi Scan App for iPhone
//
//  Created by Adib Anwar on 4/3/26.
//

import Foundation
import CoreLocation

extension WifiViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Refresh when permission changes, since SSID access can depend on it.
        refresh()
    }
}
