//
//  ResultsViewController.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/9/25.
//
//
//  ResultsViewController.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/9/25.
//
import Foundation
import UIKit

struct CrimeIncident: Decodable {
    let attributes: CrimeAttributes
}

struct CrimeAttributes: Decodable {
    let OBJECTID: Int
    let CMPDID: String
    let LOCATION: String?
    let OFFENSE_DESCRIPTION: String?
    let REPORTED_DATE: Int?
    
    var reportedDate: Date? {
        guard let timestamp = REPORTED_DATE else { return nil }
        return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
    }
}

struct CrimeResponse: Decodable {
    let features: [CrimeIncident]
}

class ResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private enum TableSection: Int, CaseIterable {
        case summary = 0
        case yearlyBreakdown = 1
        case incidents = 2
        
        var title: String {
            switch self {
            case .summary: return "Summary"
            case .yearlyBreakdown: return "Yearly Breakdown"
            case .incidents: return "Incident List"
            }
        }
    }
    
    var searchFirstLetter: String = ""
    
    @IBOutlet weak var searchResultsTableView: UITableView!
    var searchAddress: String = ""
    
    private var crimeRecords: [CrimeRecord] = []
    private var crimeStatistics: CrimeAnalysisService.CrimeStatistics?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Crime Reports"
        
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CrimeRecordCell")
        
        if !searchAddress.isEmpty {
            print("Searching for address: \(searchAddress)")
            fetchCrimeData(for: searchAddress)
        } else {
            print("Search address is empty")
        }
    }
    
    func displayError(_ message: String) {
        crimeRecords = []
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        
        print("Error displayed: \(message)")
        searchResultsTableView.reloadData()
    }
    
    func fetchCrimeData(for address: String) {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        guard let firstLetter = address.first?.lowercased() else {
            activityIndicator.stopAnimating()
            displayError("Invalid address")
            return
        }
        
        let urlString = "https://gagegaspar0.github.io/cmpd-data/crime_data_\(firstLetter).json"
        
        guard let url = URL(string: urlString) else {
            activityIndicator.stopAnimating()
            print("Invalid URL: \(urlString)")
            displayError("Invalid URL")
            return
        }
        
        print("Attempting API connection for \(urlString)")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self?.displayError("Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Response status code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        self?.displayError("Server error: \(httpResponse.statusCode)")
                        return
                    }
                }
                
                guard let data = data else {
                    print("No data received from API")
                    self?.displayError("No data received")
                    return
                }
                
                print("Received data of size: \(data.count) bytes")
                
                if let dataPreview = String(data: data.prefix(100), encoding: .utf8),
                   dataPreview.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                    print("Received HTML instead of JSON data")
                    self?.displayError("Invalid response from server")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let allRecords = try decoder.decode([CrimeRecord].self, from: data)
                    
                    print("Decoded \(allRecords.count) total crime records")
                    
                    let searchTerm = address.uppercased()
                    let relevantRecords = allRecords.filter { record in
                        return record.location.uppercased().contains(searchTerm)
                    }
                    
                    print("Found \(relevantRecords.count) matching records for address: \(address)")
                    
                    self?.crimeRecords = relevantRecords
                    // Add this line to analyze the data:
                    self?.crimeStatistics = CrimeAnalysisService.analyze(crimeRecords: relevantRecords)
                    self?.searchResultsTableView.reloadData()
                } catch {
                    print("JSON parsing error: \(error)")
                    self?.displayError("Failed to parse data: \(error.localizedDescription)")
                    
                    if let dataPreview = String(data: data.prefix(200), encoding: .utf8) {
                        print("Raw data preview: \(dataPreview)")
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return crimeRecords.isEmpty ? 1 : TableSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if crimeRecords.isEmpty {
            return nil
        }
        return TableSection(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if crimeRecords.isEmpty {
            return 1
        }
        
        guard let tableSection = TableSection(rawValue: section) else {
            return 0
        }
        
        switch tableSection {
        case .summary:
            return 3
        case .yearlyBreakdown:
            return crimeStatistics?.incidentsPerYear.count ?? 0
        case .incidents:
            return crimeRecords.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if crimeRecords.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CrimeRecordCell", for: indexPath)
            cell.textLabel?.text = "No crime reports found for this location"
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CrimeRecordCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        
        guard let tableSection = TableSection(rawValue: indexPath.section),
              let stats = crimeStatistics else {
            return cell
        }
        
        switch tableSection {
        case .summary:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Total Incidents: \(stats.totalIncidents)"
            case 1:
                cell.textLabel?.text = "Average Per Year: \(String(format: "%.1f", stats.averageIncidentsPerYear))"
            case 2:
                cell.textLabel?.text = "Trend: \(stats.trendDescription)"
                cell.textLabel?.textColor = stats.isTrendIncreasing ? .red : .green
            default:
                cell.textLabel?.text = ""
            }
            cell.selectionStyle = .none
            
        case .yearlyBreakdown:
            let sortedYears = stats.incidentsPerYear.keys.sorted()
            if indexPath.row < sortedYears.count {
                let year = sortedYears[indexPath.row]
                let count = stats.incidentsPerYear[year] ?? 0
                cell.textLabel?.text = "\(year): \(count) incidents"
            }
            cell.selectionStyle = .none
            
        case .incidents:
            let incident = crimeRecords[indexPath.row]
            let formattedDate = CrimeAnalysisService.formatDate(incident.dateReported)
            cell.textLabel?.text = "\(incident.highestNibrsDescription) (\(formattedDate))"
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = TableSection(rawValue: indexPath.section),
              section == .incidents,
              !crimeRecords.isEmpty,
              indexPath.row < crimeRecords.count else {
            return
        }
        
        let incident = crimeRecords[indexPath.row]
        showIncidentDetails(incident)
    }
    
    func showIncidentDetails(_ incident: CrimeRecord) {
        let alertController = UIAlertController(
            title: "Incident Details",
            message: """
            Type: \(incident.highestNibrsDescription)
            Date: \(CrimeAnalysisService.formatDate(incident.dateReported))
            Location: \(incident.location)
            Type: \(incident.locationTypeDescription)
            """,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Close", style: .default))
        present(alertController, animated: true)
    }
}
