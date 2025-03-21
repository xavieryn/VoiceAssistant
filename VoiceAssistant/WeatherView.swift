import SwiftUI
import LiveKit

struct WeatherView: View {
    @State private var weatherText: String = "Waiting for weather update..."
    @EnvironmentObject private var room: Room
    
    var body: some View {
        VStack {
            Text(weatherText)
                .font(.title)
                .padding()
        }
        .onAppear {
            print("WeatherView appeared, registering RPC method")
            
            Task {
                await registerRpcMethod()
            }
        }
    }
    
    func registerRpcMethod() async {
        await room.localParticipant.registerRpcMethod("display_weather") { data in
            print("Received weather data: \(data)")
            
            // Based on the output format, extract the payload directly
            let dataString = "\(data)"
            
            //RpcInvocationData(requestId: "3527ba05-2f01-483b-86bf-0157869a200e", callerIdentity: agent-AJ_vwCeyz3wWQHz, payload: "{\"location\": \"Boston, Massachusetts\", \"weather\": \"The weather in Boston, Massachusetts is Partly cloudy +46\\u00b0F.\"}", responseTimeout: 8.0)
            
            
            
            // Find the payload section between 'payload: "' and '", responseTimeout'
            
            // {\"location\": \"Boston, Massachusetts\", \"weather\": \"The weather in Boston, Massachusetts is Partly cloudy +46\\u00b0F.\"}
            guard let payloadStart = dataString.range(of: "payload: \""),
                  let payloadEnd = dataString.range(of: "\", responseTimeout") else {
                print("Failed to locate payload in string")
                return "Error: Payload not found"
            }
            
            // Extract the payload string and clean it up
            let startIndex = payloadStart.upperBound
            let endIndex = payloadEnd.lowerBound
            let payloadString = String(dataString[startIndex..<endIndex])
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
            
            print("Extracted payload: \(payloadString)")
            
            // Parse the clean JSON
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
        
    }
    
    
}

// Define struct for JSON decoding
struct WeatherData: Codable {
    let location: String
    let weather: String
}
