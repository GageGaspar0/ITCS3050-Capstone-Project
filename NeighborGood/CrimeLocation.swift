//
//  CrimeLocation.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/9/25.
//

import Foundation

struct CrimeLocation {
    let location: String
    let city: String
    let state: String
    
    var formattedAddress: String {
        return "\(location), \(city), \(state)"
    }
}
