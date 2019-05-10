//
//  HomeViewController.swift
//  Snusslutt
//
//  Created by Knut Arild Slåtsve on 08/04/2019.
//  Copyright © 2019 Knut Arild Slåtsve. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class HomeViewController: UIViewController {
    
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var wishListButton: UIButton!
    
    
    @IBOutlet weak var timeView: RoundedCornersUIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var savingsView: RoundedCornersUIView!
    @IBOutlet weak var savingsLabel: UILabel!
    
    @IBOutlet weak var rewardView: RoundedCornersUIView!
    
    @IBOutlet weak var rewardHeaderLabel: UILabel!
    @IBOutlet weak var rewardTimeLabel: UILabel!
    @IBOutlet weak var rewardAmountSpentLabel: UILabel!
    
    
    @IBOutlet weak var rewardFooterLabel: UILabel!
    @IBOutlet weak var rewardImageView: RoundedCornersUIImageView!
    @IBOutlet weak var rewardNameLabel: UILabel!
    @IBOutlet weak var rewardPriceLabel: UILabel!
        
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var moc:NSManagedObjectContext!
    var attempts = [Attempt]()
    var products = [Product]()
    var currentAttempt: Attempt?
    var nextProduct: Product?
    var elapseTimeComponents = DateComponents()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        moc = appDelegate?.persistentContainer.viewContext
        getAttempts()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        getAttempts()
    }
    
    func getAttempts() {
        let request: NSFetchRequest<Attempt> = Attempt.fetchRequest()
        let sortByDate = NSSortDescriptor(key: "startDate", ascending: false)
        request.sortDescriptors = [sortByDate]
        
        do {
            try attempts = moc.fetch(request)
            if attempts.count != 0 {
                currentAttempt = attempts.first!
            }
            getProducts()
            setupLabels()
        } catch {
            print(error)
        }
    }
    
    func getProducts() {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        let sortByPrice = NSSortDescriptor(key: "price", ascending: true)
        request.sortDescriptors = [sortByPrice]
        
        do {
            try products = moc.fetch(request)
            if products.count != 0 {
                for product in products {
                    if (!product.bought) {
                        nextProduct = product
                        break
                    }
                }
            }
        } catch {
            print(error)
        }
    }
 
    func setupLabels() {
        if attempts.count != 0 {
            self.quitButton.setTitle("Tok en snus😔", for: .normal)
            elapseTimeComponents = Calendar.current.dateComponents([Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute], from: currentAttempt!.startDate!, to: Date())
            timeLabel.text = getTimeString()
            let amountSaved = getAmountSaved()
            savingsLabel.text = "\(amountSaved.replacingOccurrences(of: ",", with: ".")) kr"
            
            let amountSpent = getAmountSpent()
            rewardAmountSpentLabel.text = "og brukt \(amountSpent) på belønninger"
            if nextProduct != nil {
                setupNextRewardLabels(amountSaved)
            }
            
            
            
        } else {
            savingsView.isHidden = true
            rewardView.isHidden = true
        }
    }
    
    func getTimeString() -> String {
        var timeString = ""
        let days = elapseTimeComponents.day!
        let hours = elapseTimeComponents.hour!
        let minutes = elapseTimeComponents.minute!
        if (days != 0) {
            if (days == 1) {
                timeString += "\(days) dag, "
            } else {
                timeString += "\(days) dager, "
            }
        }
        if hours != 0 {
            if hours == 1 {
                timeString += "\(hours) time og "
            } else {
                timeString += "\(hours) timer og "
            }
        }
        if minutes == 1 {
            timeString += "\(minutes) minutt"
        } else {
            timeString += "\(minutes) minutter"
        }
        return timeString
    }
    
    func getAmountSaved() -> String {
        let days = elapseTimeComponents.day!
        let hours = elapseTimeComponents.hour!
        let minutes = elapseTimeComponents.minute!
        let dailySavings = Double(currentAttempt!.amount) * currentAttempt!.cost
        let timeClean = Double(days) + Double(hours)/24 + Double(minutes)/1440
        let amountSaved = dailySavings * timeClean
        let defaults = UserDefaults.standard
        defaults.set(amountSaved, forKey: "amountSaved")
        
        return String(format: "%.2f", amountSaved)
    }
    
    func getAmountSpent() -> Double {
        let defaults = UserDefaults.standard
        return defaults.double(forKey: "amountSpent")
    }
    
    func setupNextRewardLabels(_ currentAmount: String) {
        rewardNameLabel.text = nextProduct!.name
        rewardPriceLabel.text = "\(nextProduct!.price) kr"
        
        let amountSpent = getAmountSpent()
        var cash = Double(currentAmount)! - amountSpent
        let goal = nextProduct!.price
        if (cash > goal) {
            rewardHeaderLabel.text = "Hurra!🥳"
            rewardTimeLabel.text = "Du har en ny belønning!"
            rewardFooterLabel.text = "Du kan markere som kjøpt i ønskelisten"
        } else {
            rewardHeaderLabel.text = "Dersom du holder deg snusfri i"
            rewardFooterLabel.text = "så kan du kjøpe deg"
            var timeString = ""
            let dailySavings = Double(currentAttempt!.amount) * currentAttempt!.cost
            var daysRemaining = 0
            while cash < goal {
                cash += dailySavings
                daysRemaining += 1
            }
            if daysRemaining == 1 {
                timeString = "\(daysRemaining) dag til"
            } else {
                timeString = "\(daysRemaining) dager til"
            }
            rewardTimeLabel.text = timeString
        }
    }
    
    @IBAction func quit(_ sender: Any) {
        if quitButton.titleLabel?.text == "Slutt!" {
            let alert = UIAlertController(title: "Kutt snusen!", message: "Spar heller pengene til noe du ønsker deg. \nFyll inn hvor mange porsjoner du bruker hver dag, og hvor mye du betaler for en porsjon. \nEn vanlig snusboks inneholder 24 porsjoner.", preferredStyle: .alert)
            
            let saveAction = UIAlertAction(title: "SLUTT!", style: .default) { (alertAction) in
                let amountTextField = alert.textFields![0] as UITextField
                let priceTextField = alert.textFields![1] as UITextField
                if amountTextField.text != "" && priceTextField.text != "" {
                    let attemtItem = Attempt(context: self.moc)
                    attemtItem.startDate = Date()
                    let price = priceTextField.text?.replacingOccurrences(of: ",", with: ".")
                    attemtItem.cost = Double(price!)!
                    attemtItem.amount = Int16(amountTextField.text!)!
                    self.appDelegate?.saveContext()
                    self.quitButton.setTitle("Tok en snus😔", for: .normal)
                    self.getAttempts()
                }
            }
            
            alert.addTextField { (textField) in
                textField.placeholder = "Antall porsjoner daglig"
                textField.keyboardType = .numberPad
            }
            alert.addTextField { (textField) in
                textField.placeholder = "Pris pr porsjon"
                textField.keyboardType = .decimalPad
            }
            
            alert.addAction(saveAction)
            
            let cancelAction = UIAlertAction(title: "Bare en til...", style: .cancel) { (alertAction) in
            }
            
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let attemt = attempts.first
            attemt?.endDate = Date()
            do {
                try self.moc.save()
                let defaults = UserDefaults.standard
                defaults.set(0.0, forKey: "amountSpent")
                quitButton.setTitle("Slutt!", for: .normal)
            } catch {
                print(error)
            }
        }
    }
}
