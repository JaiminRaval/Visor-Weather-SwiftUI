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
    // Get your key  after signup/login at https://home.openweathermap.org/api_keys
    private let apiKey = "YOUR_API_KEY"
    private let city = "London"

    
    var body: some Scene {
        WindowGroup {
            WeatherView(
                city: city,
                viewModel: WeatherViewModel(service: WeatherService(apiKey: apiKey))
            )

                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
