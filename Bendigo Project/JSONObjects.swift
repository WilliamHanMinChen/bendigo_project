//
//  JSONObjects.swift
//  Image Recogniser
//
//  Created by William Chen on 2022/7/13.
//

import UIKit

class JSONObject: NSObject, Codable {
    var annotations: [Annotation]
    
}


class Annotation: NSObject, Codable {
    var result: [Result] //Each of the results represent a region
    
}

class Result: NSObject, Codable {
    var original_width: Int
    var original_height: Int
    var value: Value //Contains the points of the region and the label for it
}


class Value: NSObject, Codable {
    var points: [[Float]]
    var polygonlabels: [String]
}





