import Foundation
import UIKit

extension Profiler.Clock {
  private static let numberFormatter = NumberFormatter()
  
  private static var averageValues: [String: [Double]] = [:]
  
  static func measureAverage(
    _ id: String = #function,
    count: Int = 30,
    equalFractionDigits: Int = 4,
    assertLessThan maxMilliseconds: Double = 0.0
  ) -> () -> Void {
    guard enabled else {
      return {}
    }
    
    var values = averageValues[id] ?? .init(repeating: 0, count: count)
    let start = CACurrentMediaTime()
    
    return {
      let ms = (CACurrentMediaTime() - start) * 1000
      
      values.insert(ms, at: 0)
      values.removeLast()
      assert(values.count == count)
      
      if maxMilliseconds > 0 {
        assert(ms <= maxMilliseconds, "\(id) \(ms) exceeded time limit: \(maxMilliseconds)")
      }
      
      averageValues[id] = values
      
      numberFormatter.maximumFractionDigits = equalFractionDigits
      numberFormatter.minimumFractionDigits = equalFractionDigits
      
      let average = values.reduce(0, +) / Double(values.count { $0 > 0 })
      print("average time \(numberFormatter.string(for: average)!)ms \(id)")
    }
  }
  
  static func measure(
    _ description: String,
    assertLessThan maxMilliseconds: Double = 0
  ) -> () -> Void {
    guard enabled else {
      return {}
    }
    
    return { [start = CACurrentMediaTime()] in
      let ms = (CACurrentMediaTime() - start) * 1000
      print("single task \(description) -> \(ms)")
      
      if maxMilliseconds > 0 {
        assert(ms <= maxMilliseconds, "\(description) \(ms) exceeded time limit: \(maxMilliseconds)")
      }
    }
  }
}
