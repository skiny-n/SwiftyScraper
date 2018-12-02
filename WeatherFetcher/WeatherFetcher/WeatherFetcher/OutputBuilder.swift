//
//  OutputBuilder.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Helper that builds weather overview outputs.
 */
struct OutputBuilder {
    
    /** Measurement formatter used for formatting temperature and wind speed. */
    private static let measurementFormatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.numberFormatter.maximumFractionDigits = 1
        f.numberFormatter.minimumFractionDigits = 1
        f.numberFormatter.roundingMode = .ceiling
        return f
    }()
    
    /** Creates a weather overview output suited for command line interface. */
    static func createOutput(from forecasts: [DayForecast], units: ForecastUnits) -> (header: String, rows: [String]) {
        // Build rows
        let rows: [String] = forecasts.map({ forecast in
            let items: [String] = [
                forecast.outputDate,
                String(forecast.phrase.split(separator: " ").last ?? ""),
                convertTemperatureToCurrentLocale(forecast.temperature, units: units),
                convertTemperatureToCurrentLocale(forecast.feelsLike, units: units),
                "\(forecast.precipPerc)\(units.percent)",
                "\(forecast.humidityPerc)\(units.percent)",
                "\(forecast.windDirection) \(convertSpeedToCurrentLocale(forecast.windSpeed, units: units))"
            ]
            return items.joined(separator: "\t|\t")
        })
        // Header
        let header: String = [
            "Date",
            "Description",
            "Temperature",
            "Feels like",
            "Precipitation",
            "Humidity",
            "Wind speed"
        ].joined(separator: "\t|\t")
        return (header, rows)
    }
    
    // MARK: Private
    
    /** Converts and formats given remperature for current locale. */
    private static func convertTemperatureToCurrentLocale(_ temperature: Double, units: ForecastUnits) -> String {
        let unit: UnitTemperature = {
            switch units.temperature.lowercased() {
            case "f": return UnitTemperature.fahrenheit
            case "c": return UnitTemperature.celsius
            case "k": return UnitTemperature.kelvin
            default:  return UnitTemperature.fahrenheit
            }
        }()
        let measurement = Measurement(value: temperature, unit: unit)
        return OutputBuilder.measurementFormatter.string(from: measurement)
    }
    
    /** Converts and formats given speed for current locale. */
    private static func convertSpeedToCurrentLocale(_ speed: Double, units: ForecastUnits) -> String {
        let unit: UnitSpeed = {
            switch units.speed.lowercased() {
            case "mph", "mi/h": return UnitSpeed.milesPerHour
            case "kph", "km/h": return UnitSpeed.kilometersPerHour
            case "mps", "m/s":  return UnitSpeed.metersPerSecond
            default:            return UnitSpeed.milesPerHour
            }
        }()
        let measurement = Measurement(value: speed, unit: unit)
        return OutputBuilder.measurementFormatter.string(from: measurement)
    }
    
}
