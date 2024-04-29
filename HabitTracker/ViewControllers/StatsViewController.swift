//
//  StatsViewController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

final class StatsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configStatsUI()
    }

    func configStatsUI() {
        view.backgroundColor = .ypWhiteDay

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Statistic"

        let label = UILabel()
        label.text = "There is nothing to analyze yet"
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

                let imageView = UIImageView(image: UIImage(named: "error3"))
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(imageView)

        NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    imageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -8),
                    imageView.widthAnchor.constraint(equalToConstant: 80),
                    imageView.heightAnchor.constraint(equalToConstant: 80)
                ])
    }

}
