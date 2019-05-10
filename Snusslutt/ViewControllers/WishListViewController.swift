//
//  WishListViewController.swift
//  Snusslutt
//
//  Created by Knut Arild Slåtsve on 08/04/2019.
//  Copyright © 2019 Knut Arild Slåtsve. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class WishListTableViewCell: UITableViewCell {
    @IBOutlet weak var titleTextField: UILabel!
    @IBOutlet weak var priceTextField: UILabel!
    @IBOutlet weak var boughtTextField: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var cellBackgroundView: RoundedCornersUIView!
}


class WishListViewController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var moc:NSManagedObjectContext!
    var products = [Product]()
    var amountSaved = 0.0
    var amountSpent = 0.0
    var elapseTimeComponents = DateComponents()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        moc = appDelegate?.persistentContainer.viewContext
        self.tableView.dataSource = self
        getProducts()
        amountSaved = getAmountSaved()
        amountSpent = getAmountSpent()
    }
    
    func getProducts() {
        
        let request: NSFetchRequest<Product> = Product.fetchRequest()

        // bought, name
        let sortByName = NSSortDescriptor(key: "name", ascending: true)
        let sortByBought = NSSortDescriptor(key: "bought", ascending: true)
        request.sortDescriptors = [sortByBought, sortByName]
        
        do {
            try products = moc.fetch(request)
            self.tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    func getAmountSaved() -> Double {
        let defaults = UserDefaults.standard
        return defaults.double(forKey: "amountSaved")
    }
    
    func getAmountSpent() -> Double {
        let defaults = UserDefaults.standard
        return defaults.double(forKey: "amountSpent")
    }
    
    @IBAction func addProduct(_ sender: Any) {
        let alert = UIAlertController(title: "Nytt ønske", message: "Legg til en tittel og en pris på det du ønsker deg", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Lagre", style: .default) { (alertAction) in
            let titleTextField = alert.textFields![0] as UITextField
            let priceTextField = alert.textFields![1] as UITextField
            if titleTextField.text != "" && priceTextField.text != "" {
                let productItem = Product(context: self.moc)
                productItem.name = titleTextField.text
                let price = priceTextField.text?.replacingOccurrences(of: ",", with: ".")
                productItem.price = Double(price!)!
                productItem.bought = false
                self.appDelegate?.saveContext()
                self.getProducts()
            } else {
                print("failed reading from text fields")
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Beskrivelse"
            textField.autocapitalizationType = .sentences
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Pris"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "Avbryt", style: .cancel) { (alertAction) in
        }
        
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! WishListTableViewCell
        let product = products[indexPath.row]
        cell.titleTextField.text = product.name
        cell.priceTextField.text = "\(product.price) kr"
        if product.bought {
            cell.boughtTextField.text = "Kjøpt"
            cell.cellBackgroundView.backgroundColor = .lightGray
        } else if product.price < amountSaved {
            cell.boughtTextField.text = "Tilgjengelig!"
            cell.cellBackgroundView.backgroundColor = .green
        } else {
            cell.boughtTextField.text = "Fortsett sparingen"
            cell.cellBackgroundView.backgroundColor = .white
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        var message = ""
        if product.price < amountSaved {
            message = "Du har vært snusfri lenge nok til å kjøpe denne belønningen!"
        } else {
            message = "Hold ut litt til for å kjøpe dette produktet"
        }
        let alert = UIAlertController(title: "\(product.name!)", message: message, preferredStyle: .alert)
        
        let buyAction = UIAlertAction(title: "Kjøp", style: .default) { (alertAction) in
            do {
                product.bought = true
                let defaults = UserDefaults.standard
                let newAmountSpent = self.amountSpent + product.price
                defaults.set(newAmountSpent, forKey: "amountSpent")
                try self.moc.save()
                self.getProducts()
            } catch {
                print(error)
            }
        }
        
        let deleteAction = UIAlertAction(title: "Slett produkt", style: .destructive) {(deleteAction) in
            do {
                self.moc.delete(product)
                try self.moc.save()
                self.getProducts()
            } catch {
                print(error)
            }
        }

        
        alert.addAction(deleteAction)
        alert.addAction(buyAction)
        
        let cancelAction = UIAlertAction(title: "Avbryt", style: .cancel) { (alertAction) in
        }
        
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}
