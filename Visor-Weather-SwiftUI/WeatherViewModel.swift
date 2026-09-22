//
//  WeatherViewModel.swift
//  Visor-Weather-SwiftUI
//
//  Created by Jaimin Raval on 22/09/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    enum State {
        case loading
        case loaded(current: CurrentWeather, daily: [DailyForecast])
        case failed(message: String)
    }

    private(set) var state: State
    private let service: WeatherService

    init(service: WeatherService, state: State = .loading) {
        self.service = service
        self.state = state
    }

    func load(city: String) async {
        // Keep old data on screen during pull-to-refresh; show the spinner again when retrying after an error.
        if case .failed = state { state = .loading }

        do {
            async let current = service.currentWeather(city: city)
            async let daily = service.dailyForecast(city: city)
            let (currentWeather, forecast) = try await (current, daily)

            // Using One Call 3.0 for a true 7-day forecast? Replace the lines above with:
            // let currentWeather = try await service.currentWeather(city: city)
            // let forecast = try await service.sevenDayForecast(latitude: currentWeather.latitude,
            //                                                   longitude: currentWeather.longitude)

            state = .loaded(current: currentWeather, daily: Array(forecast.prefix(7)))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
