import XCTest
@testable import HealthDomain

final class SchedulingRulesTests: XCTestCase {
    private let rules = SchedulingRules()
    private let now = Date(timeIntervalSince1970: 1_772_000_000)
    private let cardio = Specialty(id: "cardio", name: "Cardiologia", symbol: "")
    private let doctor = Doctor(id: "d1", name: "Dra.", crm: "", specialtyId: "cardio")

    private func slot(inHours h: Double) -> Slot {
        Slot(id: "s\(h)", doctorId: "d1", start: now.addingTimeInterval(h * 3600), isTelemedicine: false)
    }

    func testBookingRules() {
        XCTAssertThrowsError(try rules.validateBooking(slot(inHours: -1), specialtyId: "cardio", existing: [], now: now)) {
            XCTAssertEqual($0 as? SchedulingError, .slotInPast)
        }
        XCTAssertThrowsError(try rules.validateBooking(slot(inHours: 1), specialtyId: "cardio", existing: [], now: now)) {
            XCTAssertEqual($0 as? SchedulingError, .tooSoon(minHours: 2))
        }
        XCTAssertNoThrow(try rules.validateBooking(slot(inHours: 3), specialtyId: "cardio", existing: [], now: now))
    }

    func testOnlyOneUpcomingAppointmentPerSpecialty() {
        let existing = [Appointment(id: "a", slot: slot(inHours: 48), doctor: doctor, specialty: cardio)]
        XCTAssertThrowsError(try rules.validateBooking(slot(inHours: 72), specialtyId: "cardio", existing: existing, now: now))
        XCTAssertNoThrow(try rules.validateBooking(slot(inHours: 72), specialtyId: "derma", existing: existing, now: now))
        var cancelled = existing[0]
        cancelled.status = .cancelled
        XCTAssertNoThrow(try rules.validateBooking(slot(inHours: 72), specialtyId: "cardio", existing: [cancelled], now: now))
    }

    func testCancellationNeeds24Hours() {
        let soon = Appointment(id: "a", slot: slot(inHours: 10), doctor: doctor, specialty: cardio)
        XCTAssertThrowsError(try rules.validateCancellation(soon, now: now))
        let later = Appointment(id: "b", slot: slot(inHours: 30), doctor: doctor, specialty: cardio)
        XCTAssertNoThrow(try rules.validateCancellation(later, now: now))
    }
}
