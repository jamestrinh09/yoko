//
//  ContentView.swift
//  LearnLock
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
            .environment(AppStore())
            .environment(ScreenTimeService())
    }
}

#Preview {
    ContentView()
}
