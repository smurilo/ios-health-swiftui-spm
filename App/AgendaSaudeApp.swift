import SwiftUI
import AppointmentsFeature
import HealthData

@main
struct AgendaSaudeApp: App {
    /// Single backend instance shared by the tabs (swap for a remote implementation in production).
    private let api: HealthAPI = InMemoryHealthAPI()

    var body: some Scene {
        WindowGroup {
            TabView {
                ScheduleFlowView(api: api).tabItem { Label("Agendar", systemImage: "calendar.badge.plus") }
                MyAppointmentsView(api: api).tabItem { Label("Minhas consultas", systemImage: "list.bullet.clipboard") }
            }
        }
    }
}
