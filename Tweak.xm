#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>


extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);


@interface SBIconView : UIView
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture;
@end

@interface SBIconController
+ (id)sharedInstance;
- (void)_handleShortcutMenuPeek:(id)arg1;
- (BOOL)_canRevealShortcutMenu;
- (BOOL)isEditing;
@end

@interface UIGestureRecognizer (Firmware90_Private)
- (void)setRequiredPreviewForceState:(int)arg1;
@end


@interface SB3DTMLongPressGestureDelegate : NSObject <UIGestureRecognizerDelegate> @end

@implementation SB3DTMLongPressGestureDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && ![[%c(SBIconController) sharedInstance] _canRevealShortcutMenu])
		return NO;
	
	return YES;
}

@end


static SB3DTMLongPressGestureDelegate *delegate = nil;
static NSDictionary *hapticInfo = nil;


void hapticFeedback() {
	AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, hapticInfo);
}


%hook SBIconView 

- (void)addGestureRecognizer:(UIGestureRecognizer *)toAddGesture {
	if (toAddGesture != nil && toAddGesture == self.shortcutMenuPeekGesture) {
		UILongPressGestureRecognizer *menuGestureCanceller = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(__sb3dtm_handleLongPressGesture:)];
		menuGestureCanceller.minimumPressDuration = 1.0f;
		menuGestureCanceller.delegate = delegate;
		menuGestureCanceller.delaysTouchesEnded = NO;
		menuGestureCanceller.cancelsTouchesInView = NO;
		menuGestureCanceller.allowableMovement = 1.0f;
		%orig(menuGestureCanceller);
		
		[toAddGesture setRequiredPreviewForceState:0];
		[toAddGesture requireGestureRecognizerToFail:menuGestureCanceller];
		toAddGesture.delegate = delegate;
		
		[menuGestureCanceller release];
	}
	
	%orig;
}

%new
- (void)__sb3dtm_handleLongPressGesture:(UILongPressGestureRecognizer *)gesture {
	
}

- (void)_handleFirstHalfLongPressTimer:(id)timer {
	if ([[%c(SBIconController) sharedInstance] _canRevealShortcutMenu]) {
		hapticFeedback();
	}
	
	%orig;
}

- (void)_handleSecondHalfLongPressTimer:(id)timer {
	%orig;
}

%end

%hook SBIconController

- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)imm {
	%orig(iconView, YES);
}

%end


%ctor {
	class_addProtocol(%c(SBIconView), @protocol(UIGestureRecognizerDelegate));
	
	hapticInfo = [@{ @"VibePattern" : @[ @(YES), @(50) ], @"Intensity" : @(1) } retain];
	delegate = [[SB3DTMLongPressGestureDelegate alloc] init];
	
	%init;
}

