//
//  GoodViewModel.swift
//  AppViewCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

import Foundation

class GoodViewModel {
    var viewModelTargetView: UIView?
    
    init() {
        NotificationCenter.default.post(name: .init("AppView_RelationSearch"), object: self)
    }
}
