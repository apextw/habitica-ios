//
//  WorldState.swift
//  Habitica Models
//
//  Created by Phillip Thelen on 13.03.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import Foundation

public protocol WorldStateProtocol {
    var worldBoss: QuestStateProtocol? { get set }
}
