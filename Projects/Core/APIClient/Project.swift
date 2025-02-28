import ProjectDescriptionHelpers
import ProjectDescription
import DependencyPlugin
import EnvPlugin

let project = Project.framework(
    name: "APIClient",
    platforms: [.iOS, .watchOS],
    targets: [.unitTest, .dynamicFramework],
    internalDependencies: [
        .Shared.iOS,
        .Shared.watchOS
    ],
    externalDependencies: [
        
    ],
    interfaceDependencies: [
        
    ],
    testingDependencies: [],
    demoDependencies: []
)
