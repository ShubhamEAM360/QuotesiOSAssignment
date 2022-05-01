//
//  NotionAPI.swift
//  Quotes
//
//  Created by Pizza Slice on 25/04/22.
//

import Foundation
import UIKit
import CoreData
import SwiftyJSON

enum Result<Quote,Author,Category> {
    case  Success(Quote,Author,Category)
    case  Failure(String)
}


final class NotionAPI {
    
    //MARK: - PROPERTIES
    
    private var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    private var quotes : [Quotes] = [Quotes]()
    private var categories : [Category] = [Category]()
    private var author : [Author] = [Author]()
    private let headers = [
        "Accept": "application/json",
        "Notion-Version": "2022-02-22",
        "Content-Type": "application/json",
        "Authorization": "Bearer secret_PIzzu8e5g5CZDphf6NpQRUlfPNjjcCY0Hsb9RMSmXRD"
    ]
    private let url = URL(string: "https://api.notion.com/v1/databases/57db5f822a7340fcabf493a958a75026/query")
    
    //MARK: - METHODS
    public func retriveData(completion: @escaping(Result<[Quotes],[Category],[Author]>) -> Void) {
        deleteCoreData()
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        let task =  session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.persistentContainer.performBackgroundTask { context in
                
                do {
                    if let safeData = data {
                        let json = try JSON(data: safeData)
                        let results = json["results"]
                        
                        print(results.count)
                        
                        for result in results {
                            self?.author = try context.fetch(Author.fetchRequest()) as [Author]
                            self?.categories = try context.fetch(Category.fetchRequest()) as [Category]
                            
                            let newQuote = Quotes(context:context)
                            let newAuthor = Author(context: context)
                            let newCategory = Category(context: context)
                            newQuote.text = result.1["properties"]["Quote"]["title"][0]["text"]["content"].string
                            newAuthor.name =  result.1["properties"]["Author"]["multi_select"][0]["name"].string
                            newQuote.author = newAuthor
                            newCategory.categories = result.1["properties"]["Category"]["multi_select"][0]["name"].string
                            newQuote.category = newCategory
                            do {
                                let _ = try context.save()
                            } catch {
                                debugPrint(error.localizedDescription)
                            }
                        }
                        
                        do {
                            self?.quotes = try context.fetch(Quotes.fetchRequest()) as [Quotes]
                            self?.author = try context.fetch(Author.fetchRequest()) as [Author]
                            self?.categories = try context.fetch(Category.fetchRequest()) as [Category]
                        }
                        catch {
                            debugPrint(error.localizedDescription)
                        }
                        
                        DispatchQueue.main.async {
                            completion(.Success(self?.quotes ?? [],
                                                self?.categories ?? [],
                                                self?.author ?? []))
                        }
                    }
                }
                catch {
                    return completion(.Failure(error.localizedDescription))
                }
            }
        }
        task.resume()
    }
    
    public func updateData(author: String,
                           oldQuote: String,
                           newQuote: String,
                           Category: String ) {
        let parameters = [
            "page_size": 100,
            "filter": [
                "property": "Quote",
                "rich_text": ["contains": oldQuote]
            ]
        ] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        var request = URLRequest(url: url!)
        request.httpBody = postData! as Data
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        let task =  session.dataTask(with: request) { (data, response, error) in
            if let safeData = data {
                let json = try! JSON(data: safeData)
                let results = json["results"]
                self.updatePage(id: results[0]["id"].stringValue,
                                author: author,
                                Quote: newQuote,
                                category: Category)
            }
        }
        task.resume()
    }
    
    public func updatePage(id: String,
                           author: String,
                           Quote: String,
                           category: String) {
        let parameters = [
            "parent": ["type" : "database_id" ,
                       "database_id" : "57db5f82-2a73-40fc-abf4-93a958a75026"],
            "properties" : [ "Author" : ["type" :"multi_select", "multi_select" : [ ["name" : author ]]],
                             "Category" : ["type" :"multi_select", "multi_select" : [ ["name" : category ]] ],
                             "Quote": ["title": [[ "type": "text",
                                                   "text": ["content": Quote]]]]
                           ]] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        
        let url = URL(string: "https://api.notion.com/v1/pages/\(id)")
        var request = URLRequest(url: url!)
        request.httpBody = postData! as Data
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        let task =  session.dataTask(with: request) { (data, response, error) in
            if let safeData = data {
                do {
                    let _ = try JSON(data: safeData)
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    public func addPage(quote: String,
                        author: String,
                        category: String) {
        let parameters = [
            "parent": ["type" : "database_id" ,
                       "database_id" : "57db5f82-2a73-40fc-abf4-93a958a75026"],
            "properties" : [ "Author" : ["type" :"multi_select", "multi_select" : [ ["name" : author ]]],
                             "Category" : ["type" :"multi_select", "multi_select" : [ ["name" : category ]] ],
                             "Quote": ["title": [[ "type": "text",
                                                   "text": ["content": quote ]]]]
                           ]] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        
        let url = URL(string: "https://api.notion.com/v1/pages")
        var request = URLRequest(url: url!)
        request.httpBody = postData! as Data
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        let task =  session.dataTask(with: request) { (data, response, error) in
            if let safeData = data {
                do {
                    let _ = try JSON(data: safeData)
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    public func deletePage(id: String) {
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.notion.com/v1/blocks/\(id)")! as URL)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                debugPrint(error?.localizedDescription as Any)
            } else {
                _ = response as? HTTPURLResponse
                debugPrint("Succeed")
            }
        })
        dataTask.resume()
    }
    
    public func deleteCoreData() {
        let authorRecquest : NSFetchRequest<NSFetchRequestResult>
        authorRecquest = NSFetchRequest(entityName: "Author")
        
        let categoryRecquest : NSFetchRequest<NSFetchRequestResult>
        categoryRecquest = NSFetchRequest(entityName: "Category")
        
        let quoteRecquest : NSFetchRequest<NSFetchRequestResult>
        quoteRecquest = NSFetchRequest(entityName: "Quotes")
        
        let deleteauthorRequest = NSBatchDeleteRequest(
            fetchRequest: authorRecquest
        )
        
        let deleteCategoryRequest = NSBatchDeleteRequest(
            fetchRequest: categoryRecquest
        )
        
        let deletequotesRequest = NSBatchDeleteRequest(
            fetchRequest: quoteRecquest
        )
        
        do {
            let _ = try context.execute(deleteauthorRequest)
            let _ = try context.execute(deletequotesRequest)
            let _ = try context.execute(deleteCategoryRequest)
        } catch {
            debugPrint(error.localizedDescription)
        }
        
        do {
            let _ = try context.save()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    public func deleteAuthor(author: String) {
        let parameters = [
            "filter": [
                "property": "Author",
                "multi_select": [
                    "contains": author
                ]
            ],
            "page_size": 100
        ] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        var request = URLRequest(url: url!)
        request.httpBody = postData! as Data
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        let task =  session.dataTask(with: request) { (data, response, error) in
            if let safeData = data {
                let json = try! JSON(data: safeData)
                let results = json["results"]
                for result in results{
                    dump(result.1["id"])
                    self.deletePage(id:result.1["id"].stringValue)
                }
            }
        }
        task.resume()
    }
    
    public func deleteQuote(quote: String) {
        let parameters = [
            "page_size": 100,
            "filter": [
                "property": "Quote",
                "rich_text": ["contains": quote]
            ]
        ] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        var request = URLRequest(url: url!)
        request.httpBody = postData! as Data
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        let task =  session.dataTask(with: request) { (data, response, error) in
            if let safeData = data {
                let json = try! JSON(data: safeData)
                let results = json["results"]
                self.deletePage(id: results[0]["id"].stringValue)
            }
        }
        task.resume()
    }
    
    public func deleteCategory(category: String) {
        let parameters = [
            "filter": [
                "property": "Category",
                "multi_select": [
                    "contains": category
                ]
            ],
            "page_size": 100
        ] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        var request = URLRequest(url: url!)
        request.httpBody = postData! as Data
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        let task =  session.dataTask(with: request) { (data, response, error) in
            if let safeData = data {
                let json = try! JSON(data: safeData)
                let results = json["results"]
                for result in results{
                    dump(result.1["id"])
                    self.deletePage(id:result.1["id"].stringValue)
                }
            }
        }
        task.resume()
    }
    
}

