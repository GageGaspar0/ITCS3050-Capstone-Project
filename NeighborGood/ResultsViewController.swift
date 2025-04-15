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
    var searchAddress: String = ""
    
    
    @IBOutlet weak var overviewContainerOne: UIView!
    
    @IBOutlet weak var subViewOne: UIView!
    
    @IBOutlet weak var subViewTwo: UIView!
    
    @IBOutlet weak var subViewThree: UIView!
    
    @IBOutlet weak var subViewFour: UIView!
    
    @IBOutlet weak var totalIncidentsLabel: UILabel!
    
    @IBOutlet weak var avgIncidentsPerYearLabel: UILabel!
    
    @IBOutlet weak var sixYearTrendImage: UIImageView!
    
    @IBOutlet weak var threeYearTrendImage: UIImageView!
    
    @IBOutlet weak var topThreeLabel: UILabel!
    
    @IBOutlet weak var mostCommonReports: UIView!
    
    
    private var crimeRecords: [CrimeRecord] = []
    private var crimeStatistics: CrimeAnalysisService.CrimeStatistics?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Overview"
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        overviewContainerOne.layer.cornerRadius = 30
        subViewOne.layer.cornerRadius = 10
        subViewTwo.layer.cornerRadius = 10
        subViewThree.layer.cornerRadius = 10
        subViewFour.layer.cornerRadius = 10
        mostCommonReports.layer.cornerRadius = 20
        totalIncidentsLabel.text = "0"
        avgIncidentsPerYearLabel.text = "0"
       
        if !searchAddress.isEmpty {
            print("Searching for address: \(searchAddress)")
            fetchCrimeData(for: searchAddress)
        } else {
            print("Search address is empty")
        }
    }

    private func animateCountUp(for label: UILabel, to finalValue: Int, duration: Double) {
    let steps = 30
    let increment = Double(finalValue) / Double(steps)
    var currentValue = 0.0
    
    Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { timer in
        currentValue += increment
        if currentValue >= Double(finalValue) {
            label.text = "\(finalValue)"
            timer.invalidate()
        } else {
            label.text = "\(Int(currentValue))"
        }
    }
}

private func animateDoubleCountUp(for label: UILabel, to finalValue: Double, duration: Double, decimals: Int) {
    let steps = 30
    let increment = finalValue / Double(steps)
    var currentValue = 0.0
    
    Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { timer in
        currentValue += increment
        if currentValue >= finalValue {
            label.text = String(format: "%.\(decimals)f", finalValue)
            timer.invalidate()
        } else {
            label.text = String(format: "%.\(decimals)f", currentValue)
        }
    }
}
    
    func displayError(_ message: String) {
        crimeRecords = []
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        
        print("Error displayed: \(message)")
    }
    
    func fetchCrimeData(for address: String) {
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    activityIndicator.startAnimating()
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
                    if let tabBar = self?.tabBarController,
                       let vcs = tabBar.viewControllers {
                        if let detailVC = vcs[1] as? DetailViewController {
                            detailVC.crimeRecords = relevantRecords
                        }
                    }
                    self?.crimeStatistics = CrimeAnalysisService.analyze(crimeRecords: relevantRecords)
                     let totalIncidents = self?.crimeRecords.count ?? 0
                self?.animateCountUp(for: self?.totalIncidentsLabel ?? UILabel(),
                                     to: totalIncidents,
                                     duration: 1.5)
                      let avg = self?.crimeStatistics?.averageIncidentsPerYear ?? 0
                self?.animateDoubleCountUp(for: self?.avgIncidentsPerYearLabel ?? UILabel(),
                                           to: avg,
                                           duration: 1.5,
                                           decimals: 0)

                   if let stats = self?.crimeStatistics {
    let sixYearIncreasing = CrimeAnalysisService.isCrimeIncreasingOverLastSixYears(incidentsPerYear: stats.incidentsPerYear)
    if sixYearIncreasing {
        self?.sixYearTrendImage.image = UIImage(systemName: "arrow.up.forward")
        self?.sixYearTrendImage.tintColor = .red
    } else {
        self?.sixYearTrendImage.image = UIImage(systemName: "arrow.down.forward")
        self?.sixYearTrendImage.tintColor = .green
    }  
    
    
    self?.sixYearTrendImage.transform = CGAffineTransform(translationX: -50, y: 0)
    UIView.animate(withDuration: 1.0) {
        self?.sixYearTrendImage.transform = .identity
    }
    
    let threeYearIncreasing = CrimeAnalysisService.isCrimeIncreasingOverLastThreeYears(incidentsPerYear: stats.incidentsPerYear)
    if threeYearIncreasing {
        self?.threeYearTrendImage.image = UIImage(systemName: "arrow.up.forward")
        self?.threeYearTrendImage.tintColor = .red
    } else {
        self?.threeYearTrendImage.image = UIImage(systemName: "arrow.down.forward")
        self?.threeYearTrendImage.tintColor = .green
    }
                       self?.threeYearTrendImage.transform = CGAffineTransform(translationX: -50, y: 0)
                         UIView.animate(withDuration: 1.0, delay: 0.3, options: .curveEaseInOut, animations: {
                             self?.threeYearTrendImage.transform = .identity
                         }, completion: nil)
                       
                        
                        self?.mostCommonReports.subviews.forEach { $0.removeFromSuperview() }
                        
                     
                        let offenseSummary = Dictionary(grouping: relevantRecords, by: { $0.highestNibrsDescription })
                            .mapValues { $0.count }
                        
                      
                        let sortedOffenses = offenseSummary.sorted { $0.value > $1.value }
                        let topOffenses = sortedOffenses.prefix(3)
                        let totalOffenses = relevantRecords.count
                        
                       
                        let containerWidth = self?.mostCommonReports.bounds.width ?? 353
                        let containerHeight: CGFloat = 50
                        let verticalSpacing: CGFloat = 10
                        
                      
                        for (index, offense) in topOffenses.enumerated() {
                            let yOffset = CGFloat(index) * (containerHeight + verticalSpacing)
                            let containerFrame = CGRect(
                                x: 0,
                                y: yOffset,
                                width: containerWidth,
                                height: containerHeight
                            )
                            
                            let container = CommonReportsContainer(frame: containerFrame)
                            
                            let offenseDescription = offense.key
                            let offenseCount = offense.value
                            let percentage = (Double(offenseCount) / Double(totalOffenses)) * 100.0
                            
                          
                            container.offenseDescription.text = offenseDescription
                            container.offensePercentage.text = String(format: "%.1f%%", percentage)
                            
                            self?.mostCommonReports.addSubview(container)
                        }
                    }
                    
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
