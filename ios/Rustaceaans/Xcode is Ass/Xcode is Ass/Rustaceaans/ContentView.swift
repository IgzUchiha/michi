import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: selectedTab == 0 ? "photo.stack.fill" : "photo.stack")
                }
                .tag(0)
            
            MessagesListView()
                .tabItem {
                    Label("Messages", systemImage: selectedTab == 1 ? "message.fill" : "message")
                }
                .tag(1)
            
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                }
                .tag(3)
        }
        .accentColor(Color(red: 0.6, green: 0.2, blue: 0.65))
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // Selected item color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.6, green: 0.2, blue: 0.65, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.6, green: 0.2, blue: 0.65, alpha: 1.0)
            ]
            
            // Unselected item color
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.gray
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
