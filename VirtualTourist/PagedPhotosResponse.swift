//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Jimin Kim on 3/14/21.
//  Copyright © 2021 Jimin Kim. All rights reserved.
//

import Foundation

struct PagedPhotosResponse: Codable {
    let photos: PhotosResponse
}

struct PhotosResponse: Codable {
    let page: Int?
    let pages: Int?
    let perpage: Int?
    let total: String?
    let photo: [PhotoResponse]
}

struct PhotoResponse: Codable {
    let url_q: String?
}
