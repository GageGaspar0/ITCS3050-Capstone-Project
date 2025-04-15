//
//  CrimeAnalysisService.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/10/25.
//

import Foundation

class CrimeAnalysisService {
    
    struct CrimeStatistics {
        let totalIncidents: Int
        let incidentsPerYear: [String: Int]
        let averageIncidentsPerYear: Double
        let trendDescription: String
        let isTrendIncreasing: Bool
        
        let isSixYearTrendIncreasing: Bool
        let isThreeYearTrendIncreasing: Bool
    }
    
    static func analyze(crimeRecords: [CrimeRecord]) -> CrimeStatistics {
        
        var incidentsPerYear = [String: Int]()
        
        var incidentsForAverage = [String: Int]()
        
        for record in crimeRecords {
            
            incidentsPerYear[record.year, default: 0] += 1
            
           
            if record.year != "2025" {
                incidentsForAverage[record.year, default: 0] += 1
            }
        }
        
       
        let totalIncidents = incidentsPerYear.values.reduce(0, +)
        
       
        let totalForAverage = incidentsForAverage.values.reduce(0, +)
        let uniqueYearsForAverage = incidentsForAverage.keys.count
        let averageIncidentsPerYear = uniqueYearsForAverage > 0
            ? Double(totalForAverage) / Double(uniqueYearsForAverage)
            : 0
        
        
        let trend = analyzeTrend(incidentsPerYear: incidentsPerYear)
        
       
        let sixYearTrend = isCrimeIncreasingOverLastSixYears(incidentsPerYear: incidentsPerYear)
        let threeYearTrend = isCrimeIncreasingOverLastThreeYears(incidentsPerYear: incidentsPerYear)
        
        return CrimeStatistics(
            totalIncidents: totalIncidents,
            incidentsPerYear: incidentsPerYear,
            averageIncidentsPerYear: averageIncidentsPerYear,
            trendDescription: trend.description,
            isTrendIncreasing: trend.isIncreasing,
            isSixYearTrendIncreasing: sixYearTrend,
            isThreeYearTrendIncreasing: threeYearTrend
        )
    }
    
    private static func analyzeTrend(incidentsPerYear: [String: Int]) -> (description: String, isIncreasing: Bool) {
       
        let yearsSorted = incidentsPerYear.keys.compactMap { Int($0) }.sorted()
        let recentYears = Array(yearsSorted.suffix(5))
        
        if recentYears.count < 2 {
            return ("Insufficient data to determine trend", false)
        }
        
        var yearCounts: [(year: Int, count: Int)] = []
        for year in recentYears {
            if let count = incidentsPerYear[String(year)] {
                yearCounts.append((year: year, count: count))
            }
        }
        
        yearCounts.sort { $0.year < $1.year }
        
        guard yearCounts.count >= 2 else {
            return ("Insufficient data for trend analysis", false)
        }
        
        let firstYear = yearCounts.first!
        let lastYear = yearCounts.last!
        let percentChange = calculatePercentChange(from: firstYear.count, to: lastYear.count)
        let isIncreasing = lastYear.count > firstYear.count
        
        if abs(percentChange) < 5 {
            return ("Crime incidents have remained relatively stable over the last \(yearCounts.count) years", false)
        } else if isIncreasing {
            return ("Crime incidents have increased by approximately \(Int(percentChange))% from \(firstYear.year) to \(lastYear.year)", true)
        } else {
            return ("Crime incidents have decreased by approximately \(Int(abs(percentChange)))% from \(firstYear.year) to \(lastYear.year)", false)
        }
    }
    
    static func isCrimeIncreasingOverLastSixYears(incidentsPerYear: [String: Int]) -> Bool {
       
        let yearsRange = 2019...2024
        let filtered = incidentsPerYear.compactMap { (yearStr, count) -> (Int, Int)? in
            guard let y = Int(yearStr), yearsRange.contains(y) else { return nil }
            return (y, count)
        }.sorted { $0.0 < $1.0 }
        
        guard filtered.count >= 2 else { return false }
        return filtered.last!.1 > filtered.first!.1
    }

    static func isCrimeIncreasingOverLastThreeYears(incidentsPerYear: [String: Int]) -> Bool {
       
        let yearsRange = 2022...2024
        let filtered = incidentsPerYear.compactMap { (yearStr, count) -> (Int, Int)? in
            guard let y = Int(yearStr), yearsRange.contains(y) else { return nil }
            return (y, count)
        }.sorted { $0.0 < $1.0 }
        
        guard filtered.count >= 2 else { return false }
        return filtered.last!.1 > filtered.first!.1
    }
    
    private static func calculatePercentChange(from startValue: Int, to endValue: Int) -> Double {
        guard startValue != 0 else {
            return 100.0
        }
        return Double(endValue - startValue) / Double(startValue) * 100.0
    }
    
    static func formatDate(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

    guard let date = inputFormatter.date(from: dateString) else {
        return dateString
    }

    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "yyyy-MM-dd"
    return outputFormatter.string(from: date)
}
}
