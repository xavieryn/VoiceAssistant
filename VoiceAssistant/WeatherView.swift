import SwiftUI
import LiveKit

struct WeatherView: View {
    @EnvironmentObject private var room: Room
    @State private var hasRecipient: Bool = false

    func registerRpcMethod() {
        Task {
            await room.localParticipant.registerRpcMethod("greet") { data in
                print("Received greeting!")
                return "Hello there!"
            }
        }
    }

    func performGreetingRpc() {
        Task {
            guard let firstParticipant = room.remoteParticipants.values.first else {
                print("No remote participant found")
                return
            }

            do {
                let response: String = try await room.localParticipant.performRpc(
                    destinationIdentity: firstParticipant.identity!,
                    method: "greet",
                    payload: "Hello from RPC!"
                )
                print("RPC response: \(response)")
            } catch {
                print("RPC call failed: \(error)")
            }
        }
    }

    var body: some View {
        VStack {
            Text("WeatherView")
                .font(.title)
                .padding()

            if !room.remoteParticipants.isEmpty {
                VStack {
                    Text("Connected with remote participant")
                        .padding(.bottom)

                    Button("Send RPC Greeting") {
                        performGreetingRpc()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Waiting for remote participant to join...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            registerRpcMethod()
        }
        .onChange(of: room.remoteParticipants.count) { newCount in
            DispatchQueue.main.async {
                hasRecipient = newCount > 0
            }
        }
    }
}
