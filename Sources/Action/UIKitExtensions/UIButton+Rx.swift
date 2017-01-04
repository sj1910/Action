#if os(iOS) || os(tvOS)
import UIKit
import RxSwift
import RxCocoa
import ObjectiveC

public extension Reactive where Base: UIButton {
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, set the rx.action to nil or another action.
    public var action: CocoaAction? {
        get {
            var action: CocoaAction?
            action = objc_getAssociatedObject(self.base, &AssociatedKeys.Action) as? Action
            return action
        }

        set {
            // Store new value.
            objc_setAssociatedObject(self.base, &AssociatedKeys.Action, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // This effectively disposes of any existing subscriptions.
            self.base.resetActionDisposeBag()
            
            // Set up new bindings, if applicable.
            if let action = newValue {
                action
                    .enabled
                    .bindTo(self.isEnabled)
                    .addDisposableTo(self.base.actionDisposeBag)
                
                // Technically, this file is only included on tv/iOS platforms,
                // so this optional will never be nil. But let's be safe 😉
                let lookupControlEvent: ControlEvent<Void>?
                
                #if os(tvOS)
                    lookupControlEvent = self.primaryAction
                #elseif os(iOS)
                    lookupControlEvent = self.tap
                #endif
                
                guard let controlEvent = lookupControlEvent else {
                    return
                }
                
                controlEvent
                    .subscribe(onNext: {
                        action.execute()
                    })
                    .addDisposableTo(self.base.actionDisposeBag)
            }
        }
    }
    
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action with given input transform.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, call bindToAction with another action or nil.
    public func bindToAction <Input,Output>(_ action:Action<Input,Output>?,_ inputTransform: @escaping (Base) -> (Input))   {
        // This effectively disposes of any existing subscriptions.
        self.base.resetActionDisposeBag()
        
        
        // If no action is provided, there is nothing left to do. All previous subscriptions are disposed.
        if (action == nil) {
            return
        }
        // Technically, this file is only included on tv/iOS platforms,
        // so this optional will never be nil. But let's be safe 😉
        let lookupControlEvent: ControlEvent<Void>?
        
        #if os(tvOS)
            lookupControlEvent = self.primaryAction
        #elseif os(iOS)
            lookupControlEvent = self.tap
        #endif
        
        guard let controlEvent = lookupControlEvent else {
            return
        }
        // For each tap event, use the inputTransform closure to provide an Input value to the action
        controlEvent
            .map { return inputTransform(self.base) }
            .bindTo(action!.inputs)
            .addDisposableTo(self.base.actionDisposeBag)
        
        // Bind the enabled state of the control to the enabled state of the action
        action!
            .enabled
            .bindTo(self.isEnabled)
            .addDisposableTo(self.base.actionDisposeBag)
        
    }
    
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action with given input value.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, call bindToAction with another action or nil.
    public func bindToAction <Input,Output>(_ action:Action<Input,Output>?, input:Input) {
        self.bindToAction(action) {_ in return input}
    }
    
}
#endif
