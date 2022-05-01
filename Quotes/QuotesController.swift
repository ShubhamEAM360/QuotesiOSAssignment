//
//  QuotesController.swift
//  Quotes
//
//  Created by Pizza Slice on 11/04/22.
//

import Foundation
import UIKit
import CoreData

final class QuotesController: BaseController {
    
    // MARK: - PROPERTIES
    
    private var quotesModel = [Quotes]()
    private var authorModel = [Author]()
    private var quote: Quotes?
    private var selectedCategory: Category?
    public var category: Category?
    
    private lazy var refereshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                              primaryAction: UIAction(handler: { _ in
            self.notion.retriveData() { [unowned self] Result in
                switch Result {
                case .Success( _, _, _):
                    self.fetchQuotes()
                    self.fetchAuthor()
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                case .Failure(let error):
                    dump(error)
                }
            }
            self.collectionView.reloadData()
            self.refereshControl.endRefreshing()
        }))
        refreshControl.tintColor = .label
        return refreshControl
    }()
    
    private lazy var collectionView: UICollectionView = {
        // List Layout
        var listConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CELL_ID)
        return collectionView
    }()
    
    private lazy var tappedTextRecognize: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = buttonConfigTextRecognize()
        button.addTarget(self,
                         action: #selector(textRecognizeHandler(_:)),
                         for: .touchUpInside)
        return button
    }()
    
    private let pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.layer.masksToBounds = true
        pickerView.layer.cornerRadius = 8
        pickerView.backgroundColor = .quaternarySystemFill
        pickerView.isHidden = true
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        return pickerView
    }()
    
    private lazy var buttonMoveCategory: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = buttonConfigMoveCategory()
        let category = fetchCategories()
        let selectedCategory = category![pickerView.selectedRow(inComponent: 0)]
        button.addTarget(self,
                         action: #selector(didTapped(_:)),
                         for: .touchUpInside)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - LIFECYCLE
    
    override func loadView() {
        super.loadView()
        view = collectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = category?.categories
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.setToolbarHidden(false, animated: true)
        
        let items: [UIBarButtonItem] = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: tappedTextRecognize)
        ]
        toolbarItems = items
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "text.quote",
                                           withConfiguration: UIImage.SymbolConfiguration(textStyle: .headline)),
                            style: .done,
                            target: self,
                            action: #selector(addHandler(_:))),
        ]
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        view.addSubview(refereshControl)
        view.addSubview(pickerView)
        view.addSubview(buttonMoveCategory)
        
        setupConstraints()
        
        fetchQuotes()
        fetchAuthor()
    }
    
    // MARK: - SELECTOR
    
    // Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            pickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pickerView.widthAnchor.constraint(equalToConstant: 250),
            pickerView.heightAnchor.constraint(equalToConstant: 150),
            
            buttonMoveCategory.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 10),
            buttonMoveCategory.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            buttonMoveCategory.heightAnchor.constraint(equalToConstant: 40),
            buttonMoveCategory.widthAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    // CORE DATA ON QUOTES, AUTHOR AND CATEGORY
    
    // MARK: QUOTES DATA
    private func fetchQuotes() {
        if category?.text?.allObjects != nil {
            quotesModel = category?.text?.allObjects as! [Quotes]
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func createQuotes(text: String, category: Category) {
        let newQuotes = Quotes(context: context)
        newQuotes.text = text
        newQuotes.category = category
        notion.addPage(quote: text, author: "No Author", category: category.categories ?? "")
        do {
            try context.save()
            fetchQuotes()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func updateQuotes(quotes: Quotes, newText: String) {
        quotes.text = newText
        
        do {
            try context.save()
            fetchQuotes()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func deleteQuotes(quotes: Quotes) {
        context.delete(quotes)
        
        do {
            try context.save()
            fetchQuotes()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    //MARK: AUTHOR DATA
    private func fetchAuthor() {
        do {
            authorModel = try context.fetch(Author.fetchRequest())
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func exitingAuthor(name: String) -> [NSFetchRequestResult] {
        let moc = context
        let entityName = "Author"
        let predicate = NSPredicate(format: "SELF.name == %@", name)
        
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.includesPendingChanges = false
        fetchRequest.returnsObjectsAsFaults = false
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: moc)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        fetchRequest.predicate = predicate
        
        do {
            return try moc.fetch(fetchRequest)
        } catch  {
            debugPrint(error.localizedDescription)
            return []
        }
    }
    
    private func createAuthor(name: String, quotes: Quotes) {
        let newAuthor = exitingAuthor(name: name).first as? Author ??  Author(context: context)
        newAuthor.name = name
        notion.updatePage(id: "", author: name, Quote: "", category: "")
        quotes.author = newAuthor
        
        do {
            try context.save()
            fetchAuthor()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func updateAuthor(quotes: Quotes, newAuthor: String) {
        let author = Author(context: context)
        author.name = newAuthor
        quotes.author = author
        
        do {
            try context.save()
            fetchAuthor()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    // MARK: CATEGORY DATA
    private func fetchCategories() -> [Category]? {
        let moc = context
        let entityName = "Category"
        
        let sort = NSSortDescriptor(keyPath: \Category.categories, ascending: true)
        
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.includesPendingChanges = false
        fetchRequest.returnsObjectsAsFaults = false
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: moc)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        fetchRequest.sortDescriptors = [sort]
        
        do {
            return try moc.fetch(fetchRequest) as? [Category]
        } catch  {
            debugPrint(error.localizedDescription)
            return []
        }
    }
    
    // SOURCE VIEW & SOURCE RECT
    private func contextMenu(sourceView: UIView,
                             sourceRect: CGRect) {
        let shareSheetController = UIActivityViewController(activityItems: [],
                                                            applicationActivities: nil)
        shareSheetController.popoverPresentationController?.sourceView = sourceView
        shareSheetController.popoverPresentationController?.sourceRect = sourceRect
        present(shareSheetController, animated: true)
    }
    
    // MARK: CONFIG BUTTON
    private func buttonConfigTextRecognize() -> UIButton.Configuration {
        var config: UIButton.Configuration = .gray()
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 18)
        config.attributedTitle = AttributedString("Text Recognize", attributes: container)
        config.image = UIImage(systemName: "doc.richtext",
                               withConfiguration: UIImage.SymbolConfiguration(textStyle: .headline)
        )
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .label
        config.imagePlacement = .trailing
        config.imagePadding = 8
        return config
    }
    
    private func buttonConfigMoveCategory() -> UIButton.Configuration {
        var config: UIButton.Configuration = .tinted()
        config.title = "Save"
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .systemGreen
        return config
    }
    
    // MARK: HANDLER
    
    // New Quotes Action
    @objc
    private func addHandler(_ sender: UIButton) {
        guard let category = category else { return }
        
        let alert = UIAlertController(title: "New Quotes!",
                                      message: "Go ahead and add your new Quotes",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Quotes"
            field.returnKeyType = .next
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak self] _ in
            
            guard let fields = alert.textFields?.first else { return }
            
            guard let text = fields.text, !text.isEmpty else {
                let alert = UIAlertController(title: "ERROR",
                                              message: "Invalid entries",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self?.present(alert, animated: true)
                return
            }
            let _ = self?.createQuotes(text: text, category: category)
        }))
        let _ = present(alert, animated: true)
    }
    
    // Text Recognize Action
    @objc
    private func textRecognizeHandler(_ sender: UIButton) {
        let controller = TextRecognizeController()
        controller.completionHandler = { text in
            guard let category = self.category else { return }
            self.createQuotes(text: text ?? "Failed Text Recognize", category: category)
        }
        let _ = navigationController?.pushViewController(controller, animated: true)
    }
    
    // Move to another category Action
    @objc
    private func didTapped(_ sender: UIButton) {
        buttonMoveCategory.isHidden = true
        pickerView.isHidden = true
        
        guard let quote = quote else {
            return
        }
        selectedCategory?.addToText(quote)
        do {
            try context.save()
            fetchQuotes()
        
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
}


// MARK: - DELEGATE & DATASOURCE

extension QuotesController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return quotesModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath)
        cell.backgroundColor = .tertiarySystemBackground
        let quotesModel = quotesModel[indexPath.row]
        
        // Cell Config
        var configCell = UICollectionViewListCell().defaultContentConfiguration()
        configCell.text = quotesModel.text
        configCell.textProperties.color = .secondaryLabel
        
        if quotesModel.author?.name == nil {
            configCell.secondaryText = "No Author"
            configCell.secondaryTextProperties.color = .label
        } else {
            configCell.secondaryText = "@" + "\(quotesModel.author?.name ?? "")"
            configCell.secondaryTextProperties.color = randomColor.randomElement()!
        }
        configCell.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .caption1)
        
        cell.contentConfiguration = configCell
        
        return cell
    }
    
    //MARK: CONTEXT MENU
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let quotesModel = quotesModel[indexPath.row]
        
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            
            let tagByAuthor = UIAction(title: "Add Author",
                                       image: UIImage(systemName: "person.badge.plus"),
                                       identifier: nil,
                                       discoverabilityTitle: nil,
                                       state: .off) { [weak self] _ in
                let alert = UIAlertController(title: "Add Author",
                                              message: "Go ahead and add your favourite author",
                                              preferredStyle: .alert)
                
                alert.addTextField { field in
                    field.placeholder = "Author"
                    field.returnKeyType = .next
                }
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak self] _ in
                    guard let fields = alert.textFields?.first else { return }
                    
                    guard let text = fields.text, !text.isEmpty else {
                        let alert = UIAlertController(title: "ERROR",
                                                      message: "Invalid entries",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        let _ = self?.present(alert, animated: true)
                        return
                    }
                    let _ = self?.createAuthor(name: text, quotes: quotesModel)
                    
                    let _ = self?.notion.updateData(author: quotesModel.author?.name ?? "Error: No Author Found",
                                                    oldQuote: quotesModel.text ?? "Error: No Quotes Found",
                                                    newQuote: quotesModel.text ?? "Error: No Quotes Found",
                                                    Category: self?.category?.categories ?? "Error: No Category Found")
                }))
                let _ = self?.present(alert, animated: true)
            }
            
            let edit = UIAction(title: "Edit",
                                image: UIImage(systemName: "pencil"),
                                identifier: nil,
                                discoverabilityTitle: nil,
                                state: .off) { [weak self] _ in
                let alert = UIAlertController(title: "Edit",
                                              message: "Go ahead and edit your existing Quotes and Author",
                                              preferredStyle: .alert)
                
                alert.addTextField { field in
                    field.placeholder = "Quotes"
                    field.returnKeyType = .next
                }
                alert.addTextField { field in
                    field.placeholder = "Author"
                    field.returnKeyType = .done
                }
                
                alert.textFields?.first?.text = quotesModel.text
                alert.textFields?.last?.text = quotesModel.author?.name
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak self] _ in
                    guard let fields = alert.textFields, fields.count == 2 else {
                        return
                    }
                    
                    let quotesField = fields[0]
                    let authorField = fields[1]
                    
                    guard let quotes = quotesField.text, !quotes.isEmpty,
                          let author = authorField.text, !author.isEmpty else {
                        let alert = UIAlertController(title: "ERROR",
                                                      message: "Invalid entries",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        let _ =  self?.present(alert, animated: true)
                        return
                    }
                    let _ = self?.updateAuthor(quotes: quotesModel,
                                               newAuthor: author)
                    
                    let _ = self?.notion.updateData(author: quotesModel.author?.name ?? "Error: No Author Found",
                                                    oldQuote: quotesModel.text ?? "Error: No Quotes Found",
                                                    newQuote: quotes,
                                                    Category: self?.category?.categories ?? "Error: No Category Found")
                    
                    let _ = self?.updateQuotes(quotes: quotesModel,
                                               newText: quotes)
                }))
                let _ = self?.present(alert, animated: true)
            }
            
            let share = UIAction(title: "Share",
                                 image: UIImage(systemName: "square.and.arrow.up"),
                                 identifier: nil,
                                 discoverabilityTitle: nil,
                                 state: .off) { [weak self] _ in
                self?.contextMenu(sourceView: collectionView,
                                  sourceRect: collectionView.cellForItem(at: indexPath)?.frame ?? CGRect.zero)
            }
            
            let movetoAnotherCategory = UIAction(title: "Move to another category",
                                                 image: UIImage(systemName: "text.insert"),
                                                 identifier: nil,
                                                 discoverabilityTitle: nil,
                                                 state: .off) { [weak self] _ in
                 self?.quote = quotesModel
                 self?.pickerView.isHidden = false
                 self?.buttonMoveCategory.isHidden = false
            }
            
            let delete = UIAction(title: "Delete Author",
                                  image: UIImage(systemName: "xmark.bin"),
                                  identifier: nil,
                                  discoverabilityTitle: nil,
                                  attributes: .destructive,
                                  state: .off) { [weak self] _ in
                let alert = UIAlertController(title: "Delete Author",
                                              message: "Note: Deleting the author removes all Quotes related with the author from every categories. ",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
                    let _ = self?.notion.deleteAuthor(author: quotesModel.author?.name ?? "")
                    let _ = self?.deleteQuotes(quotes: quotesModel)
                }))
                let _ = self?.present(alert, animated: true)
            }
            
            return UIMenu(title: """
                         Add Author and Share your Quotes
                         How cool is that 😁
                         """,
                          image: nil,
                          identifier: nil ,
                          options: UIMenu.Options.displayInline,
                          children: [tagByAuthor, share, movetoAnotherCategory, edit, delete])
        }
        return config
    }
    
}

// MARK: - PICKER
extension QuotesController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fetchCategories()?.count ?? 0
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let categories = fetchCategories()
        selectedCategory = categories?[row]
        return selectedCategory?.categories
    }
}


