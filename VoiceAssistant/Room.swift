import LiveKit
import Foundation

// Extend Room class to add RPC functionality for weather
extension Room {
    // Register RPC methods when the room connects
    func setupRPCMethods() {
        Task {
            try? await self.localParticipant.registerRpcMethod("get_weather") { data in
                // Parse payload as location if provided
                let location = data.payload as? String ?? "current location"
                
                // Simulate weather data - in a real app, this would call a weather API
                let weatherData = [
                    "location": location,
                    "temperature": 72,
                    "condition": "Partly Cloudy",
                    "humidity": 45,
                    "wind": "5 mph"
                ]
                
                // Convert to JSON string
                if let jsonData = try? JSONSerialization.data(withJSONObject: weatherData),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                } else {
                    return "{\"error\": \"Failed to get weather\"}"
                }
            }
            
            print("RPC methods registered successfully")
        }
    }
    
    // Method to call agent's weather service via RPC
    func getWeatherFromAgent(location: String?, agentIdentity: String) async -> [String: Any]? {
        do {
            let payload = location ?? "current location"
            let response = try await self.localParticipant.performRpc(
                destinationIdentity: agentIdentity,
                method: "get_weather",
                payload: payload
            )
            
            if let data = response.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
            return nil
        } catch let error as RpcError {
            print("Weather RPC call failed: \(error)")
            return nil
        } catch {
            print("Unexpected error in weather RPC: \(error)")
            return nil
        }
    }
}
