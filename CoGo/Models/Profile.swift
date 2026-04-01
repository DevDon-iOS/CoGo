//
//  Profile.swift
//  CoGo
//
//  Created by 이돈혁 on 3/30/26.
//

import Foundation

struct Profile: Codable, Identifiable{
    let id: String
    let imageName: String
    let nickname: String
}
