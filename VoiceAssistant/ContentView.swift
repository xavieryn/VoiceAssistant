import LiveKit
import SwiftUI

#if os(iOS) || os(macOS)
import LiveKitKrispNoiseFilter
#endif


struct ContentView: View {
    @StateObject private var room = Room()
    @StateObject private var uiClient = UIUpdateClient()
    
    // Krisp is available only on iOS and macOS right now
    #if os(iOS) || os(macOS)
    private let krispProcessor = LiveKitKrispNoiseFilter()
    #endif
    
    init() {
        print("ContentView initialized")
        NSLog("This is a test log message")

        #if os(iOS) || os(macOS)
        AudioManager.shared.capturePostProcessingDelegate = krispProcessor
        #endif
    }
    
    var body: some View {
        VStack(spacing: 24) {
            StatusView() // the 5 dots
                .frame(height: 256)
                .frame(maxWidth: 512)
            WeatherView()
            ControlBar() // button UI for connecting/disconnecting
        }
        .padding()
        .environmentObject(room)
        .environmentObject(uiClient) // Make UIUpdateClient available to child views
        .background(uiClient.backgroundColor) // **Apply global background color**
        .onAppear {
            #if os(iOS) || os(macOS)
            room.add(delegate: krispProcessor)
            #endif
            print("hi")
            
            // Connect to WebSocket server for UI updates
            uiClient.connect()
        }
        .onDisappear {
            // Disconnect when view disappears
            uiClient.disconnect()
            print("bye")
        }
    }
}


