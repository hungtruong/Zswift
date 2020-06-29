//
//  WorkoutTableViewCell.swift
//  Zswift
//
//  Created by Hung Truong on 4/6/19.
//  Copyright © 2019 Hung Truong. All rights reserved.
//

import UIKit

class WorkoutTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var workoutView: WorkoutView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupWithWorkout(_ workout: Workout) {
        self.workoutView.setupWorkout(workout)
    }

}
