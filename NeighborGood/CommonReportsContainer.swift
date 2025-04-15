//
//  CommonReportsContainer.swift
//  NeighborGood
//
//  Created by Gage Gasparyan on 4/13/25.
//

import UIKit

class CommonReportsContainer: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var offensePercentage: UILabel!
    @IBOutlet weak var offenseCount: UILabel!
    @IBOutlet weak var offenseDescription: UILabel!
    @IBOutlet weak var offensePercentContainer: UIView!


    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

   
    private func commonInit() {
        
        Bundle.main.loadNibNamed("CommonReportsContainer", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        offensePercentContainer.clipsToBounds = true
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }



    func configure(description: String, count: String, percentage: String, percentColor: UIColor) {
        offenseDescription.text = description
        offenseCount.text = count
        offensePercentage.text = percentage
        offensePercentContainer.backgroundColor = percentColor
    }
}
