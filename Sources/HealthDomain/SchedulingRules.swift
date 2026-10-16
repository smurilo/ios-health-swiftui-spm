import Foundation

public enum SchedulingError: Error, Equatable, LocalizedError {
    case slotInPast
    case tooSoon(minHours: Int)
    case duplicateSpecialty
    case cancellationTooLate(minHours: Int)
    case slotTaken

    public var errorDescription: String? {
        switch self {
        case .slotInPast: return "Este horário já passou."
        case let .tooSoon(h): return "Agendamentos precisam de pelo menos \(h)h de antecedência."
        case .duplicateSpecialty: return "Você já tem uma consulta marcada nesta especialidade."
        case let .cancellationTooLate(h): return "Cancelamentos só são permitidos até \(h)h antes. Entre em contato com a clínica."
        case .slotTaken: return "Este horário acabou de ser ocupado. Escolha outro."
        }
    }
}

/// Business rules of the clinic, isolated from UI and networking.
public struct SchedulingRules: Sendable {
    public var minimumNoticeHours = 2
    public var cancellationNoticeHours = 24

    public init() {}

    public func validateBooking(_ slot: Slot, specialtyId: String, existing: [Appointment], now: Date) throws {
        if slot.start <= now { throw SchedulingError.slotInPast }
        if slot.start.timeIntervalSince(now) < Double(minimumNoticeHours) * 3600 {
            throw SchedulingError.tooSoon(minHours: minimumNoticeHours)
        }
        if existing.contains(where: { $0.status == .scheduled && $0.specialty.id == specialtyId && $0.slot.start > now }) {
            throw SchedulingError.duplicateSpecialty
        }
    }

    public func validateCancellation(_ appointment: Appointment, now: Date) throws {
        if appointment.slot.start.timeIntervalSince(now) < Double(cancellationNoticeHours) * 3600 {
            throw SchedulingError.cancellationTooLate(minHours: cancellationNoticeHours)
        }
    }

    /// Groups slots by calendar day for the date picker strip.
    public func groupByDay(_ slots: [Slot], calendar: Calendar) -> [(day: Date, slots: [Slot])] {
        Dictionary(grouping: slots) { calendar.startOfDay(for: $0.start) }
            .map { (day: $0.key, slots: $0.value.sorted { $0.start < $1.start }) }
            .sorted { $0.day < $1.day }
    }
}
