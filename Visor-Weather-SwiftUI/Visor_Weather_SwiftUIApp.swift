//
//  Visor_Weather_SwiftUIApp.swift
//  Visor-Weather-SwiftUI
//
//  Created by Jaimin Raval on 21/09/26.
//

import SwiftUI
import CoreData

@main
struct Visor_Weather_SwiftUIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
