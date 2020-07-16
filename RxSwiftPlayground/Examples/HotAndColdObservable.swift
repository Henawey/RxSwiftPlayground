//
//  HotAndColdObservable.swift
//  RxSwiftPlayground
//
//  Created by Ahmed Ali Henawey on 13/07/2020.
//  Copyright © 2020 Ahmed Ali Henawey. All rights reserved.
//

import Foundation
import RxSwift


class Producer {
    private var count = 0
    private var timer: Timer?
    private var listeners: [(Int) -> Void] = []

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.listeners.forEach{ $0(self.count) }
            self.count += 1
        }
    }

    func addListener(listener: @escaping (Int) -> Void) {
        listeners.append(listener)
    }

    func stop() {
        timer?.invalidate()
    }

    deinit {
        stop()
    }
}

class HotAndColdObservable {
    let disposeBag = DisposeBag()

    //Cold Observables: Producers created *inside*
    //An observable is “cold” if its underlying producer is created and activated during subscription. This means, that if observables are functions, then the producer is created and activated by calling that function.
    // - creates the producer
    // - activates the producer
    // - starts listening to the producer
    // - unicast
    //The example below is “cold” because it creates and listens to the Timer inside of the subscriber function that is called when you subscribe to the Observable:

    func createColdObservable() -> Observable<Int> {
        return Observable.create { observer -> Disposable in
            let producer = Producer()
            producer.addListener { tick in
                observer.onNext(tick)
            }
            return Disposables.create {
                producer.stop()
            }
        }
    }
    func coldTest() {
        let cold1 = createColdObservable()
        let cold2 = createColdObservable()

        cold1.debug("cold 1")
            .subscribe()
            .disposed(by: disposeBag)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            cold2.debug("   cold 2")
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }

    // An observable is “hot” if its underlying producer is either created or activated outside of subscription.
    // - shares a reference to a producer
    // - starts listening to the producer
    // - multicast (usually)
    // If we were to take our example above and move the creation of the Timer outside of our observable it would become “hot”:
    let producer = Producer()
    func createHotObservable() -> Observable<Int> {
        return Observable.create { [unowned self] observer -> Disposable in
            self.producer.addListener { tick in
                observer.onNext(tick)
            }
            return Disposables.create()
        }
    }
    func hotTest() {
        let hot1 = createHotObservable()
        let hot2 = createHotObservable()
        hot1.debug("hot 1 subscription:1")
            .subscribe()
            .disposed(by: disposeBag)

        hot1.debug("    hot 1 subscription:2")
            .subscribe()
            .disposed(by: disposeBag)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            hot2.debug("        hot 2")
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }

    // Making A Cold Observable Hot without ref count
    // TODO: Please find the bug
    func makeHot<T>(cold: Observable<T>) -> Observable<T> {
        let subject = PublishSubject<T>()
        let coldDisposable = cold.subscribe(subject)
        return Observable<T>.create { observer -> Disposable in
            let subjectDisposable = subject.subscribe(observer)
            return Disposables.create([coldDisposable, subjectDisposable])
        }
    }
    func coldToHotTest() {
        let cold = createColdObservable()
            .debug("cold coldToHot")
        let hot = makeHot(cold: cold).debug("hot coldToHot")
        let hot1Disposable = hot.debug("    hot coldToHot subscription:1")
            .subscribe()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            _ = hot.debug("         hot coldToHot subscription:2")
                .subscribe()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            hot1Disposable.dispose()
        }
    }

    func makeHotRefCounted<T>(cold: Observable<T>) -> Observable<T> {
        let subject = PublishSubject<T>()
        let coldDisposable = cold.subscribe(subject)
        var subscriptionRefs = 0
        return Observable<T>.create { observer -> Disposable in
            subscriptionRefs += 1
            let subjectDisposable = subject.subscribe(observer)
            return Disposables.create {
                subscriptionRefs -= 1
                subjectDisposable.dispose()
                if subscriptionRefs == 0 {
                    coldDisposable.dispose()
                }
            }
        }
    }
    func coldToHotRefCountedTest() {
        let cold = createColdObservable()
            .debug("cold coldToHotRefCounted")
        let hotRefCounted = makeHotRefCounted(cold: cold)
        let hot1RefCountedDisposable = hotRefCounted.debug("    hot coldToHotRefCounted subscription:1")
            .subscribe()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            hot1RefCountedDisposable.dispose()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let hot2RefCountedDisposable = hotRefCounted.debug("        hot coldToHotRefCounted subscription:2")
                .subscribe()
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                hot2RefCountedDisposable.dispose()
            }
        }
    }

    func makeHotOutOfTheBox<T>(cold: Observable<T>) -> Observable<T> {
        return cold.share()
//        return cold.publish().refCount()
    }

    func coldToHotOutOfTheBoxTest() {
        let cold = createColdObservable()
            .debug("cold coldToHotOutOfTheBox")
        let hotOutOfTheBox = makeHotOutOfTheBox(cold: cold)
        let hot1OutOfTheBoxDisposable = hotOutOfTheBox.debug("  hot coldToHotOutOfTheBox subscription:1")
            .subscribe()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            hot1OutOfTheBoxDisposable.dispose()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let hot2OutOfTheBoxDisposable = hotOutOfTheBox.debug("      hot coldToHotOutOfTheBox subscription:2")
                .subscribe()
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                hot2OutOfTheBoxDisposable.dispose()
            }
        }
    }

    func main() {
//        coldTest()

//        hotTest()

//        coldToHotTest()

//        coldToHotRefCountedTest()

//        coldToHotOutOfTheBoxTest()
    }
}
