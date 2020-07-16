//
//  Scan.swift
//  Pods-RxSwiftPlayground
//
//  Created by Ahmed Ali Henawey on 13/07/2020.
//

import Foundation
import RxSwift
import RxCocoa

class Scan {
    let disposeBag = DisposeBag()
    
    enum Action {
        case add(String)
        case delete(String)
    }
    let actionUserInput = PublishSubject<Action>()

    func start() -> Observable<[String]> {
        actionUserInput.asObservable()
            .scan(into: [String]()) { (values, action) in
                // update state here
            switch action {
            case .add(let filter):
                values.append(filter)
            case .delete(let filter):
                values.removeAll { $0 == filter }
            }
        }
    }

    func main() {
        start().debug().subscribe().disposed(by: disposeBag)
        actionUserInput.onNext(.add("Date filter"))
        actionUserInput.onNext(.add("Amount filter"))
        actionUserInput.onNext(.delete("Amount filter"))
    }
}


