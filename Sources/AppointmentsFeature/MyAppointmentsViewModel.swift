import Foundation
import Observation
import HealthDomain
import HealthData

@MainActor
@Observable
public final class MyAppointmentsViewModel {
    public private(set) var upcoming: [Appointment] = []
    public private(set) var errorMessage: String?
    private let api: HealthAPI
    private let rules: SchedulingRules
    private let now: () -> Date

    public init(api: HealthAPI, rules: SchedulingRules = SchedulingRules(), now: @escaping () -> Date = Date.init) {
        self.api = api
        self.rules = rules
        self.now = now
    }

    public func load() async {
        let all = (try? await api.myAppointments()) ?? []
        upcoming = all.filter { $0.status == .scheduled && $0.slot.start > now() }
    }

    public func canCancel(_ appointment: Appointment) -> Bool {
        (try? rules.validateCancellation(appointment, now: now())) != nil
    }

    public func cancel(_ appointment: Appointment) async {
        do {
            try rules.validateCancellation(appointment, now: now())
            try await api.cancel(appointmentId: appointment.id)
            errorMessage = nil
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Não foi possível cancelar."
        }
    }
}
