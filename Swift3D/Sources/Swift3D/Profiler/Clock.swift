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

      let averageString = string(
        for: values.reduce(0, +) / Double(values.count { $0 > 0 }),
        fractionDigits: equalFractionDigits
      )
      
      print("average time \(averageString) ms \(id)")
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
      print("atomic task \(description) -> \(ms)")
      
      if maxMilliseconds > 0 {
        assert(ms <= maxMilliseconds, "\(description) \(ms) exceeded time limit: \(maxMilliseconds)")
      }
    }
  }
  
  static func measureSteps(_ description: String) -> ((String) -> Void, () -> Void) {
    guard enabled else {
      return ({ _ in }, {})
    }
    
    let start = CACurrentMediaTime()
    
    var steps: [Double] = []
    var stepIDs: [String] = []
    
    let addStep = { (id: String) -> Void in
      steps.append(CACurrentMediaTime())
      stepIDs.append(id)
    }
    
    let measure = { () -> Void in
      let total = CACurrentMediaTime() - start
      var current = start
      
      let descriptions = zip(steps, stepIDs).map { step, id in
        let ratio = (step - current) / total
        let string = string(for: ratio)
        current = step
        
        return "\(id): \(string)"
      }
      print("stepped task \(description) -> \(string(for: total * 1000)) ms, \(descriptions.joined(separator: " "))")
    }
    
    return (addStep, measure)
  }
  
  private static func string(for value: Double, fractionDigits: Int = 2) -> String {
    numberFormatter.maximumFractionDigits = fractionDigits
    numberFormatter.minimumFractionDigits = fractionDigits
    
    return numberFormatter.string(for: value)!
  }
}
