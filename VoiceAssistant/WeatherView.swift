

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
            Task {
                await registerRpcMethod()
            }
        }
    }
    func registerRpcMethod() async {
        await room.localParticipant.registerRpcMethod("display_weather") { data in
            print("Received weather data: \(data)")  // Debugging line to see data
            
            guard let jsonString = data as? String,
                  let jsonData = jsonString.data(using: .utf8),
                  let weatherInfo = try? JSONDecoder().decode(WeatherData.self, from: jsonData) else {
                print("Failed to parse weather data")
                return "Error"
            }
            
            DispatchQueue.main.async {
                self.weatherText = "Weather in \(weatherInfo.location): \(weatherInfo.weather)"
            }
            
            print("Updated weather: \(self.weatherText)")  // Debugging line to see updated value
            return "Weather updated successfully"
        }
    }
}

// Define struct for JSON decoding
struct WeatherData: Codable {
    let location: String
    let weather: String
}


