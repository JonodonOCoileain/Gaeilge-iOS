//
//  Persistence.swift
//  CollinsToCoileain
//
//  Created by Jónótdón Ó Coileáin on 5/21/23.
//

import CoreData
import SwiftUI
import SQLite3
import SQLite

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
    
    func copyDataBase(path: String) -> String? {
        let fileManager = FileManager.default
        var dbPath = ""
        let dbFileName = "entries.sqlite"

        do {
            dbPath = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(dbFileName).path
        } catch {
            print(error.localizedDescription)
            return nil
        }

        if !fileManager.fileExists(atPath: dbPath) {
            let dbResourcePath = Bundle.main.path(forResource: "entries", ofType: "sqlite")
            do {
                try fileManager.copyItem(atPath: dbResourcePath!, toPath: dbPath)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        return dbPath
    }
    
    func readDatabase() {
        if UserDefaults.standard.bool(forKey: "v3") != true {
            UserDefaults.standard.removeObject(forKey: "finishedLoading")
            UserDefaults.standard.removeObject(forKey: "allFinishedLoading")
            let fm = FileManager.default
        
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                
                let viewContext = self.container.viewContext
                let dbName = "entries.sqlite"
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let dbPath = paths[0].path + "/" + dbName
                guard let newPath = self.copyDataBase(path: dbPath) else {
                    return
                }
                do {
                    let db = try Connection(newPath)
                    let queryStatementString = "SELECT * FROM entries;"
                    let response = try db.prepare(queryStatementString)
                    for row in response {
                        let word = "\(row[0] ?? 0)"
                        let definition = "\(row[1] ?? 0)"
                        let frequency = "\(row[2] ?? 0)"
                        var pronounceableLocally = "\(row[3] ?? 0)"
                        let fetchRequest = NSFetchRequest<Entry>(entityName: "Entry")
                        fetchRequest.predicate = NSPredicate(format: "filename == %@", word)
                        var result = [Entry]()
                        
                        do {
                            result = try viewContext.fetch(fetchRequest)
                        } catch {
                            print(error)
                        }
                        if result.isEmpty {
                            let array = word.components(separatedBy: " ")
                            if array.count > 1 {
                                if let path = Bundle.main.path(forResource: array.first ?? "", ofType: "mp3") {
                                    do {
                                        let attr = try fm.attributesOfItem(atPath: path)
                                        if (attr[.size] as? Int ?? 0) > 150 {
                                            pronounceableLocally = "1"
                                        }
                                    } catch {
                                        print(error)
                                    }
                                } else if let path = Bundle.main.path(forResource: array[1] ?? "", ofType: "mp3") {
                                    do {
                                        let attr = try fm.attributesOfItem(atPath: path)
                                        if (attr[.size] as? Int ?? 0) > 150 {
                                            pronounceableLocally = "1"
                                        }
                                        print("File size = \(attr[.size])")
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                            do {
                                let newEntry = Entry(context: viewContext)
                                newEntry.timestamp = Date()
                                newEntry.filename = word
                                newEntry.frequency = Int64(frequency) ?? 0
                                newEntry.definition = definition
                                newEntry.pronounceableLocally = pronounceableLocally != "0"
                                try viewContext.save()
                            } catch {
                                print(error)
                            }
                        }
                        if word == "zú" {
                            if UserDefaults.standard.bool(forKey: "v3") != true {
                                UserDefaults.standard.set(true, forKey: "v3")
                            }
                        }
                    }
                } catch {
                    print("Unable to connect to database.")
                }
            }
        }
    }
    
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
