#if canImport(SwiftUI)
import SwiftUI
import HealthDomain
import HealthData

public struct ScheduleFlowView: View {
    @State private var model: ScheduleViewModel

    public init(api: HealthAPI) {
        _model = State(initialValue: ScheduleViewModel(api: api))
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch model.step {
                case .specialty: specialtyList
                case .doctor: doctorList
                case .slot: slotPicker
                case .confirm: confirmation
                case .done: success
                }
            }
            .animation(.default, value: model.step)
            .overlay { if model.isLoading { ProgressView().controlSize(.large) } }
            .navigationTitle("Agendar consulta")
            .toolbar {
                if model.step != .specialty && model.step != .done {
                    ToolbarItem(placement: .topBarLeading) { Button("Voltar", action: model.back) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let message = model.errorMessage {
                    Text(message).padding().frame(maxWidth: .infinity).background(.red.opacity(0.15)).accessibilityAddTraits(.isStaticText)
                }
            }
            .task { await model.onAppear() }
        }
    }

    private var specialtyList: some View {
        List(model.specialties) { specialty in
            Button { Task { await model.select(specialty) } } label: {
                Label(specialty.name, systemImage: specialty.symbol)
            }
        }
    }

    private var doctorList: some View {
        List(model.doctors) { doctor in
            Button { Task { await model.select(doctor) } } label: {
                VStack(alignment: .leading) {
                    Text(doctor.name).font(.headline)
                    Text(doctor.crm).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var slotPicker: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(model.days, id: \.day) { entry in
                        let selected = entry.day == model.selectedDay
                        Button { model.selectedDay = entry.day } label: {
                            VStack {
                                Text(entry.day, format: .dateTime.weekday(.abbreviated))
                                Text(entry.day, format: .dateTime.day()).font(.title2.bold())
                            }
                            .padding(10)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.1), in: .rect(cornerRadius: 12))
                            .foregroundStyle(selected ? .white : .primary)
                        }
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.horizontal)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                ForEach(model.slotsForSelectedDay) { slot in
                    Button { model.select(slot) } label: {
                        Label(slot.start.formatted(date: .omitted, time: .shortened), systemImage: slot.isTelemedicine ? "video" : "building.2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("\(slot.start.formatted(date: .omitted, time: .shortened)), \(slot.isTelemedicine ? "teleconsulta" : "presencial")")
                }
            }
            .padding()
            Spacer()
        }
    }

    private var confirmation: some View {
        Form {
            if let doctor = model.selectedDoctor, let slot = model.selectedSlot {
                LabeledContent("Especialidade", value: model.selectedSpecialty?.name ?? "")
                LabeledContent("Profissional", value: doctor.name)
                LabeledContent("Data", value: slot.start.formatted(date: .complete, time: .shortened))
                LabeledContent("Modalidade", value: slot.isTelemedicine ? "Teleconsulta" : "Presencial")
            }
            Button("Confirmar agendamento") { Task { await model.confirm() } }.disabled(model.isLoading)
        }
    }

    private var success: some View {
        ContentUnavailableView {
            Label("Consulta agendada!", systemImage: "checkmark.seal.fill")
        } description: {
            Text(model.booked.map { "\($0.doctor.name) • \($0.slot.start.formatted(date: .abbreviated, time: .shortened))" } ?? "")
        } actions: {
            Button("Agendar outra", action: model.restart)
        }
    }
}

public struct MyAppointmentsView: View {
    @State private var model: MyAppointmentsViewModel

    public init(api: HealthAPI) {
        _model = State(initialValue: MyAppointmentsViewModel(api: api))
    }

    public var body: some View {
        NavigationStack {
            List(model.upcoming) { appointment in
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.specialty.name).font(.headline)
                    Text(appointment.doctor.name)
                    Text(appointment.slot.start.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(.secondary)
                }
                .swipeActions {
                    if model.canCancel(appointment) {
                        Button("Cancelar", role: .destructive) { Task { await model.cancel(appointment) } }
                    }
                }
            }
            .overlay { if model.upcoming.isEmpty { ContentUnavailableView("Nenhuma consulta marcada", systemImage: "calendar") } }
            .navigationTitle("Minhas consultas")
            .refreshable { await model.load() }
            .task { await model.load() }
        }
    }
}

#Preview { ScheduleFlowView(api: InMemoryHealthAPI(latencyMs: 0)) }
#endif
