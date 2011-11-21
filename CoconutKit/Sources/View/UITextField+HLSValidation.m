//
//  UITextField+HLSValidation.m
//  CoconutKit
//
//  Created by Samuel Défago on 28.10.11.
//  Copyright (c) 2011 Hortis. All rights reserved.
//

#import "UITextField+HLSValidation.h"

#import "HLSCategoryLinker.h"
#import "HLSLogger.h"
#import "HLSManagedTextFieldValidator.h"
#import "HLSRuntime.h"

#import <objc/runtime.h>

HLSLinkCategory(UITextField_HLSValidation)

// Associated object keys
static void *s_validatorKey = &s_validatorKey;

// Original implementation of the methods we swizzle
static id<UITextFieldDelegate> (*s_UITextField__delegate_Imp)(id, SEL) = NULL;
static void (*s_UITextField__setDelegate_Imp)(id, SEL, id) = NULL;
void (*UITextField__setText_Imp)(id, SEL, id) = NULL;

// Extern declarations
extern BOOL injectedManagedObjectValidation(void);

#pragma mark -
#pragma mark HLSValidationPrivate UITextField category interface

@interface UITextField (HLSValidationPrivate)

- (id<UITextFieldDelegate>)swizzledDelegate;
- (void)swizzledSetDelegate:(id<UITextFieldDelegate>) delegate;
- (void)swizzledSetText:(NSString *)text;

@end

#pragma mark -
#pragma mark HLSValidation UITextField category implementation

@implementation UITextField (HLSValidation)

#pragma mark Binding to managed object fields

- (void)bindToManagedObject:(NSManagedObject *)managedObject
                  fieldName:(NSString *)fieldName 
                  formatter:(NSFormatter *)formatter
         validationDelegate:(id<HLSTextFieldValidationDelegate>)validationDelegate
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    // First unbind any bound field
    [self unbind];
    
    // No object to bind. Nothing to do
    if (! managedObject) {
        return;
    }
    
    // Bind to a validator object, with the current text field delegate as validator delegate
    HLSManagedTextFieldValidator *validator = [[[HLSManagedTextFieldValidator alloc] initWithTextField:self 
                                                                                         managedObject:managedObject
                                                                                             fieldName:fieldName 
                                                                                             formatter:formatter
                                                                                    validationDelegate:validationDelegate] 
                                               autorelease];
    if (! validator) {
        return;
    }
    
    validator.delegate = (*s_UITextField__delegate_Imp)(self, @selector(delegate));
    objc_setAssociatedObject(self, s_validatorKey, validator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Set the validator as text field delegate to catch events and perform validation. We need an intermediate object 
    // because trying to set self as delegate does not work for a UITextField (this conflicts with the text field
    // implementation and leads to infinite recursion)
    (*s_UITextField__setDelegate_Imp)(self, @selector(setDelegate:), validator);
}

- (void)unbind
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    // If not bound to a validator, nothing to do
    if (! objc_getAssociatedObject(self, s_validatorKey)) {
        return;
    }
    
    // Restore the original delegate
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    (*s_UITextField__setDelegate_Imp)(self, @selector(setDelegate:), validator.delegate);
    
    // Remove the validator
    objc_setAssociatedObject(self, s_validatorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);    
}

#pragma mark Accessors and mutators

- (NSManagedObject *)boundManagedObject
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    return validator.managedObject;
}

- (NSString *)boundFieldName
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    return validator.fieldName;
}

- (id<HLSTextFieldValidationDelegate>)validationDelegate
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    return validator.validationDelegate;    
}

- (BOOL)isCheckingOnChange
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    if (! validator) {
        HLSLoggerInfo(@"The text field has not been bound to a model object");
        return NO;
    }
    
    return validator.checkingOnChange;
}

- (void)setCheckingOnChange:(BOOL)checkingOnChange
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    if (! validator) {
        HLSLoggerError(@"The text field has not been bound to a model object");
        return;
    }
    
    validator.checkingOnChange = checkingOnChange;
}

@end

@implementation UITextField (HLSValidationPrivate)

#pragma mark Class methods

+ (void)load
{
    s_UITextField__delegate_Imp = (id<UITextFieldDelegate> (*)(id, SEL))HLSSwizzleSelector(self, @selector(delegate), @selector(swizzledDelegate));
    s_UITextField__setDelegate_Imp = (void (*)(id, SEL, id))HLSSwizzleSelector(self, @selector(setDelegate:), @selector(swizzledSetDelegate:));
    UITextField__setText_Imp = (void (*)(id, SEL, id))HLSSwizzleSelector([UITextField class], @selector(setText:), @selector(swizzledSetText:));
}

#pragma mark Swizzled method implementations

- (id<UITextFieldDelegate>)swizzledDelegate
{
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    if (validator) {
        return validator.delegate;
    }
    else {
        return (*s_UITextField__delegate_Imp)(self, @selector(delegate));
    }
}

- (void)swizzledSetDelegate:(id<UITextFieldDelegate>)delegate
{
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    if (validator) {
        validator.delegate = delegate;
    }
    else {
        (*s_UITextField__setDelegate_Imp)(self, @selector(setDelegate:), delegate);
    }
}

- (void)swizzledSetText:(NSString *)text
{
    HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
    if (validator) {
        // Formatters does not always handle nil strings gracefully. Fix
        id value = nil;
        [validator getValue:&value forString:text ?: @""];
        [self.boundManagedObject setValue:value forKey:self.boundFieldName];
    }
    else {
        (*UITextField__setText_Imp)(self, @selector(setText:), text);
    }    
}

@end

#pragma mark -
#pragma mark HLSValidation UIView category implementation

@implementation UIView (HLSValidation)

- (BOOL)checkTextFields
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    // Check self first (if bound to a validator)
    BOOL valid = YES;
    if ([self isKindOfClass:[UITextField class]]) {
        HLSManagedTextFieldValidator *validator = objc_getAssociatedObject(self, s_validatorKey);
        if (validator && ! [validator checkDisplayedValue]) {
            valid = NO;
        }
    }
    
    // Check subviews recursively
    for (UIView *subview in self.subviews) {
        if (! [subview checkTextFields]) {
            valid = NO;
        }
    }
    
    return valid;
}

@end

#pragma mark -
#pragma mark HLSValidation UIViewController category implementation

@implementation UIViewController (HLSValidation)

- (BOOL)checkTextFields
{
    NSAssert(injectedManagedObjectValidation(), @"Managed object validation not injected. Call HLSEnableNSManagedObjectValidation first");
    
    if (! [self isViewLoaded]) {
        HLSLoggerError(@"The view controller's view has not been loaded yet");
        return NO;
    }
    
    return [self.view checkTextFields];
}

@end
