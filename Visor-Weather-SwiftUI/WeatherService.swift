//
//  WeatherService.swift
//  Visor-Weather-SwiftUI
//
//  Created by Jaimin Raval on 22/09/26.
//

import Foundation

enum WeatherError: LocalizedError {
    case invalidAPIKey
    case cityNotFound
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: "Invalid API key. New keys can take a couple of hours to activate."
        case .cityNotFound: "City not found."
        case .server(let code): "Weather service error (\(code))."
        }
    }
}

struct WeatherService: Sendable {
    let apiKey: String
    private static let baseURL = URL(string: "https://api.openweathermap.org")!

    // MARK: Current weather (free)

    func currentWeather(city: String) async throws -> CurrentWeather {
        let response: OWM.CurrentWeatherResponse = try await get("data/2.5/weather", query: ["q": city])
        return CurrentWeather(
            city: response.name,
            temperature: response.main.temp,
            description: response.weather.first?.description ?? "",
            latitude: response.coord.lat,
            longitude: response.coord.lon
        )
    }

    // MARK: Daily forecast (free)

    /// Turns the free 5-day / 3-hour forecast into one row per day.
    /// A day's temp is the average of its 3-hourly readings; its icon is taken from the reading closest to midday.
    func dailyForecast(city: String) async throws -> [DailyForecast] {
        let response: OWM.ForecastResponse = try await get("data/2.5/forecast", query: ["q": city])

        let timeZone = TimeZone(secondsFromGMT: response.city.timezone) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let readingsByDay = Dictionary(grouping: response.list) { item in
            calendar.startOfDay(for: Date(timeIntervalSince1970: item.dt))
        }

        return readingsByDay
            .compactMap { day, readings -> DailyForecast? in
                // The last day is usually cut off mid-way; skip it if there's less than half a day of data.
                guard readings.count >= 4 || calendar.isDateInToday(day) else { return nil }

                let average = readings.map(\.main.temp).reduce(0, +) / Double(readings.count)
                let noon = day.addingTimeInterval(12 * 60 * 60).timeIntervalSince1970
                let midday = readings.min { abs($0.dt - noon) < abs($1.dt - noon) }

                return DailyForecast(
                    date: day,
                    averageTemp: average,
                    iconCode: midday?.weather.first?.icon ?? "03d",
                    timeZone: timeZone
                )
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: Optional: real 7-day forecast (One Call API 3.0)
    //
    // The free tier has no 7-day endpoint. One Call 3.0 does, and its first 1,000 calls/day are free,
    // but it needs the separate "One Call by Call" subscription (a payment card is required).
    // To switch, see the comment in WeatherViewModel.load(city:).

    func sevenDayForecast(latitude: Double, longitude: Double) async throws -> [DailyForecast] {
        let response: OWM.OneCallResponse = try await get(
            "data/3.0/onecall",
            query: [
                "lat": "\(latitude)",
                "lon": "\(longitude)",
                "exclude": "current,minutely,hourly,alerts"
            ]
        )
        let timeZone = TimeZone(secondsFromGMT: response.timezoneOffset) ?? .current

        return response.daily.map { day in
            DailyForecast(
                date: Date(timeIntervalSince1970: day.dt),
                averageTemp: (day.temp.morn + day.temp.day + day.temp.eve + day.temp.night) / 4,
                iconCode: day.weather.first?.icon ?? "03d",
                timeZone: timeZone
            )
        }
    }

    // MARK: Networking

    private func get<T: Decodable>(_ path: String, query: [String: String]) async throws -> T {
        let queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) } + [
            URLQueryItem(name: "units", value: "metric"),   // °C. Use "imperial" for °F.
            URLQueryItem(name: "appid", value: apiKey)
        ]
        let url = Self.baseURL.appending(path: path).appending(queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(from: url)

        switch (response as? HTTPURLResponse)?.statusCode ?? 0 {
        case 200..<300: break
        case 401: throw WeatherError.invalidAPIKey
        case 404: throw WeatherError.cityNotFound
        case let code: throw WeatherError.server(statusCode: code)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
