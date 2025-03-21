import Foundation
import SwiftUI
import Combine
import LiveKit

class UIUpdateClient: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectTimer: Timer?
    
    @Published var backgroundColor: Color = .white
    @Published var textSize: CGFloat = 16
    var room: Room?

    init(room: Room? = nil) {
        self.room = room
        print("Registering RPC method for change_background...") 
        registerRpcMethod()
    }

    func registerRpcMethod() {
        guard let room = room else {
            print("Room instance is nil, cannot register RPC method.")
            return
        }
        
        Task {
            await room.localParticipant.registerRpcMethod("change_background") { data in
                print("Received RPC for background change: \(data)")

                // Convert data to string for parsing
                let dataString = "\(data)"
                print(data)
                
                guard let payloadStart = dataString.range(of: "payload: \""),
                      let payloadEnd = dataString.range(of: "\", responseTimeout") else {
                    print("Failed to locate payload in string")
                    return "Error: Payload not found"
                }
                
                let startIndex = payloadStart.upperBound
                let endIndex = payloadEnd.lowerBound
                let payloadString = String(dataString[startIndex..<endIndex])
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\\\", with: "\\")

                print("Extracted payload: \(payloadString)")
                
                guard let jsonData = payloadString.data(using: .utf8) else {
                    print("Failed to convert payload to data")
                    return "Error: Data conversion failed"
                }

                do {
                    let colorInfo = try JSONDecoder().decode(ColorData.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        self.backgroundColor = self.color(from: colorInfo.color)
                    }
                    
                    print("Updated background color: \(colorInfo.color)")
                    return "Background color updated successfully"
                } catch {
                    print("JSON decoding error: \(error)")
                    return "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    func connect() {
        guard webSocket == nil else { return }

        session = URLSession(configuration: .default)
        guard let url = URL(string: "wss://pmi-ios-9dsuqmkw.livekit.cloud/ws") else { return } // Replace with your actual WebSocket URL

        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()

        receiveMessage()
        print("Connected to UI update server")
    }

    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        session = nil

        reconnectTimer?.invalidate()
        reconnectTimer = nil

        print("Disconnected from UI update server")
    }

    private func receiveMessage() {
        webSocket?.receive { result in
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    fatalError()
                }
            }

            self.receiveMessage() // Keep receiving messages
        }
    }


    private func color(from string: String) -> Color {
        switch string.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "black": return .black
        case "white": return .white
        case "gray", "grey": return .gray
        default:
            if string.hasPrefix("#") {
                let hex = string.dropFirst()
                var rgbValue: UInt64 = 0
                Scanner(string: String(hex)).scanHexInt64(&rgbValue)
                
                let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
                let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
                let b = Double(rgbValue & 0x0000FF) / 255.0
                
                return Color(red: r, green: g, blue: b)
            }
            return .white
        }
    }
}

// Define struct for JSON decoding
struct ColorData: Codable {
    let color: String
}
