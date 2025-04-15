//
//  DetailViewController.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/13/25.
//

import UIKit

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
   
    @IBOutlet weak var tableView: UITableView!
    
   
    var crimeRecords: [CrimeRecord] = []
    
    private var dataByYearAndOffense: [String: [String: [CrimeRecord]]] = [:]
    
    
    private var sortedYears: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Details"
        tableView.overrideUserInterfaceStyle = .light
       
        tableView.dataSource = self
        tableView.delegate = self
        
        groupCrimeRecords()
    }
    
  private func groupCrimeRecords() {
    dataByYearAndOffense.removeAll()
    
    for record in crimeRecords {
        let year = record.year
        let offense = record.highestNibrsDescription
        
        if dataByYearAndOffense[year] == nil {
            dataByYearAndOffense[year] = [:]
        }
        if dataByYearAndOffense[year]?[offense] == nil {
            dataByYearAndOffense[year]?[offense] = []
        }
        
        dataByYearAndOffense[year]?[offense]?.append(record)
    }
    
    // Sort descending (newest first)
    sortedYears = dataByYearAndOffense.keys.sorted { lhs, rhs in
        if let leftInt = Int(lhs), let rightInt = Int(rhs) {
            return leftInt > rightInt
        } else {
            return lhs > rhs
        }
    }
    tableView.reloadData()
}
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return sortedYears.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedYears[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let year = sortedYears[section]
        guard let offenseDict = dataByYearAndOffense[year] else {
            return 0
        }
        return offenseDict.keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell")
                    ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DetailCell")
        
        let year = sortedYears[indexPath.section]
        guard let offenseDict = dataByYearAndOffense[year] else {
            cell.textLabel?.text = "Unknown"
            return cell
        }
        
        
        let offenses = offenseDict.keys.sorted()
        let offenseName = offenses[indexPath.row]
        let offenseRecords = offenseDict[offenseName] ?? []
        
        
        cell.textLabel?.text = offenseName
        cell.detailTextLabel?.text = "Incidents: \(offenseRecords.count)"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
   
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let year = sortedYears[indexPath.section]
        guard let offenseDict = dataByYearAndOffense[year] else { return }
        let offenses = offenseDict.keys.sorted()
        let offenseName = offenses[indexPath.row]
        
        let incidents = offenseDict[offenseName] ?? []
        
       
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "OffenseDetailViewController") as? OffenseDetailViewController {
            detailVC.modalPresentationStyle = .pageSheet
            detailVC.title = "\(offenseName) (\(year))"
            detailVC.incidents = incidents
            present(detailVC, animated: true)
        }
    }
}
