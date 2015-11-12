//
//  main.swift
//  Relaunch
//
//  Created by Kumaran Vijayan on 2015-11-11.
//
//

import AppKit

class Observer: NSObject
{
    private let callback: () -> Void
    
    private init(callback: () -> Void)
    {
        self.callback = callback
        super.init()
    }
    
    override func observeValueForKeyPath(
        keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>)
    {
        callback()
    }
}

// main
autoreleasepool
{
    // get the application instance
    if let parentPID = Int32(Process.arguments[1]),
        app = NSRunningApplication(processIdentifier: parentPID),
        bundleURL = app.bundleURL
    {
        // terminate() and wait terminated.
        let listener = Observer { CFRunLoopStop(CFRunLoopGetCurrent()) }
        app.addObserver(
            listener,
            forKeyPath: "isTerminated",
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: nil)
        app.terminate()
        CFRunLoopRun() // wait KVO notification
        app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)
        
        // relaunch
        try! NSWorkspace.sharedWorkspace().launchApplicationAtURL(
            bundleURL,
            options: .Default,
            configuration: [:])
    }
}
