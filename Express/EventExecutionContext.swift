//===--- EventExecutionContext.swift -------------------------------------------===//
//
//Copyright (c) 2015-2016 Daniel Leping (dileping)
//
//This file is part of Swift Express.
//
//Swift Express is free software: you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//Swift Express is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with Swift Express.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import Boilerplate
import ExecutionContext
import Future

import CEvent

//TODO: move to boilerplate and make ALL-functional
class SafeFunction {
    let f:SafeTask
    
    init(_ f:@escaping SafeTask) {
        self.f = f
    }
}

extension Timeout {
    static let USEC_PER_SEC:Double = 1000*1000
    
    var sec:Double {
        switch self {
        case .Infinity: return Double.infinity
        case .Immediate: return 0
        case .In(timeout: let timeout): return timeout.nextDown
        }
    }
    
    var secUsec:(Int, Int) {
        switch self {
        case .Infinity: return (Int.max, Int.max)
        case .Immediate: return (0, 0)
        case .In(timeout: let timeout):
            let sec = timeout.nextDown
            let usec = (timeout-sec) * Timeout.USEC_PER_SEC
            return (Int(sec), Int(usec))
        }
    }
}

extension Timeout {
    var timeval:timeval? {
        switch self {
        case .Immediate: return nil
        default:
            let secUsec = self.secUsec
            return CEvent.timeval(tv_sec: Int(secUsec.0), tv_usec: Int32(secUsec.1))
        }
    }
}

func event_base_task(base:OpaquePointer, timeout:UnsafePointer<timeval>?, task:@escaping SafeTask) {
    let function = SafeFunction(task)
    
    event_base_once(base, -1, Int16(EV_TIMEOUT), { (fd: Int32, what: Int16, arg: UnsafeMutableRawPointer?) in
        let task = Unmanaged<SafeFunction>.fromOpaque(arg!).takeRetainedValue()
        task.f()
    }, UnsafeMutableRawPointer(Unmanaged.passRetained(function).toOpaque()), timeout)
}

func event_base_task(base:OpaquePointer, timeout:Timeout = .Immediate, task:@escaping SafeTask) {
    var timeval = timeout.timeval
    let tvp = timeval.map { _ in
        withUnsafePointer(to: &timeval!) {$0}
    }
    
    event_base_task(base: base, timeout: tvp, task: task)
}

internal class EventExecutionContext : ExecutionContextBase, ExecutionContextProtocol {
    //static initialization
    static let _ini:Void = {
        evthread_use_pthreads()
    }()
    
    let base:OpaquePointer
    //TODO: atomic
    private var _running:Bool = false
    
    override init() {
        //static initialization
        EventExecutionContext._ini
        self.base = event_base_new()
        super.init()
        _run()
    }
    
    deinit {
        event_base_loopexit(base, nil)
    }
    
    private func _run() {
        if _running {
            return
        }
        
        let base = self.base
        
        try! Thread.detach { [weak self] in
            _currentContext.value = self
            
            self?._running = true
            defer {
                self?._running = false
            }
            
            let exit = event_base_loop(base, EVLOOP_NO_EXIT_ON_EMPTY)
            
            print("done:", exit)
        }
        
        
    }
    
    public func sync<ReturnType>(task: @escaping () throws -> ReturnType) rethrows -> ReturnType {
        return try syncThroughAsync(task: task)
    }
    
    public func async(after: Timeout, task: @escaping SafeTask) {
        event_base_task(base: base, timeout: after, task: task)
    }
    
    public func async(task: @escaping SafeTask) {
        event_base_task(base: base, task: task)
    }
    
}

extension EventExecutionContext : NonStrictEquatable {
    func isEqual(to other:NonStrictEquatable) -> Bool {
        guard let other = other as? EventExecutionContext else {
            return false
        }
        return self.base == other.base
    }
}
