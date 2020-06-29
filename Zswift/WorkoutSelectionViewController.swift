//
//  WorkoutSelectionViewController.swift
//  Zswift
//
//  Created by Hung Truong on 4/6/19.
//  Copyright © 2019 Hung Truong. All rights reserved.
//

import UIKit
import SwiftUI

class WorkoutSelectionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    let workouts = WorkoutManager.shared.workouts
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ZSwift"
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsButtonTapped))
        settingsButton.tintColor = .darkGray
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "WorkoutSegue", let vc = segue.destination as? WorkoutViewController,
            let cell = sender as? UITableViewCell,  let indexPath = self.tableView.indexPath(for: cell)  {
            let workout = workouts[indexPath.row]
            vc.workout = workout
        }
    }
}

extension WorkoutSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as! WorkoutTableViewCell
        let workout = self.workouts[indexPath.row]
        cell.nameLabel.text = workout.name
        cell.descriptionLabel.text = workout.workoutDescription
        cell.setupWithWorkout(workout)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc
    func settingsButtonTapped() {
        let view = UIHostingController(rootView: SettingsView())
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    
}
