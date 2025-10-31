import Foundation
import UIKit

enum Profiler {
  enum InstanceCount {}
  enum Clock {}
}

@inline(__always) private func print(_ string: String) { Swift.print(string) }

// MARK: - Clock

extension Profiler.Clock {
  private static let numberFormatter = NumberFormatter()
  
  private static var averageValues: [String: [Double]] = [:]
  
  static func measureAverage(
    _ id: String = #function,
    count: Int = 30,
    equalFractionDigits: Int = 4,
    assertLessThan maxMilliseconds: Double = 0.0
  ) -> () -> Void {
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
    { [start = CACurrentMediaTime()] in
      let ms = (CACurrentMediaTime() - start) * 1000
      print("Clock.Measure -> \(description) -> \(ms)")
      
      if maxMilliseconds > 0 {
        assert(ms <= maxMilliseconds, "\(description) \(ms) exceeded time limit: \(maxMilliseconds)")
      }
    }
  }
}

// MARK: - InstanceCount

extension Profiler.InstanceCount {
  private static var instancesCount: [AnyHashable: Int] = [:]
  
  static func increment<T: AnyObject>(_ type: T.Type) { addInstanceCount(+1, for: type) }
  static func decrement<T: AnyObject>(_ type: T.Type) { addInstanceCount(-1, for: type) }
  
  private static func addInstanceCount<T: AnyObject>(_ count: Int, for type: T.Type) {
    let id = String(describing: type)
    
    var current = instancesCount[id] ?? 0
    current -= 1
    instancesCount[id] = max(0, current)
    
    print("InstanceCount: \(id) -> \(current)")
  }
}
