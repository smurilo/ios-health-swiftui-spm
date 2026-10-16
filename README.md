# Agenda Saúde — SwiftUI + SPM modular

App de **agendamento de consultas** para uma rede de clínicas: escolha da especialidade, do profissional, do dia e do horário (presencial ou teleconsulta), confirmação e gestão das consultas marcadas. 100% **SwiftUI**, com o código organizado em **módulos Swift Package Manager**.

> Segmento: **Saúde / Hospitalar**

## Stack
Swift 5.9 • **SwiftUI** (NavigationStack, TabView, LazyVGrid, ContentUnavailableView, swipe actions, `#Preview`) • **Observation (`@Observable`)** • **MVVM** • async/await + `actor` • **Swift Package Manager** (módulos em camadas) • XCTest • XcodeGen

## Módulos

```
Package.swift
├── HealthDomain          modelos + SchedulingRules (antecedência mínima, 1 consulta futura por especialidade,
│                         cancelamento com 24h, agrupamento por dia)        ← não depende de nada
├── HealthData            HealthAPI (protocolo) + InMemoryHealthAPI (actor)  ← depende do Domain
└── AppointmentsFeature   ScheduleViewModel, MyAppointmentsViewModel (@Observable) + Views SwiftUI
App/                      casca mínima: TabView que injeta a HealthAPI
```
O SPM **impede dependências na direção errada** (o Domain não enxerga a UI) e permite compilar e testar cada módulo isoladamente.

### Destaques
- **Fluxo em etapas** controlado por um enum (`Step`) no ViewModel, com animação entre os passos e botão "Voltar".
- **Regras de negócio puras e testadas**: as mensagens de erro vêm do domínio (`LocalizedError`).
- **Concorrência segura**: backend simulado como `actor`, ViewModels `@MainActor`.
- **Datas e calendário injetáveis**: testes determinísticos com fuso `America/Maceio` e "agora" controlado.
- **Acessibilidade**: rótulos descritivos nos horários (presencial/teleconsulta) e traits de seleção.

## Como executar
```bash
brew install xcodegen && xcodegen && open AgendaSaude.xcodeproj   # iOS 17+
swift test                                                         # domínio + ViewModels (macOS ou Linux)
```
