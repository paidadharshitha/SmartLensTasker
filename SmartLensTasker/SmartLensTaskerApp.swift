//
//  SmartLensTaskerApp.swift
//  SmartLensTasker
//
//  Created by DHARSHITHA PAIDA on 17/01/26.
//

import SwiftUI
import SwiftData // 1. Deenni import cheyali

@main
struct SmartLensTaskerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TaskItem.self) // 2. Ee line ni kachitanga ikkade add cheyali
    }
}
