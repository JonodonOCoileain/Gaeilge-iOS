//
//  Persistence.swift
//  CollinsToCoileain
//
//  Created by Jónótdón Ó Coileáin on 5/21/23.
//

import CoreData
import SwiftUI


class PersistenceController {
    static let shared = PersistenceController()
    static let examples: [String: String] = ["a aithint" : "vb to recognise",
                                             "a dó" : "nmmm two",
                                             "ab" : "nm3 abbot",
                                             "abair" : "vb recite [prayer], say, suppose [mathematics]",
                                             "abairt" : "nf2 phrase, sentence", "ábalta" : "vb able",
                                             "ábaltacht" : "nf3 ability", "abhac" : "nmmm dwarf",
                                             "abhaile" : "adv home, homewards", "abhainn" : "nfff river",
                                             "ábhar" : "nmmm subject, topic",
                                             "abhatár" : "nm4 avatar"]
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<examples.count {
            let newEntry = Entry(context: viewContext)
            newEntry.timestamp = Date()
            newEntry.filename = examples.keys.sorted()[i]
            newEntry.definition = examples[examples.keys.sorted()[i]]
            newEntry.pronounceableLocally = true
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    var isEmpty: Bool {
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
            let count  = try self.container.viewContext.count(for: request)
            return count == 0
        } catch {
            return true
        }
    }
    
    var count: Int {
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
            let count  = try self.container.viewContext.count(for: request)
            return count
        } catch {
            return 0
        }
    }
    
    func countAr() -> Int {
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
            request.predicate = NSPredicate(format: "filename == %@","ar")
            let count  = try self.container.viewContext.count(for: request)
            
            let request2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
            request2.predicate = NSPredicate(format: "filename == %@","ar ")
            let count2  = try self.container.viewContext.count(for: request2)
            
            return count + count2
        } catch {
            return 0
        }
    }
    
    var definedCount: Int {
        do {
            let request = NSFetchRequest<Entry>(entityName: "Entry")
            request.predicate = NSPredicate(format: "definition!=nil")
            let results  = try self.container.viewContext.fetch(request)
            return results.count
        } catch {
            return 0
        }
    }
    
    static var partOfSpeechPlaceholders: [String] = ["plc", "adv", "n3", "n4", "nf","n1","n2","nf1","nf2","nf3","nf4","nf5","nm","nm1","nm2","nm3","nm4","nm5","vb","adjn","adj","nmbr", "n", "prep", "npl", "prefx","cnj","cphrs","pron", "nmadj", "nidiom", "nadj", "adjf"]
    
    func deleteAll() {
        let request = NSFetchRequest<Entry>(entityName: "Entry")
        do {
            let results  = try self.container.viewContext.fetch(request)
            for result in results {
                self.container.viewContext.delete(result)
            }
            try self.container.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func resetContext() {
        self.container.viewContext.reset()
    }
    
    func readData() {
        if UserDefaults.standard.bool(forKey: "finishedLoading") == true {
            deleteAll()
            return
        }
        
        if count >= 1996 && definedCount >= 848 {
            UserDefaults.standard.set(true, forKey: "finishedLoading")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let viewContext = self?.container.viewContext else { return }
            if let fileURL = Bundle.main.url(forResource: "entries", withExtension: "csv") {
                // make sure the file exists
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    preconditionFailure("file expected at \(fileURL.path) is missing")
                }
                
                do {
                    let data = try String(contentsOfFile: fileURL.path, encoding: .utf8)
                    let myStrings = data.components(separatedBy: .newlines)
                    for string in myStrings {
                        
                        var components = string.components(separatedBy: ",")
                        guard components.count > 1 else { continue }
                        let word = components.removeLast()
                        let frequencyRank = components.removeFirst()
                        let pronounceableLocally = components.removeFirst() == "1"
                        let definition = components.joined(separator: ",")
                        
                        let fetchRequest = NSFetchRequest<Entry>(entityName: "Entry")
                        fetchRequest.predicate = NSPredicate(format: "filename == %@", word)
                        // Helpers
                        DispatchQueue.main.async {
                            var result = [Entry]()
                            
                            do {
                                result = try viewContext.fetch(fetchRequest)
                            } catch {
                                print(error)
                            }
                            
                            if result.isEmpty && word.count > 0 {
                                do {
                                    let newEntry = Entry(context: viewContext)
                                    newEntry.timestamp = Date()
                                    newEntry.filename = word
                                    if word == "an" {
                                        newEntry.definition = "the"
                                    }
                                    if word == "is" {
                                        newEntry.definition = "is"
                                    }
                                    if word == "bí" {
                                        newEntry.definition = "be"
                                    }
                                    newEntry.frequency = Int64(frequencyRank) ?? 0
                                    newEntry.definition = definition
                                    newEntry.pronounceableLocally = pronounceableLocally
                                    try viewContext.save()
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                    
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func allEntriesData() {
        if countAr() > 1 {
            deleteAll()
            UserDefaults.standard.set(false, forKey: "finishedLoading")
            UserDefaults.standard.removeObject(forKey: "finishedLoading")
        }
        
        if UserDefaults.standard.bool(forKey: "finishedLoading") == true {
            if UserDefaults.standard.bool(forKey: "allFinishedLoading") != true {
                deleteAll()
            }
            UserDefaults.standard.set(false, forKey: "finishedLoading")
            UserDefaults.standard.removeObject(forKey: "finishedLoading")
            return
        }
        
        if UserDefaults.standard.bool(forKey: "allFinishedLoading") == true {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let viewContext = self?.container.viewContext else { return }
            if let fileURL = Bundle.main.url(forResource: "allEntries", withExtension: "txt") {
                // make sure the file exists
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    preconditionFailure("file expected at \(fileURL.path) is missing")
                }
                
                do {
                    let data = try String(contentsOfFile: fileURL.path, encoding: .utf8)
                    let myStrings = data.components(separatedBy: .newlines)
                    for string in myStrings {
                        guard string.count > 1 else { continue }
                        var separated = string.components(separatedBy: " ")
                        
                        let fileExists = separated.removeLast()
                        let occurenceDenominator = Int64(separated.removeLast())
                        
                        var word: String?
                        if let firstIndexOfSeparator = separated.firstIndex(where: { PersistenceController.partOfSpeechPlaceholders.contains($0) }) {
                            let separator = separated[firstIndexOfSeparator]
                            word = string.components(separatedBy: separator).first?.trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            word = separated.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        guard let word = word else { continue }
                        
                        for component in separated {
                            if word.contains(component) {
                                separated.removeFirst()
                            } else {
                                break
                            }
                        }
                        var definition = separated.joined(separator: " ")
                        
                        let fetchRequest = NSFetchRequest<Entry>(entityName: "Entry")
                        fetchRequest.predicate = NSPredicate(format: "filename == %@", word)
                        // Helpers
                        DispatchQueue.main.async {
                            var result = [Entry]()
                            
                            do {
                                result = try viewContext.fetch(fetchRequest)
                            } catch {
                                print(error)
                            }
                            
                            if word == "an" {
                                definition = "the"
                            } else if word == "is" {
                                definition = "is"
                            } else if word == "bí" {
                                definition = "be"
                            } else if word == "agus" {
                                definition = "and"
                            }
                            
                            if result.isEmpty && word.count > 0 {
                                do {
                                    let newEntry = Entry(context: viewContext)
                                    newEntry.timestamp = Date()
                                    newEntry.filename = word
                                    newEntry.frequency = occurenceDenominator ?? 400000
                                    newEntry.definition = definition
                                    newEntry.pronounceableLocally = fileExists == "1"
                                    try viewContext.save()
                                    
                                    if string == "facs 350594 1" {
                                        UserDefaults.standard.set(true, forKey: "allFinishedLoading")
                                    }
                                } catch {
                                    print(error)
                                }
                            } else if word.count > 0, result.isEmpty == false, let entry = result.first {
                                do {
                                    if let occurenceDenominator = occurenceDenominator, entry.frequency > occurenceDenominator {
                                        entry.frequency = occurenceDenominator
                                    }
                                    if entry.definition == nil {
                                        entry.definition = definition
                                    }
                                    if fileExists == "1" {
                                        entry.pronounceableLocally = true
                                    }
                                    try viewContext.save()
                                    if string == "facs 350594 1" {
                                        UserDefaults.standard.set(true, forKey: "allFinishedLoading")
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                            
                        }
                    }
                    
                } catch {
                    print(error)
                }
            }
        }
    }
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CollinsToCoileain")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
