//
//  ViewController.swift
//  ArtBookProject
//
//  Created by Görkem Güray on 20.08.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedPainting = ""
    var selectedPaintingId:UUID?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newData"), object: nil)
    }
    

    @objc func addButtonClicked() {
        
        selectedPainting = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        
        content.text = nameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
        
    }
    
   @objc func getData () {
        
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        // context'e ihtiyacımız var yine, bu sebeple context oluşturma işlemi yapılıyor.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // context.fetch() metodunun çağrılabilmesi için fetchRequest'e ihtiyacımız var.
        //tanımlaması burada yapılıyor.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
        fetchRequest.returnsObjectsAsFaults = false //veriler daha hızlı gelsin diye
        
        do {
            //veritabanından veri bu aşamada çekildi.
            let results = try context.fetch(fetchRequest)
            
            //çekilen veri NSManagedObject olarak cast ediliyor.
            for result in results as! [NSManagedObject] {
                //.value metodu ile anahtarı verekek veriyi alabiliyoruz.
                if let name = result.value(forKey: "name") as? String {
                    
                    self.nameArray.append(name)
                    
                }
                
                if let id = result.value(forKey: "id") as? UUID {
                    self.idArray.append(id)
                }
                
                self.tableView.reloadData()
            }
            
        } catch {
            print("Error")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            
            let destinationVC = segue.destination as! DetailsVC
            destinationVC.chosenPainting = selectedPainting
            destinationVC.chosenPaintindId = selectedPaintingId
            
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPainting = nameArray[indexPath.row]
        selectedPaintingId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //gerçekten delete işlemi mi yapmış kullanıcı onu kontrol ediyoruz.
        if editingStyle == .delete {
            //standart context'i oluşturuyoruz.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            
            let idString = idArray[indexPath.row].uuidString
            
            //bu noktada predicate ile filtreleme işlemi yapıyoruz.
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == idArray[indexPath.row] {
                                //core data silme işlemi burada yapılıyor.
                                context.delete(result)
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    //core data save ediliyor tekrar
                                    try context.save()
                                } catch {
                                    print("Error")
                                }
                                
                                break
                            }
                            
                        }
                        
                    }
                    
                    
                }
            } catch {
                print("Silmede hata")
                
            }
            
            
        }
    } //
    
}

