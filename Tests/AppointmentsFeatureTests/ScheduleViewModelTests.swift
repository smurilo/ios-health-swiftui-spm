import XCTest
import HealthDomain
import HealthData
@testable import AppointmentsFeature

@MainActor
final class ScheduleViewModelTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Maceio")!
        return c
    }()

    /// Monday 2026-03-02 07:00 local time
    private var monday7am: Date { calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 7))! }

    func testFullBookingFlow() async {
        let api = InMemoryHealthAPI(calendar: calendar, latencyMs: 0)
        let vm = ScheduleViewModel(api: api, calendar: calendar, now: { self.monday7am })

        await vm.onAppear()
        XCTAssertEqual(vm.specialties.count, 3)

        await vm.select(vm.specialties[0])
        XCTAssertEqual(vm.step, .doctor)
        XCTAssertEqual(vm.doctors.map(\.id), ["d1", "d2"])

        await vm.select(vm.doctors[0])
        XCTAssertEqual(vm.step, .slot)
        XCTAssertEqual(vm.days.count, 10) // 14 days minus 2 weekends
        XCTAssertEqual(vm.selectedDay, calendar.startOfDay(for: monday7am))

        // 08:00 is only 1h away → blocked by the 2h notice rule
        vm.select(vm.slotsForSelectedDay[0])
        await vm.confirm()
        XCTAssertEqual(vm.errorMessage, "Agendamentos precisam de pelo menos 2h de antecedência.")

        vm.back()
        vm.select(vm.slotsForSelectedDay.first { calendar.component(.hour, from: $0.start) == 10 }!)
        await vm.confirm()
        XCTAssertEqual(vm.step, .done)
        XCTAssertEqual(vm.booked?.doctor.name, "Dra. Helena Costa")
    }

    func testBookedSlotDisappearsAndSecondCardioIsRefused() async {
        let api = InMemoryHealthAPI(calendar: calendar, latencyMs: 0)
        let vm = ScheduleViewModel(api: api, calendar: calendar, now: { self.monday7am })
        await vm.onAppear()
        await vm.select(vm.specialties[0])
        await vm.select(vm.doctors[1])
        let target = vm.days[1].slots[0]
        vm.select(target)
        await vm.confirm()

        vm.restart()
        await vm.select(vm.specialties[0])
        await vm.select(vm.doctors[1])
        XCTAssertFalse(vm.days.flatMap(\.slots).contains(target))

        vm.select(vm.days[2].slots[0])
        await vm.confirm()
        XCTAssertEqual(vm.errorMessage, "Você já tem uma consulta marcada nesta especialidade.")
    }

    func testMyAppointmentsCancellationRespectsNotice() async throws {
        let api = InMemoryHealthAPI(calendar: calendar, latencyMs: 0)
        let tomorrow9 = calendar.date(byAdding: .day, value: 1, to: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: monday7am)!)!
        let slotId = "d3-\(Int(tomorrow9.timeIntervalSince1970))"
        _ = try await api.book(slotId: slotId)

        let vm = MyAppointmentsViewModel(api: api, now: { self.monday7am })
        await vm.load()
        XCTAssertEqual(vm.upcoming.count, 1)
        XCTAssertTrue(vm.canCancel(vm.upcoming[0])) // 26h ahead

        let lateVM = MyAppointmentsViewModel(api: api, now: { tomorrow9.addingTimeInterval(-3600) })
        await lateVM.load()
        await lateVM.cancel(lateVM.upcoming[0])
        XCTAssertNotNil(lateVM.errorMessage)

        await vm.cancel(vm.upcoming[0])
        XCTAssertTrue(vm.upcoming.isEmpty)
    }
}
