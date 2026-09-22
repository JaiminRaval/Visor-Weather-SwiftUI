//
//  WeatherModel.swift
//  Visor-Weather-SwiftUI
//
//  Created by Jaimin Raval on 22/09/26.
//

import Foundation

// MARK: - App models (what the UI works with)

struct CurrentWeather {
    let city: String
    let temperature: Double
    let description: String
    let latitude: Double    // only needed for the optional One Call 7-day request
    let longitude: Double
}

struct DailyForecast: Identifiable {
    let date: Date
    let averageTemp: Double
    let iconCode: String      // OpenWeatherMap icon code, e.g. "10d"
    let timeZone: TimeZone    // the city's time zone, so day names are right for that city

    var id: Date { date }

    var dayName: String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        if calendar.isDateInToday(date) { return "Today" }

        var style = Date.FormatStyle.dateTime.weekday(.wide)
        style.timeZone = timeZone
        return date.formatted(style)
    }
}

// MARK: - OpenWeatherMap API responses

enum OWM {
    /// GET /data/2.5/weather  (free)
    struct CurrentWeatherResponse: Decodable {
        let name: String
        let coord: Coord
        let main: Main
        let weather: [Condition]
    }

    /// GET /data/2.5/forecast  (free — 5 days, one reading every 3 hours)
    struct ForecastResponse: Decodable {
        let list: [Item]
        let city: City

        struct Item: Decodable {
            let dt: TimeInterval
            let main: Main
            let weather: [Condition]
        }

        struct City: Decodable {
            let timezone: Int   // offset from UTC in seconds
        }
    }

    /// GET /data/3.0/onecall  (optional — see WeatherService.sevenDayForecast)
    struct OneCallResponse: Decodable {
        let timezoneOffset: Int
        let daily: [Day]

        struct Day: Decodable {
            let dt: TimeInterval
            let temp: Temp
            let weather: [Condition]
        }

        struct Temp: Decodable {
            let morn, day, eve, night: Double
        }
    }

    struct Coord: Decodable {
        let lat: Double
        let lon: Double
    }

    struct Main: Decodable {
        let temp: Double
    }

    struct Condition: Decodable {
        let description: String
        let icon: String
    }
}
