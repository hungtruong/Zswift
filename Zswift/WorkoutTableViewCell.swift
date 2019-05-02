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
    @IBOutlet weak var workoutStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupWithWorkout(_ workout: Workout) {
        workoutStackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
            workoutStackView.removeArrangedSubview(view)
        }
        
        workout.workoutSegments.forEach { workoutSegment in
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(barView)
            let heightMultiplier = workoutSegment.highPower() / workout.maximumPower()

            barView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: CGFloat(heightMultiplier)).isActive = true
            workoutStackView.addArrangedSubview(view)
            let multiplier = workoutSegment.duration / workout.totalTime
            view.widthAnchor.constraint(equalTo: workoutStackView.widthAnchor, multiplier: CGFloat(multiplier)).isActive = true
            barView.backgroundColor = workoutSegment.color()

            
            barView.bottomAnchor.constraint(equalTo: barView.superview!.bottomAnchor).isActive = true
            barView.leadingAnchor.constraint(equalTo: barView.superview!.leadingAnchor).isActive = true
            barView.trailingAnchor.constraint(equalTo: barView.superview!.trailingAnchor, constant: -1).isActive = true
        }
    }

}
