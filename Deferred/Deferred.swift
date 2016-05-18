//
//  DeferredProtocol.swift
//  Pods
//
//  Created by damouse on 4/26/16.
//
//

import Foundation


class AbstractDeferred {
    // Automatically invoke callbacks and errbacks if not nil when given arguments
    var callbackArgs: [AnyObject]?
    var errbackArgs: [AnyObject]?
    
    // If an invocation has already occured then the args properties are already set
    // We should invoke immediately
    var _callback: AnyClosureType?
    var _errback: AnyClosureType?
    
    // The next link in the chain
    var next: [AbstractDeferred] = []
    
    
    func _then<T: AbstractDeferred>(fn: AnyClosureType, nextDeferred: T) -> T {
        next.append(nextDeferred)
        
        // This isnt correct and likely doesnt account for the failure cases well
        // if let a = callbackArgs { callback(a) }
        if let a = callbackArgs { _ = try? fn.call(a) }
        
        // Also we don't want to replace the callback here if the args are set, want to branch the chain instead
        _callback = fn
        
        return nextDeferred
    }
    
    func _error<T: AbstractDeferred>(fn: AnyClosureType, nextDeferred: T) -> T {
        next.append(nextDeferred)
        _errback = fn
        if let a = errbackArgs { errback(a) }
        return nextDeferred
    }
    
    func callback(args: [AnyObject]) {
        callbackArgs = args
        var ret: [AnyObject] = []
        
        // Not handled: error branching and chaining
        if let cb = _callback { ret = try! cb.call(args) }
        for n in next { n.callback(ret) }
    }
    
    func errback(args: [AnyObject]) {
        errbackArgs = args
        if let eb = _errback { try! eb.call(args) }
        for n in next { n.errback(args) }
    }
    
    func error(fn: String -> ()) -> Deferred<Void> {
        return _error(Closure.wrap(fn), nextDeferred: Deferred<Void>())
    }
}


class Deferred<A>: AbstractDeferred {
    func then(fn: A -> ())  -> Deferred<Void> {
        return _then(Closure.wrap(fn), nextDeferred: Deferred<Void>())
    }
    
    func then<T>(fn: A -> Deferred<T>)  -> Deferred<T> {
        let next = Deferred<T>()
        
        _callback = Closure.wrap { (a: A) in
            fn(a).then { s in
                s is Void ? next.callback([]) : next.callback([s as! AnyObject])
            }.error { s in
                next.errback([s])
            }
        }
        
        return next
    }
    
//    func chain(fn: () -> Deferred) -> Deferred<Void> {
//        let next = Deferred<Void>()
//        
//        _callback = Closure.wrap {
//            fn().next.append(next)
//        }
//        
//        return next
//    }
    
//    func chain(fn: A -> ())  -> Deferred<Void> {
//        return _then(Closure.wrap(fn), nextDeferred: Deferred<Void>())
//    }
//    
//    func chain<T>(fn: A -> Deferred<T>)  -> Deferred<T> {
//        let next = Deferred<T>()
//        
//        _callback = Closure.wrap { (a: A) in
//            fn(a).then { s in
//                next.callback([s as! AnyObject])
//            }.error { s in
//                next.errback([s])
//            }
//        }
//        
//        return next
//    }
}













