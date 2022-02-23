//
//  KMeans.swift
//  OOrion-Project-App
//
//  Created by Maxime Wolf on 23/02/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//
import Foundation

private func indexOfNearestCenter(_ x: Vector, centers: [Vector]) -> Int {
    var nearestDist = Double.greatestFiniteMagnitude
    var minIndex = 0

    for (idx, center) in centers.enumerated() {
      let dist = x.distanceTo(center)
      if dist < nearestDist {
        minIndex = idx
        nearestDist = dist
      }
    }
    return minIndex
  }

func reservoirSample<T>(_ samples: [T], k: Int) -> [T] {
  var result = [T]()

  // Fill the result array with first k elements
  for i in 0..<k {
    result.append(samples[i])
  }

  // Randomly replace elements from remaining pool
  for i in k..<samples.count {
    let j = Int(arc4random_uniform(UInt32(i + 1)))
    if j < k {
      result[j] = samples[i]
    }
  }
  return result
}


func kMeans(numCenters: Int, convergeDistance: Double, points: [Vector]) -> [Vector] {

  // Randomly take k objects from the input data to make the initial centroids.
  var centers = reservoirSample(points, k: numCenters)

  // This loop repeats until we've reached convergence, i.e. when the centroids
  // have moved less than convergeDistance since the last iteration.
  var centerMoveDist = 0.0
  repeat {
    // In each iteration of the loop, we move the centroids to a new position.
    // The newCenters array contains those new positions.
    let zeros = [Double]( repeating: 0,count: points[0].length)
    var newCenters = [Vector](repeating: Vector(zeros),count: numCenters)

    // We keep track of how many data points belong to each centroid, so we
    // can calculate the average later.
    var counts = [Double](repeating: 0,count: numCenters)

    // For each data point, find the centroid that it is closest to. We also
    // add up the data points that belong to that centroid, in order to compute
    // that average.
    for p in points {
      let c = indexOfNearestCenter(p, centers: centers)
      newCenters[c] += p
      counts[c] += 1
    }

    // Take the average of all the data points that belong to each centroid.
    // This moves the centroid to a new position.
    for idx in 0..<numCenters {
      newCenters[idx] /= counts[idx]
    }

    // Find out how far each centroid moved since the last iteration. If it's
    // only a small distance, then we're done.
    centerMoveDist = 0.0
    for idx in 0..<numCenters {
      centerMoveDist += centers[idx].distanceTo(newCenters[idx])
    }

    centers = newCenters
  } while centerMoveDist > convergeDistance

  return centers
}


import Foundation

struct Vector: CustomStringConvertible, Equatable {
  private(set) var length = 0
  private(set) var data: [Double]

  init(_ data: [Double]) {
    self.data = data
    self.length = data.count
  }

  var description: String {
    return "Vector (\(data)"
  }

  func distanceTo(_ other: Vector) -> Double {
    var result = 0.0
    for idx in 0..<length {
      result += pow(data[idx] - other.data[idx], 2.0)
    }
    return sqrt(result)
  }
}

func == (left: Vector, right: Vector) -> Bool {
  for idx in 0..<left.length {
    if left.data[idx] != right.data[idx] {
      return false
    }
  }
  return true
}

func + (left: Vector, right: Vector) -> Vector {
  var results = [Double]()
  for idx in 0..<left.length {
    results.append(left.data[idx] + right.data[idx])
  }
  return Vector(results)
}

func += (left: inout Vector, right: Vector) {
  left = left + right
}

func - (left: Vector, right: Vector) -> Vector {
  var results = [Double]()
  for idx in 0..<left.length {
    results.append(left.data[idx] - right.data[idx])
  }
  return Vector(results)
}

func -= (left: inout Vector, right: Vector) {
  left = left - right
}

func / (left: Vector, right: Double) -> Vector {
  var results = [Double](repeating: 0, count: left.length)
  for (idx, value) in left.data.enumerated() {
    results[idx] = value / right
  }
  return Vector(results)
}

func /= (left: inout Vector, right: Double) {
  left = left / right
}

//print(kMeans(numCenters: 4, convergeDistance:0.00,points:[Vector([1.22,2.77]),Vector([1.10,1.10]),Vector([0.80,1.20]),Vector([1.12,1.77]),Vector([3.12,1.37]),Vector([1.92,2.17]),Vector([1.00,2.00])]))
