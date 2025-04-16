# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Generate Xcode project: `./generate_project.sh`
- Open in Xcode: `xed LEDMESSENGER.xcodeproj`
- Run Tests: Use Xcode test navigator or `xcodebuild test -project LEDMESSENGER.xcodeproj -scheme LEDMESSENGER -destination 'platform=iOS Simulator,name=iPhone 14'`
- Run Single Test: `xcodebuild test -project LEDMESSENGER.xcodeproj -scheme LEDMESSENGER -only-testing:LEDMESSENGERTests/[TestClass]/[testMethod]`

## Code Style Guidelines
- **Swift Version**: Swift 5.0+
- **Architecture**: MVVM with clear separation between Models, Views, ViewModels, and Services
- **Indentation**: 4 spaces
- **Imports**: Foundation first, then frameworks alphabetically
- **Types**: Use Swift native types, prefer protocols for interfaces, use proper access control
- **Naming**: CamelCase for types, lowerCamelCase for variables/functions
- **Error Handling**: Use custom error types inheriting from LocalizedError
- **Documentation**: Use doc comments (/**) for all public interfaces
- **Cross-Platform**: Use conditional compilation (#if os(iOS)/os(macOS)) for platform-specific code
- **SwiftUI**: Prefer composition over inheritance, extract reusable components