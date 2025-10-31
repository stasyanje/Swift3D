//
//  Profiler 2.swift
//  Swift3D
//
//  Created by Stanislav Kaliuzhnyi on 10/30/25.
//


// MARK: - Counter

extension Profiler.Counter {
  static func increment<T: AnyObject>(_ type: T.Type) { addInstanceCount(+1, for: type) }
  static func decrement<T: AnyObject>(_ type: T.Type) { addInstanceCount(-1, for: type) }
  
  // MARK: - Private
  
  private static var counters: [AnyHashable: Int] = [:]
  
  private static func addInstanceCount<T: AnyObject>(_ count: Int, for type: T.Type) {
    guard enabled else {
      return
    }
    
    let id = String(describing: type)
    
    var current = counters[id] ?? 0
    current += count
    counters[id] = max(0, current)
    
    print("Counter: \(id) -> \(current)")
  }
}
