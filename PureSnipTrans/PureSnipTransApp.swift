//
//  test4App.swift
//  test4
//
//  Created by qiuhq on 2024/10/12.
//

import SwiftUI

@main
struct test6App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() 
        }
    }
}
