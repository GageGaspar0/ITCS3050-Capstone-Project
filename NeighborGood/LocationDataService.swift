//
//  LocationDataService.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/9/25.
//
import Foundation

class LocationDataService {
    static let shared = LocationDataService()
    private var locations: [CrimeLocation] = []
    private var uniqueLocations: Set<String> = []
    private var streetNameToLocation: [String: CrimeLocation] = [:]
    
    private init() {
        loadLocationData()
    }
    
    private func loadLocationData() {
        guard let path = Bundle.main.path(forResource: "cmpd_crime_data", ofType: "geojson") else {
            print("Error: GeoJSON file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let features = json["features"] as? [[String: Any]] else {
                print("Error parsing JSON structure")
                return
            }
            
            for feature in features {
                if let properties = feature["properties"] as? [String: Any],
                   let location = properties["LOCATION"] as? String,
                   let city = properties["CITY"] as? String,
                   let state = properties["STATE"] as? String {
                    
                    if !uniqueLocations.contains(location) {
                        uniqueLocations.insert(location)
                        let crimeLocation = CrimeLocation(location: location, city: city, state: state)
                        locations.append(crimeLocation)
                        
                        if let streetName = extractStreetName(from: location) {
                            streetNameToLocation[streetName] = crimeLocation
                        }
                    }
                }
            }
            
            print("Loaded \(locations.count) unique crime locations")
        } catch {
            print("Error loading or parsing GeoJSON file: \(error)")
        }
    }
    
    private func extractStreetName(from address: String) -> String? {
        let pattern = "^\\d+\\s+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: address.utf16.count)
            let streetName = regex.stringByReplacingMatches(in: address, range: range, withTemplate: "")
            return streetName.isEmpty ? nil : streetName
        }
        return address
    }
    
    func searchLocations(query: String) -> [CrimeLocation] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        
        var matchingStreetNames = Set<String>()
        var results: [CrimeLocation] = []
        
        for location in locations {
            if let streetName = extractStreetName(from: location.location),
               streetName.lowercased().contains(lowercasedQuery) {
                if !matchingStreetNames.contains(streetName) {
                    matchingStreetNames.insert(streetName)
                    results.append(location)
                }
            }
        }
        
        return results
    }
    
    func getStreetNameForDisplay(from location: CrimeLocation) -> String {
        return extractStreetName(from: location.location) ?? location.location
    }
}
