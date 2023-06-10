//
//  ContentView.swift
//  CollinsToCoileain
//
//  Created by Jónótdón Ó Coileáin on 5/21/23.
//

import SwiftUI
import CoreData
#if os(OSX)
  import AppleScriptObjC
#endif

struct ContentView: View {
    let persistenceController = PersistenceController.shared
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.frequency, ascending: true)],
        predicate: NSPredicate(format: "filename!=nil AND definition!=nil"),
        animation: .default)
    private var Entrys: FetchedResults<Entry>
    @ObservedObject var player: Player = Player()
    @State private var searchText = ""
    @State private var localPronounciationOnly: Bool = false
    @State private var playing: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                List() {
                    ForEach(Entrys, id: \.self) { Entry in
                            if Entry.filename?.contains(searchText) == true || Entry.definition?.contains(searchText) == true || searchText.count == 0 {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(Entry.filename ?? "No Entry")
                                        Text(Entry.definition ?? "").foregroundColor(.green).padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                                    }
                                    Spacer()
                                    Button("fhuaimniú") {
                                        guard let filename = Entry.filename, filename.count > 0 else { return }
                                        //DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                                        //  guard let self = self else { return }
                                        var secondCheckArray = Entry.filename?.components(separatedBy: " ")
                                        if let sound = Bundle.main.path(forResource: Entry.filename, ofType: "mp3") {
                                            do {
                                                let fm = FileManager.default
                                                let newPath = URL.documents.appending(path: "file.mp3")
                                                if fm.fileExists(atPath: newPath.path) {
                                                    try fm.removeItem(at: newPath)
                                                }
                                                try fm.copyItem(atPath: sound, toPath: newPath.path)
                                                self.player.playLocal(word: newPath)
                                            } catch {
                                                print(error)
                                            }
                                        } else if (secondCheckArray?.count ?? 0) > 1, let sound1 = Bundle.main.path(forResource: secondCheckArray?[0] ?? "", ofType: "mp3") {
                                            
                                            secondCheckArray?.removeFirst()
                                            do {
                                                let fm = FileManager.default
                                                let newPath = URL.documents.appending(path: "file.mp3")
                                                
                                                if fm.fileExists(atPath: newPath.path) {
                                                    try fm.removeItem(at: newPath)
                                                }
                                                try fm.copyItem(atPath: sound1, toPath: newPath.path)
                                                self.player.playLocal(word: newPath)
                                            } catch {
                                                print(error)
                                            }
                                            
                                            guard let secondCheckArray = secondCheckArray else { return }
                                            for (index, word) in secondCheckArray.enumerated() {
                                                if let nextSound = Bundle.main.path(forResource: word, ofType: "mp3") {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45 * Double(index), execute: {
                                                        do {
                                                            let fm = FileManager.default
                                                            let newPath = URL.documents.appending(path: "file.mp3")
                                                            if fm.fileExists(atPath: newPath.path) {
                                                                try fm.removeItem(at: newPath)
                                                            }
                                                            try fm.copyItem(atPath: nextSound, toPath: newPath.path)
                                                            self.player.playLocal(word: newPath)
                                                        } catch {
                                                            print(error)
                                                        }
                                                    })
                                                }
                                            }
                                        } else {
                                            let arrayOfWords = filename.components(separatedBy: " ")
                                            self.player.playOnWebsite(phrase: arrayOfWords)
                                        }
                                        //}
                                    }
                                    .padding()
                                    .background(Color(red: 0.2, green: 0.1, blue: 0.345789))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .modifier(DarkModeViewModifier())
                                    //.opacity(Entry.pronounceableLocally ? 1.0 : 0.0001)
                                }
                                .swipeActions {
                                    if #available(OSX 10.14, *) {
                                        Button("Send Correction") {
                                            if let filename = Entry.filename, let encodedParams = "subject=\(filename)&body=The definition of \"\(filename)\" is:\n".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                                                let email = "jonotdon.ocoileain@gmail.com"
                                                if let url = URL(string: "mailto:\(email)?\(encodedParams)") {
                                                    #if os(iOS)
                                                    UIApplication.shared.open(url)
                                                    #endif
                                                    #if os(macOS)
                                                    let service = NSSharingService(named: NSSharingService.Name.composeEmail)
                                                    
                                                    service?.recipients = ["jonotdon.ocoileain@gmail.com"]
                                                    service?.subject = "\(filename)"
                                                    service?.perform(withItems: ["The definition of \"\(filename)\" is:\n"])
                                                    #endif
                                                }
                                            }
                                        }
                                        .tint(Color(red: 0.7, green: 0.7, blue: 1.0))
                                    }
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
                            }
                    }
                }
                .navigationTitle("Gaeilge")
                .searchable(text: $searchText)
                .disableAutocorrection(true)
            }
            
        }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear() {
                DispatchQueue.global(qos: .userInitiated).async {
                    persistenceController.readDatabase()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func addEntry() {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteEntrys(offsets: IndexSet) {
        withAnimation {
            offsets.map { Entrys[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

public struct DarkModeViewModifier: ViewModifier {
@AppStorage("isDarkMode") var isDarkMode: Bool = true
public func body(content: Content) -> some View {
    content
        .environment(\.colorScheme, isDarkMode ? .dark : .dark)
        .preferredColorScheme(isDarkMode ? .dark : .dark)
    }
}

private let EntryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

extension URL {
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension Bool {
     static var mobileOS: Bool {
         guard #available(iOS 10, *) else {
             return false
         }
         // It's iOS 14 so return false.
         return true
     }
 }
