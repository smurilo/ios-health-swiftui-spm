import Foundation
import HealthDomain

public protocol HealthAPI: Sendable {
    func specialties() async throws -> [Specialty]
    func doctors(specialtyId: String) async throws -> [Doctor]
    func slots(doctorId: String, from: Date, days: Int) async throws -> [Slot]
    func book(slotId: String) async throws -> Appointment
    func myAppointments() async throws -> [Appointment]
    func cancel(appointmentId: String) async throws
}

/// Simulated backend (actor = thread-safe without locks). Also used by SwiftUI previews.
public actor InMemoryHealthAPI: HealthAPI {
    private let specialtiesList = [
        Specialty(id: "cardio", name: "Cardiologia", symbol: "heart.fill"),
        Specialty(id: "derma", name: "Dermatologia", symbol: "hand.raised.fill"),
        Specialty(id: "pedia", name: "Pediatria", symbol: "figure.and.child.holdinghands"),
    ]
    private let doctorsList = [
        Doctor(id: "d1", name: "Dra. Helena Costa", crm: "CRM-AL 1234", specialtyId: "cardio"),
        Doctor(id: "d2", name: "Dr. Rafael Lima", crm: "CRM-AL 5678", specialtyId: "cardio"),
        Doctor(id: "d3", name: "Dra. Marina Alves", crm: "CRM-AL 9012", specialtyId: "derma"),
        Doctor(id: "d4", name: "Dr. Paulo Nunes", crm: "CRM-AL 3456", specialtyId: "pedia"),
    ]
    private var taken: Set<String> = []
    private var appointments: [Appointment] = []
    private let calendar: Calendar
    private let latency: UInt64

    public init(calendar: Calendar = .current, latencyMs: UInt64 = 400) {
        self.calendar = calendar
        latency = latencyMs * 1_000_000
    }

    public func specialties() async throws -> [Specialty] {
        try await Task.sleep(nanoseconds: latency)
        return specialtiesList
    }

    public func doctors(specialtyId: String) async throws -> [Doctor] {
        doctorsList.filter { $0.specialtyId == specialtyId }
    }

    /// Weekdays, 08:00–12:00 every 30 min; afternoons are telemedicine.
    public func slots(doctorId: String, from: Date, days: Int) async throws -> [Slot] {
        try await Task.sleep(nanoseconds: latency)
        var result: [Slot] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: from)),
                  !calendar.isDateInWeekend(day) else { continue }
            for (hour, minute, tele) in [(8, 0, false), (8, 30, false), (9, 0, false), (10, 30, false), (14, 0, true), (15, 30, true)] {
                guard let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), start > from else { continue }
                let id = "\(doctorId)-\(Int(start.timeIntervalSince1970))"
                if !taken.contains(id) { result.append(Slot(id: id, doctorId: doctorId, start: start, isTelemedicine: tele)) }
            }
        }
        return result
    }

    public func book(slotId: String) async throws -> Appointment {
        try await Task.sleep(nanoseconds: latency)
        guard !taken.contains(slotId),
              let doctorId = slotId.split(separator: "-").first.map(String.init),
              let seconds = slotId.split(separator: "-").last.flatMap({ TimeInterval($0) }),
              let doctor = doctorsList.first(where: { $0.id == doctorId }),
              let specialty = specialtiesList.first(where: { $0.id == doctor.specialtyId }) else {
            throw SchedulingError.slotTaken
        }
        taken.insert(slotId)
        let start = Date(timeIntervalSince1970: seconds)
        let hour = calendar.component(.hour, from: start)
        let appointment = Appointment(id: UUID().uuidString, slot: Slot(id: slotId, doctorId: doctorId, start: start, isTelemedicine: hour >= 14),
                                      doctor: doctor, specialty: specialty)
        appointments.append(appointment)
        return appointment
    }

    public func myAppointments() async throws -> [Appointment] {
        appointments.sorted { $0.slot.start < $1.slot.start }
    }

    public func cancel(appointmentId: String) async throws {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else { return }
        appointments[index].status = .cancelled
        taken.remove(appointments[index].slot.id)
    }
}
