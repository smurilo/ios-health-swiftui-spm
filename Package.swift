// swift-tools-version:5.9
// The app is a thin shell; all code lives in this package, split into layered modules.
// SPM enforces the dependency direction: Feature → Data → Domain (Domain depends on nothing).
import PackageDescription

let package = Package(
    name: "AgendaSaude",
    defaultLocalization: "pt",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AppointmentsFeature", targets: ["AppointmentsFeature"]),
    ],
    targets: [
        .target(name: "HealthDomain"),
        .target(name: "HealthData", dependencies: ["HealthDomain"]),
        .target(name: "AppointmentsFeature", dependencies: ["HealthDomain", "HealthData"]),
        .testTarget(name: "HealthDomainTests", dependencies: ["HealthDomain"]),
        .testTarget(name: "AppointmentsFeatureTests", dependencies: ["AppointmentsFeature", "HealthData"]),
    ]
)
