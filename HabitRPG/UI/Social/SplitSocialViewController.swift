//
//  HabiticaSplitViewController.swift
//  Habitica
//
//  Created by Phillip Thelen on 21.02.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import UIKit
import Habitica_Models
import ReactiveSwift

class SplitSocialViewController: HRPGUIViewController, UIScrollViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var detailViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var chatViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    
    @objc var groupID: String?
    
    var detailViewController: HRPGGroupTableViewController?
    var chatViewController: GroupChatViewController?
    
    private let segmentedWrapper = PaddedView()
    private let segmentedControl = UISegmentedControl(items: [NSLocalizedString("", comment: ""), NSLocalizedString("Chat", comment: "")])
    private var isInitialSetup = true
    private var showAsSplitView = false
    
    private let socialRepository = SocialRepository()
    private let disposable = ScopedDisposable(CompositeDisposable())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showAsSplitView = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControl.tintColor = UIColor.purple300()
        self.segmentedControl.addTarget(self, action: #selector(SplitSocialViewController.switchView(_:)), for: .valueChanged)
        self.segmentedControl.setTitle(navigationItem.title, forSegmentAt: 0)
        segmentedControl.isHidden = false
        segmentedWrapper.containedView = segmentedControl
        topHeaderCoordinator.alternativeHeader = segmentedWrapper
        topHeaderCoordinator.hideHeader = showAsSplitView
        
        scrollView.delegate = self
        
        for childViewController in self.childViewControllers {
            if let viewController = childViewController as? HRPGGroupTableViewController {
                detailViewController = viewController
            }
            if let viewController = childViewController as? GroupChatViewController {
                chatViewController = viewController
            }
        }
        
        detailViewController?.groupID = groupID
        chatViewController?.groupID = groupID
        
        if let groupID = self.groupID {
            disposable.inner.add(socialRepository.getGroup(groupID: groupID).on(value: { group in
                self.set(group: group)
            }).start())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = self.hrpgTopHeaderNavigationController() {
            scrollViewTopConstraint.constant = navController.contentInset
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isInitialSetup {
            isInitialSetup = false
            setupSplitView(traitCollection)
            if !showAsSplitView {
                let userDefaults = UserDefaults()
                let lastPage = userDefaults.integer(forKey: groupID ?? "" + "lastOpenedSegment")
                segmentedControl.selectedSegmentIndex = lastPage
                scrollTo(page: lastPage, animated: false)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let userDefaults = UserDefaults()
        userDefaults.set(segmentedControl.selectedSegmentIndex, forKey: groupID ?? "" + "lastOpenedSegment")
        super.viewWillDisappear(animated)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.setupSplitView(newCollection)
            self.scrollTo(page: self.segmentedControl.selectedSegmentIndex)
        }, completion: nil)
    }
    
    private func setupSplitView(_ collection: UITraitCollection) {
        showAsSplitView = collection.horizontalSizeClass == .regular && collection.verticalSizeClass == .regular
        separatorView.isHidden = !showAsSplitView
        scrollView.isScrollEnabled = !showAsSplitView
        topHeaderCoordinator?.hideHeader = showAsSplitView
        if showAsSplitView {
            detailViewWidthConstraint = detailViewWidthConstraint.setMultiplier(multiplier: 0.333)
            chatViewWidthConstraint = chatViewWidthConstraint.setMultiplier(multiplier: 0.666)
        } else {
            detailViewWidthConstraint = detailViewWidthConstraint.setMultiplier(multiplier: 1)
            chatViewWidthConstraint = chatViewWidthConstraint.setMultiplier(multiplier: 1)
        }
        self.view.setNeedsLayout()
    }
    
    internal func set(group: GroupProtocol) {
        //detailViewController?.group = group
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = getCurrentPage()
        self.segmentedControl.selectedSegmentIndex = currentPage
    }

    
    @objc
    func switchView(_ segmentedControl: UISegmentedControl) {
        scrollTo(page: segmentedControl.selectedSegmentIndex)
    }
    
    func getCurrentPage() -> Int {
        return Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
    
    func scrollTo(page: Int, animated: Bool = true) {
        let point = CGPoint(x: scrollView.frame.size.width * CGFloat(page), y: 0)
        scrollView.setContentOffset(point, animated: animated)
    }
}
