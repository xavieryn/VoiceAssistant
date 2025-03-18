import LiveKit
import LiveKitComponents
import SwiftUI

/// Shows a visualizer for the agent participant in the room
struct StatusView: View {
    // Load the room from the environment
    @EnvironmentObject private var room: Room
    @EnvironmentObject private var uiClient: UIUpdateClient
    
    // Find the first agent participant in the room
    private var agentParticipant: RemoteParticipant? {
        for participant in room.remoteParticipants.values {
            if participant.kind == .agent {
                return participant
            }
        }
        
        return nil
    }
    
    // Reads the agent state property which is updated automatically
    private var agentState: AgentState {
        agentParticipant?.agentState ?? .initializing
    }
    
    var body: some View {
        VStack {
            AgentBarAudioVisualizer(
                audioTrack: agentParticipant?.firstAudioTrack,
                agentState: agentState,
                barColor: .primary,
                barCount: 5
            )
            .id(agentParticipant?.firstAudioTrack?.id)
            
            Text("Your status content")
                .font(.system(size: uiClient.textSize))
        }
    }
}
