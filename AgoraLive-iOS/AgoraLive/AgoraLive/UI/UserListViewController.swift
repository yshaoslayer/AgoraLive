//
//  UserListViewController.swift
//  AgoraLive
//
//  Created by CavanSu on 2020/3/27.
//  Copyright © 2020 Agora. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

protocol UserListCellDelegate: NSObjectProtocol {
    func tapInviteButton(cell: UserListCell)
}

class UserListCell: UITableViewCell {
    @IBOutlet var headImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    
    fileprivate weak var delegate: UserListCellDelegate?
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let color = UIColor(hexString: "#D8D8D8")
        let x: CGFloat = 15.0
        let width = UIScreen.main.bounds.width - (x * 2)
        self.contentView.containUnderline(color,
                                          x: x,
                                          width: width)
        
        self.inviteButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.delegate?.tapInviteButton(cell: self)
        }).disposed(by: bag)
    }
}

class UserListViewController: UITableViewController {
    enum ShowType {
        case broadcasting, pk, allUser
        
        var buttonDescription: String {
            switch self {
            case .broadcasting: return NSLocalizedString("Invite_Broadcasting")
            case .pk:           return NSLocalizedString("Invite_PK")
            case .allUser:      return NSLocalizedString("")
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    private let bag = DisposeBag()
    
    // Rx
    var selectedInviteAudience = PublishRelay<RemoteAudience>()
    var selectedInviteRoom = PublishRelay<RoomBrief>()
    
    var userList: [RemoteAudience]? {
        didSet {
            if showType == .allUser {
                self.titleLabel.text = NSLocalizedString("User_List") + "(\(userList?.count ?? 0))"
            }
            
            tableView.reloadData()
        }
    }
    
    var roomList: [RoomBrief]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    var showType: ShowType = .broadcasting
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 48
        let color = UIColor(hexString: "#D8D8D8")
        let x: CGFloat = 15.0
        let width = UIScreen.main.bounds.width - (x * 2)
        self.titleLabel.containUnderline(color,
                                         x: x,
                                         width: width)
        switch showType {
        case .broadcasting: self.titleLabel.text = NSLocalizedString("Invite_Broadcasting")
        case .pk:           self.titleLabel.text = NSLocalizedString("Invite_PK")
        case .allUser:      self.titleLabel.text = NSLocalizedString("User_List") + "(\(userList?.count ?? 0))"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch showType {
        case .broadcasting, .allUser:
            return userList?.count ?? 0
        case .pk:
            return roomList?.count ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserListCell", for: indexPath) as! UserListCell
        cell.inviteButton.setTitle(showType.buttonDescription, for: .normal)
        cell.delegate = self
        let images = ALCenter.shared().centerProvideImagesHelper()
        switch showType {
        case .broadcasting, .allUser:
            let user = userList![indexPath.row]
            cell.nameLabel.text = user.info.name
            cell.headImageView.image = images.getHead(index: user.info.imageIndex)
            if showType == .allUser {
                cell.inviteButton.isHidden = true
            }
        case .pk:
            let room = roomList![indexPath.row]
            cell.nameLabel.text = room.name
            cell.headImageView.image = images.getHead(index: room.imageIndex)
        }
        return cell
    }
}

extension UserListViewController: UserListCellDelegate {
    func tapInviteButton(cell: UserListCell) {
        guard let index = self.tableView.indexPath(for: cell) else {
            return
        }
        
        switch showType {
        case .broadcasting:
            let audience = userList![index.row]
            self.selectedInviteAudience.accept(audience)
        case .pk:
            let room = roomList![index.row]
            self.selectedInviteRoom.accept(room)
        case .allUser:
            break
        }
    }
}
