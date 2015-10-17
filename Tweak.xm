#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>


extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);


@interface SBIconView : UIView
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture;
- (void)cancelLongPressTimer;
@end

@interface SBApplicationShortcutMenu : NSObject @end

@interface SBIconController
+ (id)sharedInstance;
@property(retain, nonatomic) SBApplicationShortcutMenu *presentedShortcutMenu;
- (void)_handleShortcutMenuPeek:(id)arg1;
- (BOOL)_canRevealShortcutMenu;
- (BOOL)isEditing;
@end

@interface UIGestureRecognizer (Firmware90_Private)
- (void)setRequiredPreviewForceState:(int)arg1;
@end


static NSDictionary *hapticInfo = nil;


#define hapticFeedback()	AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, hapticInfo)


%hook SBIconView 

- (void)addGestureRecognizer:(UIGestureRecognizer *)toAddGesture {
	if (toAddGesture != nil && toAddGesture == self.shortcutMenuPeekGesture) {
		UILongPressGestureRecognizer *menuGestureCanceller = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(__sb3dtm_handleLongPressGesture:)];
		menuGestureCanceller.minimumPressDuration = 1.0f;
		menuGestureCanceller.delaysTouchesEnded = NO;
		menuGestureCanceller.cancelsTouchesInView = NO;
		menuGestureCanceller.allowableMovement = 1.0f;
		%orig(menuGestureCanceller);
		
		self.shortcutMenuPeekGesture.minimumPressDuration = 0.75f * 0.5f;
		[toAddGesture setRequiredPreviewForceState:0];
		[toAddGesture requireGestureRecognizerToFail:menuGestureCanceller];
		
		[menuGestureCanceller release];
	}
	
	%orig;
}

%new
- (void)__sb3dtm_handleLongPressGesture:(UILongPressGestureRecognizer *)gesture {
	
}

- (void)_handleFirstHalfLongPressTimer:(id)timer {
	SBIconController *iconC = [%c(SBIconController) sharedInstance];
	
	if ([iconC _canRevealShortcutMenu]) {
		// TODO: icon visual feedback
		hapticFeedback();
	}
	else if (iconC.presentedShortcutMenu != nil) {
		[self cancelLongPressTimer];
		return;
	}
	
	%orig;
}

- (void)_handleSecondHalfLongPressTimer:(id)timer {
	// TODO: icon visual feedback
	%orig;
}

%end

%hook SBIconController

- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state == UIGestureRecognizerStateCancelled 
			|| gesture.state == UIGestureRecognizerStateFailed 
			|| gesture.state == UIGestureRecognizerStateRecognized)
		;// TODO: icon visual feedback
	
	%orig;
}

- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)imm {
	%orig(iconView, YES);
}

%end


%ctor {
	hapticInfo = [@{ @"VibePattern" : @[ @(YES), @(50) ], @"Intensity" : @(1) } retain];
	
	%init;
}

