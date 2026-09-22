//
//  ContentView.swift
//  Visor-Weather-SwiftUI
//
//  Created by Jaimin Raval on 21/09/26.
//

import SwiftUI
import CoreData
import SwiftUI

struct WeatherView: View {
    let city: String
    @State private var viewModel: WeatherViewModel

    init(city: String, viewModel: WeatherViewModel) {
        self.city = city
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .tint(.white)

            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't Load Weather", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.load(city: city) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .foregroundStyle(.white)

            case .loaded(let current, let daily):
                VStack(spacing: 0) {
                    CurrentWeatherHeader(weather: current)
                        .padding(.vertical, 32)

                    forecastList(daily)
                }
            }
        }
        .task {
            if case .loading = viewModel.state {
                await viewModel.load(city: city)
            }
        }
    }

    private func forecastList(_ daily: [DailyForecast]) -> some View {
        List {
            Section {
                ForEach(daily) { day in
                    DailyForecastRow(forecast: day)
                        .listRowBackground(Color.white.opacity(0.15))
                }
            } header: {
                Text("\(daily.count)-Day Forecast")
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.load(city: city) }
    }
}

// MARK: - Header

private struct CurrentWeatherHeader: View {
    let weather: CurrentWeather

    var body: some View {
        VStack(spacing: 4) {
            Text(weather.city)
                .font(.largeTitle)

            Text(weather.temperature.degrees)
                .font(.system(size: 96, weight: .thin))

            Text(weather.description.capitalized)
                .font(.title3)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Row

private struct DailyForecastRow: View {
    let forecast: DailyForecast

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: WeatherIcon.symbol(for: forecast.iconCode))
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .frame(width: 36)

            Text(forecast.averageTemp.degrees)
                .font(.title3.monospacedDigit())

            Spacer()

            Text(forecast.dayName)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Helpers

/// Maps OpenWeatherMap icon codes (https://openweathermap.org/weather-conditions) to SF Symbols.
enum WeatherIcon {
    static func symbol(for code: String) -> String {
        switch code {
        case "01d": "sun.max.fill"
        case "01n": "moon.stars.fill"
        case "02d": "cloud.sun.fill"
        case "02n": "cloud.moon.fill"
        case "03d", "03n": "cloud.fill"
        case "04d", "04n": "smoke.fill"
        case "09d", "09n": "cloud.drizzle.fill"
        case "10d": "cloud.sun.rain.fill"
        case "10n": "cloud.moon.rain.fill"
        case "11d", "11n": "cloud.bolt.rain.fill"
        case "13d", "13n": "cloud.snow.fill"
        case "50d", "50n": "cloud.fog.fill"
        default: "cloud.fill"
        }
    }
}

extension Double {
    /// 23.6 → "24°"
    var degrees: String { "\(Int(rounded()))°" }
}

// MARK: - Preview (mock data, no network)

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let icons = ["01d", "02d", "10d", "04d", "11d", "01d", "03d"]
    let temps: [Double] = [18, 17, 14, 15, 13, 19, 16]

    let daily = icons.indices.map { i in
        DailyForecast(
            date: calendar.date(byAdding: .day, value: i, to: today)!,
            averageTemp: temps[i],
            iconCode: icons[i],
            timeZone: .current
        )
    }

    WeatherView(
        city: "Ahmedabad",
        viewModel: WeatherViewModel(
            service: WeatherService(apiKey: ""),
            state: .loaded(
                current: CurrentWeather(city: "London", temperature: 18.4, description: "scattered clouds",
                                        latitude: 51.51, longitude: -0.13),
                daily: daily
            )
        )
    )
}
