/* Cydia Substrate - Meta-Library Insert for iPhoneOS
 * Copyright (C) 2008  Jay Freeman (saurik)
*/

/*
 *        Redistribution and use in source and binary
 * forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer in the documentation
 *    and/or other materials provided with the
 *    distribution.
 * 3. The name of the author may not be used to endorse
 *    or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIKit.h>

#import <SpringBoard/SBAlertItem.h>
#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBContentLayer.h>
#import <SpringBoard/SBStatusBarController.h>
#import <SpringBoard/SBStatusBarTimeView.h>

#import <SpringBoard/SBSlidingAlertDisplay.h>

#include <substrate.h>

@protocol MobileSubstrate
- (id) ms$initWithSize:(CGSize)size;
- (int) ms$maxIconColumns;
@end

Class $SafeModeAlertItem;
Class $SBAlertItemsController;

void SafeModeAlertItem$alertSheet$buttonClicked$(id self, SEL sel, id sheet, int button) {
    switch (button) {
        case 1:
        break;

        case 2:
            exit(0);
        break;

        case 3:
            [UIApp applicationOpenURL:[NSURL URLWithString:@"http://cydia.saurik.com/safemode/"] asPanel:NO];
        break;
    }

    [self dismiss];
}

void SafeModeAlertItem$configure$requirePasscodeForActions$(id self, SEL sel, BOOL configure, BOOL require) {
    UIModalView *sheet([self alertSheet]);
    [sheet setDelegate:self];
    [sheet setBodyText:@"We apologize for the inconvenience, but SpringBoard has just crashed.\n\nA recent software installation, upgrade, or removal might have been the cause of this.\n\nYour device is now running in Safe Mode. All extensions that support this safety system are disabled.\n\nReboot (or restart SpringBoard) to return to the normal mode. To return to this dialog touch the status bar."];
    [sheet addButtonWithTitle:@"OK"];
    [sheet addButtonWithTitle:@"Restart"];
    [sheet addButtonWithTitle:@"Help"];
    [sheet setNumberOfRows:1];
}

void SafeModeAlertItem$performUnlockAction(id self, SEL sel) {
    [[$SBAlertItemsController sharedInstance] activateAlertItem:self];
}

static void MSAlert() {
    if ($SafeModeAlertItem == nil)
        $SafeModeAlertItem = objc_lookUpClass("SafeModeAlertItem");
    if ($SafeModeAlertItem == nil) {
        $SafeModeAlertItem = objc_allocateClassPair(objc_getClass("SBAlertItem"), "SafeModeAlertItem", 0);
        if ($SafeModeAlertItem == nil)
            return;

        class_addMethod($SafeModeAlertItem, @selector(alertSheet:buttonClicked:), (IMP) &SafeModeAlertItem$alertSheet$buttonClicked$, "v@:@i");
        class_addMethod($SafeModeAlertItem, @selector(configure:requirePasscodeForActions:), (IMP) &SafeModeAlertItem$configure$requirePasscodeForActions$, "v@:cc");
        class_addMethod($SafeModeAlertItem, @selector(performUnlockAction), (IMP) SafeModeAlertItem$performUnlockAction, "v@:");
        objc_registerClassPair($SafeModeAlertItem);
    }

    if ($SBAlertItemsController != nil)
        [[$SBAlertItemsController sharedInstance] activateAlertItem:[[$SafeModeAlertItem alloc] init]];
}

MSHook(void, SBStatusBar$mouseDown$, SBStatusBar *self, SEL sel, GSEventRef event) {
    MSAlert();
    _SBStatusBar$mouseDown$(self, sel, event);
}

static void SBIconController$showInfoAlertIfNeeded(id self, SEL sel) {
    static bool loaded = false;
    if (loaded)
        return;
    loaded = true;
    MSAlert();
}

static int SBButtonBar$maxIconColumns(id<MobileSubstrate> self, SEL sel) {
    static int max;
    if (max == 0) {
        max = [self ms$maxIconColumns];
        if (NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults])
            if (NSDictionary *iconState = [defaults objectForKey:@"iconState"])
                if (NSDictionary *buttonBar = [iconState objectForKey:@"buttonBar"])
                    if (NSArray *iconMatrix = [buttonBar objectForKey:@"iconMatrix"])
                        if ([iconMatrix count] != 0)
                            if (NSArray *row = [iconMatrix objectAtIndex:0]) {
                                int count([row count]);
                                if (max < count)
                                    max = count;
                            }
    } return max;
}

static id SBContentLayer$initWithSize$(SBContentLayer<MobileSubstrate> *self, SEL sel, CGSize size) {
    self = [self ms$initWithSize:size];
    if (self == nil)
        return nil;
    [self setBackgroundColor:[UIColor darkGrayColor]];
    return self;
}

/*MSHook(void, SBSlidingAlertDisplay$updateDesktopImage$, SBSlidingAlertDisplay *self, SEL sel, UIImage *image) {
    NSString *text(@"\"Sad iPhone\" by Geoff Stearns");
    UIView *&_backgroundView(MSHookIvar<UIView *>(self, "_backgroundView"));
    if (_backgroundView != nil)
        text = nil;
    _SBSlidingAlertDisplay$updateDesktopImage$(self, sel, image);
    if (text != nil) {
        UIFont *font([UIFont systemFontOfSize:12]);
        CGRect rect([self frame]);
        CGSize size([text sizeWithFont:font]);
        rect.origin.y = 385 - 3 - 14;//size.height;
        rect.size.height = size.height;

        UITextView *view([[UITextView alloc] initWithFrame:rect]);
        [view setTextAlignment:UITextAlignmentCenter];
        [view setMarginTop:0];
        [view setFont:font];
        [view setText:text];
        [view setTextColor:[UIColor grayColor]];
        [view setBackgroundColor:[UIColor clearColor]];

        [self insertSubview:view aboveSubview:_backgroundView];
    }
}*/

#define Paper_ "/Library/MobileSubstrate/MobilePaper.png"

MSHook(UIImage *, UIImage$defaultDesktopImage, UIImage *self, SEL sel) {
    return [UIImage imageWithContentsOfFile:@Paper_];
}

MSHook(void, SBStatusBarTimeView$tile, SBStatusBarTimeView *self, SEL sel) {
    NSString *&_time(MSHookIvar<NSString *>(self, "_time"));
    CGRect &_textRect(MSHookIvar<CGRect>(self, "_textRect"));
    if (_time != nil)
        [_time release];
    _time = [@"Exit Safe Mode" retain];
    GSFontRef font([self textFont]);
    CGSize size([_time sizeWithFont:(id)font]);
    CGRect frame([self frame]);
    _textRect.size = size;
    _textRect.origin.x = (frame.size.width - size.width) / 2;
    _textRect.origin.y = (frame.size.height - size.height) / 2;
}

#define Dylib_ "/Library/MobileSubstrate/MobileSubstrate.dylib"

extern "C" void MSInitialize() {
    NSLog(@"MS:Warning: Entering Safe Mode");

    MSHookMessage(objc_getClass("SBButtonBar"), @selector(maxIconColumns), (IMP) &SBButtonBar$maxIconColumns, "ms$");
    MSHookMessage(objc_getClass("SBContentLayer"), @selector(initWithSize:), (IMP) &SBContentLayer$initWithSize$, "ms$");
    _SBStatusBar$mouseDown$ = MSHookMessage(objc_getClass("SBStatusBar"), @selector(mouseDown:), &$SBStatusBar$mouseDown$);
    _SBStatusBarTimeView$tile = MSHookMessage(objc_getClass("SBStatusBarTimeView"), @selector(tile), &$SBStatusBarTimeView$tile);

    _UIImage$defaultDesktopImage = MSHookMessage(object_getClass(objc_getClass("UIImage")), @selector(defaultDesktopImage), &$UIImage$defaultDesktopImage);
    //_SBSlidingAlertDisplay$updateDesktopImage$ = MSHookMessage(objc_getClass("SBSlidingAlertDisplay"), @selector(updateDesktopImage:), &$SBSlidingAlertDisplay$updateDesktopImage$);

    char *dil = getenv("DYLD_INSERT_LIBRARIES");
    if (dil == NULL)
        NSLog(@"MS:Error: DYLD_INSERT_LIBRARIES is unset?");
    else {
        NSArray *dylibs([[NSString stringWithUTF8String:dil] componentsSeparatedByString:@":"]);
        NSUInteger index([dylibs indexOfObject:@ Dylib_]);
        if (index == NSNotFound)
            NSLog(@"MS:Error: dylib not in DYLD_INSERT_LIBRARIES?");
        else if ([dylibs count] == 1)
            unsetenv("DYLD_INSERT_LIBRARIES");
        else {
            NSMutableArray *value([[[NSMutableArray alloc] init] autorelease]);
            [value setArray:dylibs];
            [value removeObjectAtIndex:index];
            setenv("DYLD_INSERT_LIBRARIES", [[value componentsJoinedByString:@":"] UTF8String], !0);
        }
    }

    $SBAlertItemsController = objc_getClass("SBAlertItemsController");

    if (Class _class = objc_getClass("SBIconController")) {
        SEL sel(@selector(showInfoAlertIfNeeded));
        if (Method method = class_getInstanceMethod(_class, sel))
            method_setImplementation(method, (IMP) &SBIconController$showInfoAlertIfNeeded);
    }
}