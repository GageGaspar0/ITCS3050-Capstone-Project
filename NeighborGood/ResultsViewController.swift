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
    
    var searchFirstLetter: String = ""
    
    @IBOutlet weak var searchResultsTableView: UITableView!
    var searchAddress: String = ""
    
    private var crimeRecords: [CrimeRecord] = []
    
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
        
        print("📡 Attempting API connection for \(urlString)")
        
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
                
                print("✅ Received data of size: \(data.count) bytes")
                
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if crimeRecords.isEmpty {
            return 1
        }
        return crimeRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CrimeRecordCell", for: indexPath)
        
        if crimeRecords.isEmpty {
            cell.textLabel?.text = "No crime reports found for this location"
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            return cell
        }
        
        let incident = crimeRecords[indexPath.row]
        
        cell.textLabel?.text = incident.location
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !crimeRecords.isEmpty {
            let incident = crimeRecords[indexPath.row]
            showIncidentDetails(incident)
        }
    }
    
    func showIncidentDetails(_ incident: CrimeRecord) {
        let alertController = UIAlertController(
            title: incident.highestNibrsDescription,
            message: """
            Location: \(incident.location)
            Reported: \(incident.dateReported)
            Type: \(incident.locationTypeDescription)
            """,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
