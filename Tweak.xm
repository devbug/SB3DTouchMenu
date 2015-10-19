#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIGestureRecognizerSubclass.h>


extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);


@interface SBIconView : UIView
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture;
- (void)cancelLongPressTimer;
- (void)setHighlighted:(BOOL)arg1;
- (BOOL)isHighlighted;
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

@interface UITouch (Private)
@property (nonatomic, readonly) CGFloat majorRadius;
@property (nonatomic, readonly) CGFloat majorRadiusTolerance;
@end


@interface SB3DTMPeekDetectorForShortcutMenuGestureRecognizer : UILongPressGestureRecognizer
@property (nonatomic, readonly) CGFloat startMajorRadius;
@end

@implementation SB3DTMPeekDetectorForShortcutMenuGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
	self = [super initWithTarget:target action:action];
	
	if (self) {
		_startMajorRadius = 0.0f;
	}
	
	return self;
}

- (void)reset {
	[super reset];
	
	_startMajorRadius = 0.0f;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	_startMajorRadius = touch.majorRadius;
	
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	if (_startMajorRadius < touch.majorRadius) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	[super touchesMoved:touches withEvent:event];
}

@end


static NSDictionary *hapticInfo = nil;


#define hapticFeedback()	AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, hapticInfo)


%hook SBIconView 

- (void)addGestureRecognizer:(UIGestureRecognizer *)toAddGesture {
	if (toAddGesture != nil && toAddGesture == self.shortcutMenuPeekGesture) {
		SB3DTMPeekDetectorForShortcutMenuGestureRecognizer *menuGestureCanceller = [[SB3DTMPeekDetectorForShortcutMenuGestureRecognizer alloc] initWithTarget:self action:@selector(__sb3dtm_handleLongPressGesture:)];
		menuGestureCanceller.minimumPressDuration = 1.0f;
		menuGestureCanceller.delaysTouchesEnded = NO;
		menuGestureCanceller.cancelsTouchesInView = NO;
		menuGestureCanceller.allowableMovement = 0.0f;
		%orig(menuGestureCanceller);
		
		self.shortcutMenuPeekGesture.minimumPressDuration = 0.75f * 0.5f;
		[toAddGesture setRequiredPreviewForceState:0];
		[toAddGesture requireGestureRecognizerToFail:menuGestureCanceller];
		
		[menuGestureCanceller release];
	}
	
	%orig;
}

%new
- (void)__sb3dtm_handleLongPressGesture:(SB3DTMPeekDetectorForShortcutMenuGestureRecognizer *)gesture {
	
}

- (BOOL)_delegateTapAllowed {
	if ([[%c(SBIconController) sharedInstance] presentedShortcutMenu] != nil && !self.isHighlighted)
		return NO;
	
	return %orig;
}

- (void)_handleFirstHalfLongPressTimer:(id)timer {
	if ([[%c(SBIconController) sharedInstance] _canRevealShortcutMenu]) {
		// TODO: icon visual feedback
		hapticFeedback();
	}
	
	%orig;
}

- (void)_handleSecondHalfLongPressTimer:(id)timer {
	if ([[%c(SBIconController) sharedInstance] presentedShortcutMenu] != nil) {
		[self cancelLongPressTimer];
		[self setHighlighted:NO];
		return;
	}
	
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

- (BOOL)iconShouldAllowTap:(SBIconView *)iconView {
	if (self.presentedShortcutMenu != nil && !iconView.isHighlighted)
		return NO;
	
	return %orig;
}

- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)imm {
	%orig(iconView, YES);
}

%end


// Screen Edge Peek 3D Touch

%hook BSPlatform
- (BOOL)hasOrbCapability {
	return YES;
}
%end
%hook SBAppSwitcherSettings
- (BOOL)useOrbGesture {
	return YES;
}
%end

extern "C" BOOL _AXSForceTouchEnabled();
MSHook(BOOL, _AXSForceTouchEnabled) {
	return TRUE;
}


@interface UIScreenEdgePanGestureRecognizer (Private)
- (CGFloat)_edgeRegionSize;
- (CGPoint)_locationForTouch:(id)arg1;
- (void)_setHysteresis:(CGFloat)arg1;
- (UIInterfaceOrientation)_touchInterfaceOrientation;
@end
@interface SBSwitcherForcePressSystemGestureRecognizer : UIScreenEdgePanGestureRecognizer @end
@interface SBSystemGestureManager : NSObject
+ (id)mainDisplayManager;
- (void)removeGestureRecognizer:(id)arg1;
- (void)addGestureRecognizer:(id)arg1 withType:(NSUInteger)arg2;
@end
@interface SBSwitcherForcePressSystemGestureTransaction : NSObject
- (void)systemGestureStateChanged:(id)arg1;
@end
@interface SBMainSwitcherGestureCoordinator : NSObject {
	SBSwitcherForcePressSystemGestureTransaction *_switcherForcePressTransaction;
}
+ (id)sharedInstance;
- (void)_forcePressGestureBeganWithGesture:(id)arg1;
- (void)_handleSwitcherForcePressGesture:(id)arg1;
- (void)handleSwitcherForcePressGesture:(id)arg1;
@end

@interface UIGestureRecognizerTarget : NSObject {
	SEL _action;
	id _target;
}
@end


// TODO: another directions
@interface SB3DTMSwitcherFakeForcePressGestureRecognizer : UIScreenEdgePanGestureRecognizer
//@property (nonatomic) NSUInteger numberOfTapsRequired;	// 0
//@property (nonatomic) NSUInteger numberOfTouchesRequired;	// 1
@property (nonatomic) CFTimeInterval minimumPressDurationForLongPress;
@property (nonatomic) CGFloat allowableMovementForLongPress;
@property (nonatomic, readonly) BOOL isLongPressRecognized;
@property (nonatomic, readonly) BOOL panning;
@property (nonatomic, readonly) CGPoint startPoint;
@property (nonatomic, readonly) CFTimeInterval startTime;
@property (nonatomic, readonly) NSSet<UITouch *> *startTouches;
@property (nonatomic, readonly) UIEvent *startEvent;

- (instancetype)initWithTarget:(id)target action:(SEL)action;
@end

@implementation SB3DTMSwitcherFakeForcePressGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
	// type == 1
	self = [super initWithTarget:target action:action];
	
	if (self) {
		self.minimumPressDurationForLongPress = 0.5f;
		self.allowableMovementForLongPress = 10.0f;
		_isLongPressRecognized = NO;
		_panning = NO;
		_startPoint = CGPointMake(0,0);
		_startTime = 0.0f;
		_startTouches = nil;
		_startEvent = nil;
	}
	
	return self;
}

- (void)reset {
	[super reset];
	
	_isLongPressRecognized = NO;
	_panning = NO;
	_startPoint = CGPointMake(0,0);
	_startTime = 0.0f;
	[_startTouches release], _startTouches = nil;
	[_startEvent release], _startEvent = nil;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	_startTouches = [touches copy];
	_startEvent = [event retain];
	
	UITouch *touch = [touches anyObject];

	if ([touch tapCount] != 1) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	if ([self _locationForTouch:touch].x > [self _edgeRegionSize]) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	if (self.state == UIGestureRecognizerStateFailed) return;
	
	if (!self.isLongPressRecognized) {
		if (_startTime == 0.0f) {
			_startPoint = [self _locationForTouch:touch];
			_startTime = [[NSDate date] timeIntervalSince1970];
			[self performSelector:@selector(longPressTimerElapsed:) withObject:self afterDelay:self.minimumPressDurationForLongPress];
		}
		return;
	}
	
	[super touchesBegan:touches withEvent:event];
}

- (void)longPressTimerElapsed:(id)unused {
	if (self.state != UIGestureRecognizerStateCancelled 
			&& self.state != UIGestureRecognizerStateFailed 
			&& self.state != UIGestureRecognizerStateRecognized) {
		_isLongPressRecognized = YES;
		//hapticFeedback();
		
		if (self.panning == NO) {
			[self touchesBegan:self.startTouches withEvent:self.startEvent];
			
			NSArray *_targets = MSHookIvar<NSArray *>(self, "_targets");
			for (UIGestureRecognizerTarget *target in _targets) {
				dispatch_async(dispatch_get_main_queue(), ^{
					id t = MSHookIvar<id>(target, "_target");
					SEL a = MSHookIvar<SEL>(target, "_action");
					
					[t performSelector:a withObject:self];
				});
			}
			
			_panning = YES;
		}
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (!self.isLongPressRecognized) {
		UITouch *touch = [touches anyObject];
		
		CGPoint curPoint = [self _locationForTouch:touch];
		CGFloat dx = fabs(_startPoint.x - curPoint.x);
		CGFloat dy = fabs(_startPoint.y - curPoint.y);
		CGFloat distance = sqrt(dx*dx + dy*dy);
		
		if (distance > self.allowableMovementForLongPress) {
			self.state = UIGestureRecognizerStateFailed;
			return;
		}
		
		if (self.startTime + self.minimumPressDurationForLongPress <= [[NSDate date] timeIntervalSince1970]
				&& self.state != UIGestureRecognizerStateCancelled 
				&& self.state != UIGestureRecognizerStateFailed 
				&& self.state != UIGestureRecognizerStateRecognized) {
			_isLongPressRecognized = YES;
		}
		else {
			return;
		}
	}
	
	if (self.panning == NO) {
		[super touchesBegan:touches withEvent:event];
		_panning = YES;
	}
	
	[super touchesMoved:touches withEvent:event];
}

@end



%hook SBUIController

- (void)_addRemoveSwitcherGesture {
	SBSwitcherForcePressSystemGestureRecognizer *&g = MSHookIvar<SBSwitcherForcePressSystemGestureRecognizer *>(self, "_switcherForcePressRecognizer");
	if (g) {
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:g];
		[g release];
		g = nil;
	}
	
	g = (SBSwitcherForcePressSystemGestureRecognizer *)[[%c(SB3DTMSwitcherFakeForcePressGestureRecognizer) alloc] initWithTarget:[%c(SBMainSwitcherGestureCoordinator) sharedInstance] action:@selector(__sb3dtm_handleSwitcherFakeForcePressGesture:)];
	g.delegate = (id <UIGestureRecognizerDelegate>)self;
	g.minimumNumberOfTouches = 1;
	g.maximumNumberOfTouches = 1;
	[g _setHysteresis:0];
	g.edges = UIRectEdgeLeft;
	
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:0xD];
}

%end

%hook SBMainSwitcherGestureCoordinator

%new
- (void)__sb3dtm_handleSwitcherFakeForcePressGesture:(SB3DTMSwitcherFakeForcePressGestureRecognizer *)gesture {
	if (!gesture.isLongPressRecognized) return;
	
	if (gesture.state == UIGestureRecognizerStateBegan) {
		hapticFeedback();
		[self _forcePressGestureBeganWithGesture:gesture];
	}
	
	SBSwitcherForcePressSystemGestureTransaction *_switcherForcePressTransaction = MSHookIvar<SBSwitcherForcePressSystemGestureTransaction *>(self, "_switcherForcePressTransaction");
	[_switcherForcePressTransaction systemGestureStateChanged:gesture];
}

%end



%ctor {
	hapticInfo = [@{ @"VibePattern" : @[ @(YES), @(35) ], @"Intensity" : @(1) } retain];
	
	MSHookFunction(_AXSForceTouchEnabled, MSHake(_AXSForceTouchEnabled));
	
	%init;
}

