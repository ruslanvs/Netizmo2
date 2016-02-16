//
//  EditProfileViewController.swift
//  Netizmo
//
//  Created by Yoon, Kyle on 2/15/16.
//  Copyright © 2016 Kyle Yoon. All rights reserved.
//

import UIKit
import CloudKit

protocol EditProfileViewControllerDelegate {
    
    func didSaveProfile(profile: Profile)
    
}

class EditProfileViewController: UIViewController {
    
    let maxRequestBytes = 1000000.0
    
    @IBOutlet var needTextField: UITextField!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    
    var delegate: EditProfileViewControllerDelegate?
    var myProfile: Profile?
    var skills = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImageView.layer.cornerRadius = CGRectGetWidth(self.profileImageView.frame) / 2
        self.profileImageView.clipsToBounds = true
        
        if let myProfile = self.myProfile {
            self.needTextField.text = myProfile.need
            self.firstNameTextField.text = myProfile.firstName
            self.lastNameTextField.text = myProfile.lastName
            if let image = myProfile.profileImage {
                self.profileImageView.image = image
            }
        }
    }
    
    @IBAction func didTapProfileImage(recognizer: UITapGestureRecognizer) {
        self.setDelegateAndPresentImagePickerController()
    }
    
    @IBAction func didTapSave(sender: AnyObject) {
        let defaultPrivateDB = CKContainer.defaultContainer().privateCloudDatabase
        let myProfileRecordID = CKRecordID(recordName: "myProfile")
        // If we have a profile, then need to send that record
        var recordToUpdate: CKRecord
        if let existingProfile = self.myProfile {
            recordToUpdate = existingProfile.record
        } else {
            recordToUpdate = CKRecord(recordType: "profile", recordID: myProfileRecordID)
        }
        
        recordToUpdate[RecordKeys.FirstName.rawValue] = self.firstNameTextField.text
        recordToUpdate[RecordKeys.LastName.rawValue] = self.lastNameTextField.text
        recordToUpdate[RecordKeys.Need.rawValue] = self.needTextField.text
        if let profileImage = self.profileImageView.image {
            var compression = 1.0
            var imageData = UIImageJPEGRepresentation(profileImage, CGFloat(compression))
            
            while Double(imageData!.length) > self.maxRequestBytes && compression > 0.1 {
                compression -= 0.1
                imageData = UIImageJPEGRepresentation(profileImage, CGFloat(compression))
            }
            
            recordToUpdate[RecordKeys.ProfileImage.rawValue] = imageData
        }

        defaultPrivateDB.saveRecord(recordToUpdate, completionHandler: {
            [weak self]
            record, error in
            if let record = record {
                if let delegate = self?.delegate,
                    updatedProfile = Profile(record: record) {
                        delegate.didSaveProfile(updatedProfile)
                }
            } else {
                print("\(error)")
            }
        })
    }
    
    @IBAction func didTapCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func setDelegateAndPresentImagePickerController() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController,
            animated: true,
            completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, 
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.dismissViewControllerAnimated(true, completion: {
                    self.profileImageView.image = image
                })
            }
    }
    
}
