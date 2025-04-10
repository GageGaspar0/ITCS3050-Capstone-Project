//
//  ViewController.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/2/25.
//

import UIKit
import MapKit

struct CrimeRecord: Decodable {
    let year: String
    let location: String
    let state: String?
    let zip: String?
    let dateReported: String
    let locationTypeDescription: String
    let highestNibrsDescription: String

    enum CodingKeys: String, CodingKey {
        case year = "YEAR"
        case location = "LOCATION"
        case state = "STATE"
        case zip = "ZIP"
        case dateReported = "DATE_REPORTED"
        case locationTypeDescription = "LOCATION_TYPE_DESCRIPTION"
        case highestNibrsDescription = "HIGHEST_NIBRS_DESCRIPTION"
    }
}

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var neighborhoodSearchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    
    private var locations: [String] = []
    private var filteredLocations: [String] = []
    private var currentAPIFirstLetter: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        neighborhoodSearchBar.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        resultsTableView.isHidden = true
        neighborhoodSearchBar.returnKeyType = .search
        loadLocations()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func loadLocations() {
        if let path = Bundle.main.path(forResource: "unique_locations", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                locations = try JSONDecoder().decode([String].self, from: data)
            } catch {
                print("Error loading locations: \(error)")
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let firstChar = searchText.first, firstChar.isLetter {
            let letter = String(firstChar).lowercased()
            if letter != currentAPIFirstLetter {
                currentAPIFirstLetter = letter
                fetchCrimeDataForLetter(letter: letter)
            }
        } else {
            currentAPIFirstLetter = ""
        }
        
        if searchText.isEmpty {
            filteredLocations = []
            resultsTableView.isHidden = true
        } else {
            filteredLocations = locations.filter { $0.lowercased().hasPrefix(searchText.lowercased()) }
            if filteredLocations.isEmpty {
                filteredLocations = locations.filter { $0.lowercased().contains(searchText.lowercased()) }
            }
            resultsTableView.isHidden = filteredLocations.isEmpty
            resultsTableView.reloadData()
        }
    }

       func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true) 
        
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            let alert = UIAlertController(title: "Empty Search", message: "Please enter an address to search", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        performSegue(withIdentifier: "showResults", sender: searchText)
    }

    func fetchCrimeDataForLetter(letter: String) {
        let lowercaseLetter = letter.lowercased()
        let urlString = "https://gagegaspar0.github.io/cmpd-data/crime_data_\(lowercaseLetter).json"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        print("📡 Attempting API connection for \(urlString)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 400 {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    return
                }
            }
            
            if let error = error {
                print("Error connecting to API: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from API")
                return
            }
            
            print("Received data of size: \(data.count) bytes")
            
            if let dataPreview = String(data: data.prefix(300), encoding: .utf8),
               dataPreview.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                print("Received HTML instead of JSON data")
                print("HTML preview: \(dataPreview)")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let records = try decoder.decode([CrimeRecord].self, from: data)
                
                DispatchQueue.main.async {
                    print("Connection to crime_data_\(lowercaseLetter).json was successful")
                    print("Retrieved \(records.count) records, here is a preview:")
                    let firstThree = records.prefix(3)
                    for record in firstThree {
                        print(record.location)
                    }
                }
            } catch {
                print("JSON decoding error: \(error)")
                if let dataPreview = String(data: data.prefix(300), encoding: .utf8) {
                    print("📄 Raw data preview: \(dataPreview)")
                }
            }
        }
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell") ?? UITableViewCell(style: .default, reuseIdentifier: "SearchResultCell")
        let location = filteredLocations[indexPath.row]
        cell.textLabel?.text = location
        return cell
    }
    
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let selectedLocation = filteredLocations[indexPath.row]
    neighborhoodSearchBar.text = selectedLocation
    resultsTableView.isHidden = true
    filteredLocations = []
    
    
    performSegue(withIdentifier: "showResults", sender: selectedLocation)
}
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResults",
           let resultsVC = segue.destination as? ResultsViewController,
           let address = sender as? String {
            resultsVC.searchAddress = address
        }
    }
}
//end ViewController
