//
//  WeeklyArchive.swift
//  Domain_ios
//
//  Created by 김윤서 on 2023/07/31.
//  Copyright © 2023 EarthIsRound. All rights reserved.
//

import Foundation

import DesignSystem_ios

public struct WeeklyArchive {
    public let uuid: UUID
    public let week: Int
    public let snowmanType: SnowmanType
    public let snowmanItem: [SnowmanItemType]

    public init(
        uuid: UUID,
        week: Int,
        snowmanType: SnowmanType,
        snowmanItem: [SnowmanItemType]
    ) {
        self.uuid = uuid
        self.week = week
        self.snowmanType = snowmanType
        self.snowmanItem = snowmanItem
    }
}

extension WeeklyArchive: Equatable, Hashable {
    public static func == (lhs: WeeklyArchive, rhs: WeeklyArchive) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
