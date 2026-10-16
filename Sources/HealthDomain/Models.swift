import Foundation

public struct Specialty: Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let symbol: String
    public init(id: String, name: String, symbol: String) {
        self.id = id
        self.name = name
        self.symbol = symbol
    }
}

public struct Doctor: Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let crm: String
    public let specialtyId: String
    public init(id: String, name: String, crm: String, specialtyId: String) {
        self.id = id
        self.name = name
        self.crm = crm
        self.specialtyId = specialtyId
    }
}

public struct Slot: Hashable, Identifiable, Sendable {
    public let id: String
    public let doctorId: String
    public let start: Date
    public let isTelemedicine: Bool
    public init(id: String, doctorId: String, start: Date, isTelemedicine: Bool) {
        self.id = id
        self.doctorId = doctorId
        self.start = start
        self.isTelemedicine = isTelemedicine
    }
}

public struct Appointment: Hashable, Identifiable, Sendable {
    public enum Status: String, Sendable { case scheduled, cancelled }
    public let id: String
    public let slot: Slot
    public let doctor: Doctor
    public let specialty: Specialty
    public var status: Status
    public init(id: String, slot: Slot, doctor: Doctor, specialty: Specialty, status: Status = .scheduled) {
        self.id = id
        self.slot = slot
        self.doctor = doctor
        self.specialty = specialty
        self.status = status
    }
}
