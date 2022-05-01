//
//  BaseController.swift
//  Quotes
//
//  Created by Pizza Slice on 26/04/22.
//

import Foundation
import UIKit

class BaseController: UIViewController {
    
    // MARK: - PROPERTIES
    
    public let CELL_ID = "CELL_ID"
    public let CLIENT_ID = "36515056899-r5mj3895sacuk2qp5k53pkc3in9tr1b7.apps.googleusercontent.com"
    
    public var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    public let notion = NotionAPI()
    
    public let randomColor: [UIColor] = [
        .systemGreen, .systemPink, .systemYellow, .systemRed, .systemCyan, .systemBlue, .systemGray, .systemPurple, .systemIndigo, .systemOrange, .systemMint, .systemTeal
    ]
    
    // MARK: - SELECTOR
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - METHODS
}
