//
//  DataStructures.swift
//  Looomity
//
//  Created by Michael Langbein on 20.12.22.
//

import Foundation


class Queue<T>: ObservableObject {
    @Published var list = [T]()
    
    var isEmpty: Bool {
        return list.isEmpty
    }
    
    func enqueue(_ element: T) {
        list.append(element)
    }
    
    func dequeue() -> T? {
        if !list.isEmpty {
            return list.removeFirst()
        } else {
            return nil
        }
    }
    
    func peek() -> T? {
        if !list.isEmpty {
            return list[0]
        } else {
            return nil
        }
    }
}
