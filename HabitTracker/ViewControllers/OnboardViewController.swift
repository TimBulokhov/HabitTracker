//
//  OnboardVC.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 01.06.2024.
//

import UIKit

protocol ContentViewControllerDelegate: AnyObject {
    func didTapButton()
}

// MARK: - OnboardViewController

final class OnboardViewController: UIPageViewController {
    private let dataStorage = DataStorege.shared
    private let analyticsService = AnalyticsService()
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .ypBlackDay
        pageControl.pageIndicatorTintColor = .backgroundDay
        pageControl.currentPage = 0
        pageControl.addTarget(OnboardViewController.self, action: #selector(pageControlTapped), for: .valueChanged)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    lazy var pages: [UIViewController] = [
        {
            let controller = OnboardContentViewController()
            controller.backgroundImage = UIImage(named: "blueImage")
            controller.descriptionText = NSLocalizedString("blueOnboardingText", comment: "blueOnboardingText")
            controller.delegate = self
            return controller
        }(),
        {
            let controller = OnboardContentViewController()
            controller.backgroundImage = UIImage(named: "redImage")
            controller.descriptionText = NSLocalizedString("redOnboardingText", comment: "redOnboardingText")
            controller.delegate = self
            return controller
        }()
    ]
    
    // MARK: - Initialisation
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configViews()
        configConstraints()
        analyticsService.report(event: .open, params: ["Screen" : "Onboarding"])
    }
    
    // MARK: - Actions
    
    @objc func pageControlTapped(_ sender: UIPageControl) {
        let tappedPageIndex = sender.currentPage
        if tappedPageIndex >= 0 && tappedPageIndex < pages.count {
            let targetPage = pages[tappedPageIndex]
            guard let currentViewController = viewControllers?.first else {
                return
            }
            if let currentIndex = pages.firstIndex(of: currentViewController) {
                let direction: UIPageViewController.NavigationDirection = tappedPageIndex > currentIndex ? .forward : .reverse
                setViewControllers([targetPage], direction: direction, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func configViews() {
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
        delegate = self
        dataSource = self
        pageControl.numberOfPages = pages.count
        view.addSubview(pageControl)
    }
    
    private func configConstraints() {
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -134),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return pages.last
        }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else {
            return pages.first
        }
        return pages[nextIndex]
    }
}

// MARK: - ContentViewControllerDelegate

extension OnboardViewController: ContentViewControllerDelegate {
    func didTapButton() {
        
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid Configuration")
        }
        window.rootViewController = TabBarController()
        dataStorage.firstLaunchApplication = true
    }
}


