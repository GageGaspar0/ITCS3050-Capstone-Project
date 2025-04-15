//
//  OffenseDetailViewController.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/13/25.
//


import UIKit

class OffenseDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var incidents: [CrimeRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incidents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "IncidentCell") 
                    ?? UITableViewCell(style: .subtitle, reuseIdentifier: "IncidentCell")
        
        let incident = incidents[indexPath.row]
        
       
        let displayDate = CrimeAnalysisService.formatDate(incident.dateReported)
        
       
        cell.textLabel?.text = incident.location
        
       
        cell.detailTextLabel?.text = "\(displayDate) | \(incident.locationTypeDescription)"
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .none
        
        return cell
    }
    
   
    @IBAction func didPressClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
