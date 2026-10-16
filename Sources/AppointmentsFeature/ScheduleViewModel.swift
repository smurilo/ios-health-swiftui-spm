import Foundation
import Observation
import HealthDomain
import HealthData

/// Step-by-step booking flow: specialty → doctor → day → time → confirmation.
@MainActor
@Observable
public final class ScheduleViewModel {
    public enum Step: Equatable { case specialty, doctor, slot, confirm, done }

    public private(set) var step: Step = .specialty
    public private(set) var specialties: [Specialty] = []
    public private(set) var doctors: [Doctor] = []
    public private(set) var days: [(day: Date, slots: [Slot])] = []
    public var selectedDay: Date?
    public private(set) var selectedSpecialty: Specialty?
    public private(set) var selectedDoctor: Doctor?
    public private(set) var selectedSlot: Slot?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public private(set) var booked: Appointment?

    private let api: HealthAPI
    private let rules: SchedulingRules
    private let calendar: Calendar
    private let now: () -> Date

    public init(api: HealthAPI, rules: SchedulingRules = SchedulingRules(), calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.api = api
        self.rules = rules
        self.calendar = calendar
        self.now = now
    }

    public var slotsForSelectedDay: [Slot] {
        days.first { $0.day == selectedDay }?.slots ?? []
    }

    public func onAppear() async {
        guard specialties.isEmpty else { return }
        await run { self.specialties = try await self.api.specialties() }
    }

    public func select(_ specialty: Specialty) async {
        selectedSpecialty = specialty
        await run {
            self.doctors = try await self.api.doctors(specialtyId: specialty.id)
            self.step = .doctor
        }
    }

    public func select(_ doctor: Doctor) async {
        selectedDoctor = doctor
        await run {
            let slots = try await self.api.slots(doctorId: doctor.id, from: self.now(), days: 14)
            self.days = self.rules.groupByDay(slots, calendar: self.calendar)
            self.selectedDay = self.days.first?.day
            self.step = .slot
        }
    }

    public func select(_ slot: Slot) {
        selectedSlot = slot
        step = .confirm
    }

    public func confirm() async {
        guard let slot = selectedSlot, let specialty = selectedSpecialty else { return }
        await run {
            let existing = try await self.api.myAppointments()
            try self.rules.validateBooking(slot, specialtyId: specialty.id, existing: existing, now: self.now())
            self.booked = try await self.api.book(slotId: slot.id)
            self.step = .done
        }
    }

    public func back() {
        errorMessage = nil
        switch step {
        case .doctor: step = .specialty
        case .slot: step = .doctor
        case .confirm: step = .slot
        case .specialty, .done: break
        }
    }

    public func restart() {
        step = .specialty
        selectedSpecialty = nil
        selectedDoctor = nil
        selectedSlot = nil
        booked = nil
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await work()
        } catch let error as SchedulingError {
            errorMessage = error.errorDescription
            if error == .slotTaken { step = .slot }
        } catch {
            errorMessage = "Falha de conexão. Tente novamente."
        }
    }
}
