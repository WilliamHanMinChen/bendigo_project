//
//  Painting.swift
//  Image Recogniser
//
//  Created by William Chen on 2022/7/13.
//

import UIKit

class Painting: NSObject {
    var regions: [Region]
    var width: Int
    var height: Int
    
    init(regions: [Region], width: Int, height: Int) {
        self.regions = regions
        self.width = width
        self.height = height
    }
}

class Region: NSObject {
    var lineSegments: [LineSegment]
    var label: String
    
    init(lineSegments: [LineSegment], label: String){
        self.lineSegments = lineSegments
        self.label = label
        
    }
}


class Point: NSObject {
    var x: Float
    var y: Float
    
    init(x: Float, y: Float){
        self.x = x
        self.y = y
    }
}

class LineSegment: NSObject {
    
    var startingPoint: Point
    var endingPoint: Point
    
    init(startingPoint: Point, endingPoint: Point){
        self.startingPoint = startingPoint
        self.endingPoint = endingPoint
    }
}
