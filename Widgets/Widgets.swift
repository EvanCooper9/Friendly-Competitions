import Firebase
import FirebaseAuthCombineSwift
import FirebaseFirestore
import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    
    init() {
        FirebaseApp.configure()
//        Auth.auth().useUserAccessGroup(BuildEnvironment.appGroup)
    }
    
    var body: some Widget {
        CompetitionsWidget()
    }
}

