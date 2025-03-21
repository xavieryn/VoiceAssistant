import SwiftUI
import LiveKit

struct WeatherView: View {
    @State private var weatherText: String = "Waiting for weather update..."
    @EnvironmentObject private var room: Room
    @EnvironmentObject private var uiClient: UIUpdateClient  // Use shared background color state

    var body: some View {
        VStack {
            Text(weatherText)
                .font(.title)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(uiClient.backgroundColor) // Apply background color globally
        .onAppear {
            print("WeatherView appeared, registering RPC methods")
            
            Task {
                await registerRpcMethods()
            }
        }
    }
    
    func registerRpcMethods() async {
        // **Weather Data RPC**
        await room.localParticipant.registerRpcMethod("display_weather") { data in
            print("Received weather data: \(data)")
            
            // Extract JSON payload
            guard let payloadStart = "\(data)".range(of: "payload: \""),
                  let payloadEnd = "\(data)".range(of: "\", responseTimeout") else {
                print("Failed to locate payload in string")
                return "Error: Payload not found"
            }
            
            let startIndex = payloadStart.upperBound
            let endIndex = payloadEnd.lowerBound
            let payloadString = String("\(data)"[startIndex..<endIndex])
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")

            print("Extracted payload: \(payloadString)")
            
            guard let jsonData = payloadString.data(using: .utf8) else {
                print("Failed to convert to data")
                return "Error: Data conversion failed"
            }
            
            do {
                let weatherInfo = try JSONDecoder().decode(WeatherData.self, from: jsonData)
                DispatchQueue.main.async {
                    self.weatherText = weatherInfo.weather
                }
                print("Updated weather: \(self.weatherText)")
                return "Weather updated successfully"
            } catch {
                print("JSON decoding error: \(error)")
                return "Error: \(error.localizedDescription)"
            }
        }
        
        // **Background Color Change RPC**
        await room.localParticipant.registerRpcMethod("change_background") { data in
            print("Received background color data: \(data)")

            guard let payloadStart = "\(data)".range(of: "payload: \""),
                  let payloadEnd = "\(data)".range(of: "\", responseTimeout") else {
                print("Failed to locate payload in string")
                return "Error: Payload not found"
            }

            let startIndex = payloadStart.upperBound
            let endIndex = payloadEnd.lowerBound
            let payloadString = String("\(data)"[startIndex..<endIndex])
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")

            print("Extracted payload for color: \(payloadString)")

            guard let jsonData = payloadString.data(using: .utf8) else {
                print("Failed to convert to data")
                return "Error: Data conversion failed"
            }

            do {
                let colorInfo = try JSONDecoder().decode(ColorData.self, from: jsonData)
                DispatchQueue.main.async {
                    self.uiClient.updateBackgroundColor(colorInfo.color) // Update UI background
                }
                print("Updated background color to: \(colorInfo.color)")
                return "Background color updated successfully"
            } catch {
                print("JSON decoding error: \(error)")
                return "Error: \(error.localizedDescription)"
            }
        }
    }
}

// Define structs for JSON decoding
struct WeatherData: Codable {
    let location: String
    let weather: String
}

struct ColorData: Codable {
    let color: String
}
