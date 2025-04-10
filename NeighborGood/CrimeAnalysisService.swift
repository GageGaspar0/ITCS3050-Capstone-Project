//
//  CrimeAnalysisService.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/10/25.
//

//
//  CrimeAnalysisService.swift
//  NeighborGood
//
//  Created on 4/10/25.
//

import Foundation

class CrimeAnalysisService {
    
    struct CrimeStatistics {
        let totalIncidents: Int
        let incidentsPerYear: [String: Int]
        let averageIncidentsPerYear: Double
        let trendDescription: String
        let isTrendIncreasing: Bool
    }
    
    static func analyze(crimeRecords: [CrimeRecord]) -> CrimeStatistics {
        let totalIncidents = crimeRecords.count
        
        var incidentsPerYear = [String: Int]()
        for record in crimeRecords {
            incidentsPerYear[record.year, default: 0] += 1
        }
        
        let uniqueYearsWithData = incidentsPerYear.filter { $0.value > 0 }.count
        let averageIncidentsPerYear = uniqueYearsWithData > 0 ? Double(totalIncidents) / Double(uniqueYearsWithData) : 0
        
        let trend = analyzeTrend(incidentsPerYear: incidentsPerYear)
        
        return CrimeStatistics(
            totalIncidents: totalIncidents,
            incidentsPerYear: incidentsPerYear,
            averageIncidentsPerYear: averageIncidentsPerYear,
            trendDescription: trend.description,
            isTrendIncreasing: trend.isIncreasing
        )
    }
    
    private static func analyzeTrend(incidentsPerYear: [String: Int]) -> (description: String, isIncreasing: Bool) {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        var yearsSorted = incidentsPerYear.keys.compactMap { Int($0) }.sorted()
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
    
        if yearCounts.count >= 2 {
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
        
        return ("Insufficient data for trend analysis", false)
    }
    
    private static func calculatePercentChange(from startValue: Int, to endValue: Int) -> Double {
        guard startValue != 0 else { return 100.0 } // Avoid division by zero
        return Double(endValue - startValue) / Double(startValue) * 100.0
    }
    
    static func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString // Return original if can't parse
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: date)
    }
}
