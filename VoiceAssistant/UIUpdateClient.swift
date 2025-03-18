import Foundation
import SwiftUI
import Combine

class UIUpdateClient: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectTimer: Timer?
    
    @Published var backgroundColor: Color = .white
    @Published var textSize: CGFloat = 16
    
    func connect() {
        guard webSocket == nil else { return }
        
        session = URLSession(configuration: .default)
        // Change this to your actual server IP address when not testing on localhost
        guard let url = URL(string: "ws://localhost:8765") else { return }
        
        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()
        
        print("Connected to UI update server")
    }
    
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        session = nil
        
        // Stop reconnect timer if it's running
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        print("Disconnected from UI update server")
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("Received data: \(text)")
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.scheduleReconnect()
            }
        }
    }
    
    private func scheduleReconnect() {
        // Disconnect current socket if any
        webSocket?.cancel(with: .abnormalClosure, reason: nil)
        webSocket = nil
        
        // Schedule reconnect after 5 seconds
        DispatchQueue.main.async {
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.connect()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            print("Failed to convert message to data")
            return
        }
        
        do {
            let message = try JSONDecoder().decode(UIUpdateMessage.self, from: data)
            
            DispatchQueue.main.async {
                switch message.type {
                case "change_background":
                    if let colorString = message.data["color"] as? String {
                        self.backgroundColor = self.color(from: colorString)
                    }
                case "change_text_size":
                    if let sizeString = message.data["size"] as? String {
                        self.textSize = self.fontSize(from: sizeString)
                    }
                default:
                    print("Unknown message type: \(message.type)")
                }
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }
    
    private func color(from string: String) -> Color {
        // Handle common color names
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
            // Try to parse as hex
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
    
    private func fontSize(from string: String) -> CGFloat {
        switch string.lowercased() {
        case "small": return 12
        case "medium": return 16
        case "large": return 20
        case "xlarge": return 24
        default: return 16
        }
    }
}

// Simple decodable structure for UI update messages
struct UIUpdateMessage: Decodable {
    struct DataValue: Decodable {
        let value: Any
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let string = try? container.decode(String.self) {
                value = string
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if container.decodeNil() {
                value = NSNull()
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode value"
                )
            }
        }
    }
    
    let type: String
    let data: [String: Any]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        let dataContainer = try container.decode([String: DataValue].self, forKey: .data)
        data = dataContainer.mapValues { $0.value }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
}
