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

%hook SBSwitcherForcePressSystemGestureRecognizer

- (BOOL)_shouldTryToBeginWithEvent:(UIEvent * /*UITouchesEvent **/)event {
	// 무조건 yes는 감도에 영향을 줌. 이 제스처의 모든 유효 터치에 대해 begin을 가능하게 해줌.
	//return YES;
	return %orig;
}

%end

@interface _UISettings : NSObject @end
@interface _UIScreenEdgePanRecognizerDwellSettings : _UISettings
@property (nonatomic) CFTimeInterval longPressRequiredDuration;
@end
@interface _UIScreenEdgePanRecognizerSettings : _UISettings
- (void)setDefaultValues;
- (_UIScreenEdgePanRecognizerDwellSettings *)dwellSettings;
@end
@interface _UIScreenEdgePanRecognizer : NSObject
@property (nonatomic, readonly) struct CGPoint _lastTouchLocation;
- (id)delegate;
@property (nonatomic, retain) _UIScreenEdgePanRecognizerSettings *settings;
@property (nonatomic, readonly) int state;
- (void)_setState:(int)arg1;
- (void)_incorporateIncrementalSampleAtLocation:(struct CGPoint)arg1 timestamp:(CFTimeInterval)arg2 modifier:(int)arg3 interfaceOrientation:(UIInterfaceOrientation)arg4 forceState:(int)arg5;
- (void)_incorporateInitialTouchAtLocation:(struct CGPoint)arg1 timestamp:(CFTimeInterval)arg2 modifier:(int)arg3 interfaceOrientation:(UIInterfaceOrientation)arg4 forceState:(int)arg5;
- (void)incorporateTouchSampleAtLocation:(struct CGPoint)arg1 timestamp:(CFTimeInterval)arg2 modifier:(int)arg3 interfaceOrientation:(UIInterfaceOrientation)arg4 forceState:(int)arg5;
- (int)_type;
- (BOOL)isRequiringLongPress;
- (void)setRequiresFlatThumb:(BOOL)arg1;
- (void)setShouldUseGrapeFlags:(BOOL)arg1;
@end
@interface UIScreenEdgePanGestureRecognizer (Private)
- (BOOL)_shouldTryToBeginWithEvent:(id)arg1;
- (CGFloat)_edgeRegionSize;
- (CGPoint)_locationForTouch:(id)arg1;
- (void)_setEdgeRegionSize:(CGFloat)arg1;
- (void)_setHysteresis:(CGFloat)arg1;
- (BOOL)_shouldTryToBeginWithEvent:(id)arg1;
- (BOOL)_shouldUseGrapeFlags;
- (UIInterfaceOrientation)_touchInterfaceOrientation;
- (id)initWithTarget:(id)arg1 action:(SEL)arg2 type:(int)arg3;
- (BOOL)isRequiringLongPress;
- (void)screenEdgePanRecognizerStateDidChange:(id)arg1;
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

@interface FBSDisplay : NSObject @end
@interface SBWorkspace : NSObject
+ (id)mainWorkspace;
//@property(readonly, retain, nonatomic) FBWorkspaceEventQueue *eventQueue;
@property(readonly, retain, nonatomic) FBSDisplay *display;
@end
@interface SBWorkspaceTransitionRequest : NSObject
@property(copy, nonatomic) NSString *eventLabel;
//@property(retain, nonatomic) SBAlertManager *alertManager;
@end
@interface SBMainWorkspaceTransitionRequest : SBWorkspaceTransitionRequest
- (id)initWithDisplay:(id)arg1;
- (id)initWithWorkspace:(SBWorkspace *)arg1 display:(FBSDisplay *)arg2;	// crash
@end
@interface SBMainSwitcherViewController : NSObject
+ (id)sharedInstance;
- (void)startTransitionPresenting:(BOOL)arg1 withRequest:(id)arg2;
@end
@interface FBRootWindow : UIWindow @end
@interface FBSceneManager : NSObject
+ (id)sharedInstance;
- (FBRootWindow *)_rootWindowForDisplay:(FBSDisplay *)arg1 createIfNecessary:(BOOL)arg2;
@end

@interface UIGestureRecognizerTarget : NSObject {
	SEL _action;
	id _target;
}
@end

@interface UILongPressGestureRecognizer (Private)
@property (setter=_setButtonType:, nonatomic) int _buttonType;
- (void)_resetGestureRecognizer;
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2;
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2;
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2;
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2;
@end


// TODO: another directions
@interface SB3DTMSwitcherFakeForcePressGestureRecognizer : UIScreenEdgePanGestureRecognizer
//@property (nonatomic) NSUInteger numberOfTapsRequired;	// 0
//@property (nonatomic) NSUInteger numberOfTouchesRequired;	// 1
@property (nonatomic) CFTimeInterval minimumPressDuration;
@property (nonatomic) CGFloat allowableMovement;
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
		self.minimumPressDuration = 0.5f;
		self.allowableMovement = 10.0f;
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
			[self performSelector:@selector(longPressTimerElapsed:) withObject:self afterDelay:self.minimumPressDuration];
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
		
		if (distance > self.allowableMovement) {
			self.state = UIGestureRecognizerStateFailed;
			return;
		}
		
		if (self.startTime + self.minimumPressDuration <= [[NSDate date] timeIntervalSince1970]
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

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
}

@end



%hook SBUIController

/*- (void)_addRemoveSwitcherGesture {
	%orig;
	
	SBSwitcherForcePressSystemGestureRecognizer *&g = MSHookIvar<SBSwitcherForcePressSystemGestureRecognizer *>(self, "_switcherForcePressRecognizer");
	if (g == nil) {
		g = (SBSwitcherForcePressSystemGestureRecognizer *)[[%c(UIScreenEdgePanGestureRecognizer) alloc] initWithTarget:self action:@selector(_handleSwitcherForcePressGesture:)];
		g.delegate = (id <UIGestureRecognizerDelegate>)self;
		g.minimumNumberOfTouches = 1;
		g.maximumNumberOfTouches = 1;
		[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:0xD];
	}
	
	[g _setEdgeRegionSize:10.0f];
}*/

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
	//[g _setEdgeRegionSize:1.0f];
	
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:0xD];
}

%end

%hook SBMainSwitcherGestureCoordinator

// _handleSwitcherForcePressGesture == handleSwitcherForcePressGesture
//- (void)_handleSwitcherForcePressGesture:(UIGestureRecognizer *)gesture {
//	if (gesture.state == UIGestureRecognizerStateBegan) {
//		[self _forcePressGestureBeganWithGesture:gesture];
//	}
//
//	SBSwitcherForcePressSystemGestureTransaction *_switcherForcePressTransaction = MSHookIvar<SBSwitcherForcePressSystemGestureTransaction *>(self, "_switcherForcePressTransaction");
//	[_switcherForcePressTransaction systemGestureStateChanged:gesture];
//}

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

/*
Oct 18 21:24:16 deVbugs-i5 SpringBoard[4670] <Notice>: [SB3DTouchMenu] Tweak.xm:225 DEBUG: -[<SBMainSwitcherViewController: 0x158ad0d0> startTransitionPresenting:1 withRequest:<SBMainWorkspaceTransitionRequest: 0x14607270; eventLabel: ActivateSwitcherForcePress; display: Main; source: Unspecified> {
	    alertManager = <SBMainAlertManager: 0x14729b20>;
	    applicationContext = <SBWorkspaceApplicationTransitionContext: 0x146c0c80; animationDisabled: NO; background: NO; waitForScenes: YES> {
	        layoutState = <SBMainDisplayLayoutState: 0x147acc60; elements: 1> {
	            orientation = UIInterfaceOrientationPortrait;
	            breadcrumbState = <SBBreadcrumbState: 0x146ef3b0>;
	            sideAppState = <SBSideAppState: 0x14693920; identifier: (null); style: Overlay; width: Narrow>;
	            elements = {
	                <SBLayoutElement: 0x16a91070; identifier: com.apple.SpringBoard.builtin.PrimarySwitcher; role: primary> {
	                    supportedRoles = primary;
	                    attributes = none;
	                    viewControllerClass = SBMainSwitcherViewController;
	                };
	            }
	        };
	        previousLayoutState = <SBMainDisplayLayoutState: 0x16b7fba0; elements: 0> {
	            orientation = UIInterfaceOrientationPortrait;
	            breadcrumbState = <SBBreadcrumbState: 0x15b427e0>;
	            sideAppState = <SBSideAppState: 0x15b9e8b0; identifier: (null); style: Overlay; width: Narrow>;
	        };
	        layoutDelegate = <SBMainWorkspaceTransitionRequest: 0x14607270>;
	        entities = {
	            SBLayoutPrimaryRole = <SBMainWorkspacePrimarySwitcherEntity: 0x1474ca20; ID: com.apple.SpringBoard.builtin.PrimarySwitcher; layoutRole: primary> {
	                supportedRoles = primary;
	                layoutAttributes = none;
	            };
	            SBLayoutSideRole = <SBWorkspaceDeactivatingEntity: 0x15a4b510; layoutRole: side> {
	                supportedRoles = none;
	                layoutAttributes = none;
	            };
	        }
	    };
	}] 
*/



%ctor {
	hapticInfo = [@{ @"VibePattern" : @[ @(YES), @(50) ], @"Intensity" : @(1) } retain];
	
	MSHookFunction(_AXSForceTouchEnabled, MSHake(_AXSForceTouchEnabled));
	
	%init;
}

