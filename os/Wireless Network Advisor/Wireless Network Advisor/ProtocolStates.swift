//
//  ProtocolStates.swift
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-29.
//

import Foundation

struct ProtocolInfo: Codable {
    var isEnabled: Bool
    var port: Int
    var unsecurePacketCount: Int = 0  // Track incoming packets for this protocol
}

class ProtocolStateViewModel: ObservableObject {
    @Published var protocolStates: [String: ProtocolInfo] = loadProtocolStates()

    func toggleProtocolState(protocolName: String) {
        protocolStates[protocolName]?.isEnabled.toggle()
        saveProtocolStates(protocolStates)
    }

    func saveProtocolStates(_ states: [String: ProtocolInfo]) {
        if let data = try? JSONEncoder().encode(states) {
            UserDefaults.standard.set(data, forKey: "protocolStates")
        }
    }

    static func loadProtocolStates() -> [String: ProtocolInfo] {
        if let data = UserDefaults.standard.data(forKey: "protocolStates"),
            let savedStates = try? JSONDecoder().decode(
                [String: ProtocolInfo].self, from: data)
        {
            return savedStates
        } else {
            // Default protocol states if no saved data exists
            return [
                "HTTP": ProtocolInfo(isEnabled: true, port: 80),
                "FTP": ProtocolInfo(isEnabled: false, port: 21),
                "Telnet": ProtocolInfo(isEnabled: false, port: 23),
                "SMTP": ProtocolInfo(isEnabled: false, port: 25),
                "Time": ProtocolInfo(isEnabled: false, port: 37),
                "DNS": ProtocolInfo(isEnabled: false, port: 53),
                "IMAP": ProtocolInfo(isEnabled: false, port: 143),
                "SMB": ProtocolInfo(isEnabled: false, port: 445),
                "LDAP": ProtocolInfo(isEnabled: false, port: 389),
                "HTTPS": ProtocolInfo(isEnabled: true, port: 443),
            ]
        }
    }
    
    public func incrementIncomingPacket(for protocolName: String) {
        protocolStates[protocolName]?.unsecurePacketCount += 1
    }
}
