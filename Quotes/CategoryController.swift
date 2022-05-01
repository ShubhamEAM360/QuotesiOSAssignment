//
//  CategoryController.swift
//  Quotes
//
//  Created by Pizza Slice on 11/04/22.
//

import Foundation
import UIKit
import CoreData

final class CategoryController: BaseController {
    
    // MARK: - PROPERTIES
    
    private var models = [Category]()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds,
                                              collectionViewLayout: createLayout())
        collectionView.register(UICollectionViewCell.self,
                                forCellWithReuseIdentifier: CELL_ID)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var refereshControll: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                              primaryAction: UIAction(handler: { [unowned self] _ in
            self.notion.retriveData() { [unowned self] Result in
                switch Result {
                case .Success ( _, _, _):
                    self.fetchCategories()
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                case .Failure(let error):
                    dump(error)
                }
            }
            self.collectionView.reloadData()
            self.refereshControll.endRefreshing()
        }))
        refreshControl.tintColor = .label
        return refreshControl
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Add new Category"
        label.font = UIFont(name: "Academy Engraved LET", size: 25)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tappedAddCategory: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = buttonConfig()
        button.addTarget(self,
                         action: #selector(addCategoryHandler(_:)),
                         for: .touchUpInside)
        return button
    }()
    
    // MARK: - LIFECYCLE
    
    override func loadView() {
        super.loadView()
        view = collectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        navigationItem.title = "Category"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .label
        navigationController?.toolbar.tintColor = .label
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.setToolbarHidden(false,
                                               animated: true)
        
        let items: [UIBarButtonItem] = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                            target: nil,
                            action: nil),
            UIBarButtonItem(customView: tappedAddCategory),
        ]
        toolbarItems = items
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(signOutHandler(_:)))
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.addSubview(refereshControll)
        collectionView.addSubview(categoryLabel)
        
        setupConstraints()
        
        fetchCategories()
    }
    
    // MARK: - SELECTOR
    
    // Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                               constant: 115),
            categoryLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            categoryLabel.heightAnchor.constraint(equalToConstant: 60),
            categoryLabel.widthAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    // CORE DATA
    private func fetchSortedCategories() -> [Category]? {
        let moc = context
        let entityName = "Category"
        
        let sort = NSSortDescriptor(keyPath: \Category.createdAt, ascending: false)
        
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
    
    private func fetchCategories() {
        models = fetchSortedCategories() ?? []
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func createCategories(categories: String) {
        let newCategories = Category(context: context)
        newCategories.createdAt = Date.now
        newCategories.categories = categories
        
        do {
            try context.save()
            fetchCategories()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func updateCategories(categories: Category, newCategories: String) {
        categories.categories = newCategories
        
        do {
            try context.save()
            fetchCategories()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func deleteCategories(categories: Category) {
        context.delete(categories)
        
        do {
            try context.save()
            fetchCategories()
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    // MARK: LAYOUT
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(80))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: 2)
        let spacing = CGFloat(10)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: 10,
                                                        bottom: 0,
                                                        trailing: 10)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    // MARK: CONFIG BUTTON
    private func buttonConfig() -> UIButton.Configuration {
        var config: UIButton.Configuration = .gray()
        var container = AttributeContainer()
        container.font = UIFont.boldSystemFont(ofSize: 18)
        config.attributedTitle = AttributedString("Add Category",
                                                  attributes: container)
        config.image = UIImage(systemName: "text.badge.plus",
                               withConfiguration: UIImage.SymbolConfiguration(textStyle: .headline)
        )
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .label
        config.imagePlacement = .trailing
        config.imagePadding = 8
        return config
    }
    
    // MARK: HANDLER
    
    // Add Category Action
    @objc
    private func addCategoryHandler(_ sender: UIButton) {
        let alert = UIAlertController(title: "New Category!",
                                      message: "Go ahead and add your new category",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Category"
            field.returnKeyType = .done
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak self] _ in
            guard let field = alert.textFields?.first else {
                return
            }
            guard let text = field.text, !text.isEmpty else {
                let alert = UIAlertController(title: "ERROR",
                                              message: "Invalid entries",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                let _ = self?.present(alert, animated: true)
                return
            }
            self?.categoryLabel.isHidden = true
            let _ = self?.createCategories(categories: text)
        }))
        present(alert, animated: true)
    }
    
    // Sign Out Action
    @objc
    private func signOutHandler(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Sign Out",
                                            message: """
        You are trying to sign out of the application
        Think Seriously!
        """,
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [weak self] _ in
            let _ = self?.dismiss(animated: true)
        }))
        actionSheet.popoverPresentationController?.sourceView = view
        actionSheet.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        let _ = present(actionSheet, animated: true)
    }
    
}


// MARK: - DELEGATE & DATASOURCE

extension CategoryController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if models.isEmpty {
            categoryLabel.isHidden = false
        } else {
            categoryLabel.isHidden = true
        }
        
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath)
        
        // CONFIG CELL
        cell.backgroundColor = randomColor.randomElement()
        cell.layer.cornerRadius = 6
        cell.layer.masksToBounds = true
        var cellConfig = UICollectionViewListCell().defaultContentConfiguration()
        cellConfig.text = models[indexPath.row].categories
        cell.contentConfiguration = cellConfig
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let controller   = QuotesController()
        controller.category = models[indexPath.row]
        let _ = navigationController?.pushViewController(controller, animated: true)
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let model = models[indexPath.row]
        
        let config = UIContextMenuConfiguration(identifier: nil,
                                                previewProvider: nil) { _ in
            let edit = UIAction(title: "Edit",
                                image: UIImage(systemName: "pencil"),
                                identifier: nil,
                                discoverabilityTitle: nil,
                                state: .off) { [weak self] _ in
                let alert = UIAlertController(title: "Edit Category",
                                              message: "Go ahead and edit your existing category",
                                              preferredStyle: .alert)
                
                alert.addTextField { field in
                    field.placeholder = "Category"
                    field.returnKeyType = .next
                }
                alert.textFields?.first?.text = model.categories
                
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
                    let _ = self?.updateCategories(categories: model, newCategories: text)
                }))
                let _ = self?.present(alert, animated: true)
            }
            let delete = UIAction(title: "Delete",
                                  image: UIImage(systemName: "xmark.bin"),
                                  identifier: nil,
                                  discoverabilityTitle: nil,
                                  attributes: .destructive,
                                  state: .off) { [weak self] _ in
                let _ = self?.notion.deleteCategory(category: model.categories ?? "Nothing Found")
                let _ = self?.deleteCategories(categories: model)
            }
            return UIMenu(title: "Category",
                          image: nil,
                          identifier: nil ,
                          options: UIMenu.Options.displayInline,
                          children: [edit, delete])
        }
        return config
    }
    
}
