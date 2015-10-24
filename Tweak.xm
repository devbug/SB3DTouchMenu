#import "headers.h"


extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);


NSUserDefaults *userDefaults = nil;

enum {
	kScreenEdgeOff = 0,
	kScreenEdgeOnWithoutLongPress,
	kScreenEdgeOnWithLongPress
};

#define SHORTCUT_ENABLED	([userDefaults boolForKey:@"Enabled"] && [userDefaults boolForKey:@"ShortcutEnabled"])
#define SCREENEDGE_ENABLED	([userDefaults boolForKey:@"Enabled"] && [userDefaults boolForKey:@"ScreenEdgeEnabled"])
#define HAPTIC_ENABLED		([userDefaults boolForKey:@"Enabled"] && [userDefaults boolForKey:@"UseHaptic"])
#define SCREENEDGES_		(UIRectEdge)(([userDefaults integerForKey:@"ScreenEdgeLeftInt"] != kScreenEdgeOff ? UIRectEdgeLeft : 0) | ([userDefaults integerForKey:@"ScreenEdgeRightInt"] != kScreenEdgeOff ? UIRectEdgeRight : 0) | ([userDefaults integerForKey:@"ScreenEdgeTopInt"] != kScreenEdgeOff ? UIRectEdgeTop : 0) | ([userDefaults integerForKey:@"ScreenEdgeBottomInt"] != kScreenEdgeOff ? UIRectEdgeBottom : 0))

static NSDictionary *hapticInfo = nil;

#define hapticFeedback()	{ if (HAPTIC_ENABLED) AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, hapticInfo); }


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
	if (!SHORTCUT_ENABLED) {
		[super touchesBegan:touches withEvent:event];
		return;
	}
	if (SHORTCUT_ENABLED && [userDefaults boolForKey:@"ShortcutNoUseEditMode"]) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	UITouch *touch = [touches anyObject];
	
	_startMajorRadius = touch.majorRadius;
	
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (!SHORTCUT_ENABLED) {
		[super touchesMoved:touches withEvent:event];
		return;
	}
	
	UITouch *touch = [touches anyObject];
	
	if (_startMajorRadius < touch.majorRadius) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	[super touchesMoved:touches withEvent:event];
}

@end


%hook SBIconView 

- (void)addGestureRecognizer:(UIGestureRecognizer *)toAddGesture {
	if (toAddGesture != nil && toAddGesture == self.shortcutMenuPeekGesture) {
		SB3DTMPeekDetectorForShortcutMenuGestureRecognizer *menuGestureCanceller = [[SB3DTMPeekDetectorForShortcutMenuGestureRecognizer alloc] initWithTarget:self action:@selector(__sb3dtm_handleLongPressGesture:)];
		menuGestureCanceller.minimumPressDuration = 1.0f;
		menuGestureCanceller.delaysTouchesEnded = NO;
		menuGestureCanceller.cancelsTouchesInView = NO;
		menuGestureCanceller.allowableMovement = 0.0f;
		menuGestureCanceller.delegate = (id <UIGestureRecognizerDelegate>)self;
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

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	if ([gestureRecognizer isKindOfClass:[SB3DTMPeekDetectorForShortcutMenuGestureRecognizer class]] && otherGestureRecognizer != self.shortcutMenuPeekGesture) {
		return YES;
	}
	
	return NO;
}

- (BOOL)_delegateTapAllowed {
	if (SHORTCUT_ENABLED && [[%c(SBIconController) sharedInstance] presentedShortcutMenu] != nil && !self.isHighlighted)
		return NO;
	
	return %orig;
}

- (void)_handleFirstHalfLongPressTimer:(id)timer {
	if (SHORTCUT_ENABLED && [[%c(SBIconController) sharedInstance] _canRevealShortcutMenu]) {
		// TODO: icon visual feedback
		hapticFeedback();
	}
	
	%orig;
}

- (void)_handleSecondHalfLongPressTimer:(id)timer {
	if (SHORTCUT_ENABLED && [[%c(SBIconController) sharedInstance] presentedShortcutMenu] != nil) {
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
	if (SHORTCUT_ENABLED && (gesture.state == UIGestureRecognizerStateCancelled 
			|| gesture.state == UIGestureRecognizerStateFailed 
			|| gesture.state == UIGestureRecognizerStateRecognized))
		;// TODO: icon visual feedback
	
	if (SHORTCUT_ENABLED && [userDefaults boolForKey:@"ShortcutNoUseEditMode"] 
			&& gesture.state == UIGestureRecognizerStateBegan) {
		// TODO: icon visual feedback
		hapticFeedback();
	}
	
	if (!SHORTCUT_ENABLED) return;
	
	%orig;
}

- (BOOL)iconShouldAllowTap:(SBIconView *)iconView {
	if (SHORTCUT_ENABLED && self.presentedShortcutMenu != nil && !iconView.isHighlighted)
		return NO;
	
	return %orig;
}

- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)imm {
	%orig(iconView, SHORTCUT_ENABLED ? YES : imm);
}

%end


%hook UIDevice

- (BOOL)_supportsForceTouch {
	return YES;
}

%end

//extern "C" CFBooleanRef MGGetBoolAnswer(CFStringRef);
//MSHook(CFBooleanRef, MGGetBoolAnswer, CFStringRef key) {
//	if (CFEqual(key, CFSTR("eQd5mlz0BN0amTp/2ccMoA")))
//		return kCFBooleanFalse;
//	
//	return _MGGetBoolAnswer(key);
//}


// Screen Edge Peek 3D Touch

%hook BSPlatform
- (BOOL)hasOrbCapability {
	return SCREENEDGE_ENABLED ? YES : %orig;
}
%end
%hook SBAppSwitcherSettings
- (BOOL)useOrbGesture {
	return SCREENEDGE_ENABLED ? YES : %orig;
}
%end

extern "C" BOOL _AXSForceTouchEnabled();
MSHook(BOOL, _AXSForceTouchEnabled) {
	return TRUE;
}


// if landscape with iPhone/iPod touch, iOS doesn't deliver message for screen edge.
// TODO: test on iPad
@interface SB3DTMFakeForcePressGestureRecognizer : UIScreenEdgePanGestureRecognizer
//@property (nonatomic) NSUInteger numberOfTapsRequired;	// 0
//@property (nonatomic) NSUInteger numberOfTouchesRequired;	// 1
@property (nonatomic) CFTimeInterval minimumPressDurationForLongPress;
@property (nonatomic) CGFloat allowableMovementForLongPress;
@property (nonatomic, readonly) BOOL isLongPressRecognized;
@property (nonatomic, readonly, getter=isFirstFace) BOOL firstface;
@property (nonatomic, readonly) BOOL panning;
@property (nonatomic, readonly) CGPoint startPoint;
@property (nonatomic, readonly) CFTimeInterval startTime;
@property (nonatomic, readonly) NSSet<UITouch *> *startTouches;
@property (nonatomic, readonly) UIEvent *startEvent;
@property (nonatomic, readonly) UIRectEdge recognizedEdge;
@property (nonatomic) BOOL _needLongPressForLeft;
@property (nonatomic) BOOL _needLongPressForRight;
@property (nonatomic) BOOL _needLongPressForTop;
@property (nonatomic) BOOL _needLongPressForBottom;

- (instancetype)initWithTarget:(id)target action:(SEL)action;
- (instancetype)initWithType:(int)type target:(id)target action:(SEL)action;
- (BOOL)_isNoRequriedLongPress;
@end

@implementation SB3DTMFakeForcePressGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
	// type == 1
	self = [super initWithTarget:target action:action];
	
	if (self) {
		self.minimumPressDurationForLongPress = 0.5f;
		self.allowableMovementForLongPress = 10.0f;
		self._needLongPressForLeft = YES;
		self._needLongPressForRight = YES;
		self._needLongPressForTop = YES;
		self._needLongPressForBottom = YES;
		_isLongPressRecognized = NO;
		_firstface = NO;
		_panning = NO;
		_startPoint = CGPointMake(0,0);
		_startTime = 0.0f;
		_startTouches = nil;
		_startEvent = nil;
		_recognizedEdge = UIRectEdgeNone;
	}
	
	return self;
}

// type
// 1 : default, 아무리 오래 눌러도 아래쪽 터치는 (인식되다가) 결국 무시됨
// 2 : Control center default, 1초 정도 누르면 터치 실패됨
- (instancetype)initWithType:(int)type target:(id)target action:(SEL)action {
	self = [self initWithTarget:target action:action type:type];
	
	if (self) {
		self.minimumPressDurationForLongPress = 0.5f;
		self.allowableMovementForLongPress = 10.0f;
		self._needLongPressForLeft = YES;
		self._needLongPressForRight = YES;
		self._needLongPressForTop = YES;
		self._needLongPressForBottom = YES;
		_isLongPressRecognized = NO;
		_firstface = NO;
		_panning = NO;
		_startPoint = CGPointMake(0,0);
		_startTime = 0.0f;
		_startTouches = nil;
		_startEvent = nil;
		_recognizedEdge = UIRectEdgeNone;
	}
	
	return self;
}

- (void)reset {
	[super reset];
	
	_isLongPressRecognized = NO;
	_firstface = NO;
	_panning = NO;
	_startPoint = CGPointMake(0,0);
	_startTime = 0.0f;
	[_startTouches release], _startTouches = nil;
	[_startEvent release], _startEvent = nil;
	_recognizedEdge = UIRectEdgeNone;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL)_isNoRequriedLongPress {
	if (!SCREENEDGE_ENABLED) return NO;
	
	if (_recognizedEdge == UIRectEdgeLeft && !self._needLongPressForLeft) {
		return YES;
	}
	else if (_recognizedEdge == UIRectEdgeRight && !self._needLongPressForRight) {
		return YES;
	}
	else if (_recognizedEdge == UIRectEdgeTop && !self._needLongPressForTop) {
		return YES;
	}
	else if (_recognizedEdge == UIRectEdgeBottom && !self._needLongPressForBottom) {
		return YES;
	}
	
	return NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (!SCREENEDGE_ENABLED) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	_startTouches = [touches copy];
	_startEvent = [event retain];
	
	UITouch *touch = [touches anyObject];

	if ([touch tapCount] != 1) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	CGPoint location = [self _locationForTouch:touch];
	
	BOOL inEdge = NO;
	_recognizedEdge = UIRectEdgeNone;
	if ((self.edges & UIRectEdgeLeft) != 0 && location.x <= [self _edgeRegionSize]) {
		inEdge = YES;
		_recognizedEdge |= UIRectEdgeLeft;
	}
	else if ((self.edges & UIRectEdgeRight) != 0 && (screenSize.width - location.x) <= [self _edgeRegionSize]) {
		inEdge = YES;
		_recognizedEdge |= UIRectEdgeRight;
	}
	if ((self.edges & UIRectEdgeTop) != 0 && location.y <= [self _edgeRegionSize]) {
		inEdge = YES;
		_recognizedEdge |= UIRectEdgeTop;
	}
	else if ((self.edges & UIRectEdgeBottom) != 0 && (screenSize.height - location.y) <= [self _edgeRegionSize]) {
		inEdge = YES;
		_recognizedEdge |= UIRectEdgeBottom;
	}
	
	if (!inEdge)
		self.state = UIGestureRecognizerStateFailed;
	
	if (self.state == UIGestureRecognizerStateFailed) return;
	
	if (_recognizedEdge & ~(UIRectEdgeLeft | UIRectEdgeRight)) {
		CGFloat x = MIN(ABS(screenSize.width - location.x), location.x);
		CGFloat y = MIN(ABS(screenSize.height - location.y), location.y);
		
		if (_recognizedEdge & ~UIRectEdgeLeft) {
			if (x > y) {
				_recognizedEdge &= ~UIRectEdgeLeft;
			}
			else {
				_recognizedEdge = UIRectEdgeLeft;
			}
		}
		else if (_recognizedEdge & ~UIRectEdgeRight) {
			if (x > y) {
				_recognizedEdge &= ~UIRectEdgeRight;
			}
			else {
				_recognizedEdge = UIRectEdgeRight;
			}
		}
	}
	
	if (_recognizedEdge == UIRectEdgeBottom && !self._needLongPressForBottom) {
		if ([[%c(SBNotificationCenterController) sharedInstanceIfExists] isVisible]) {
			self.state = UIGestureRecognizerStateFailed;
			return;
		}
	}
	
	if ([self _isNoRequriedLongPress]) {
		_firstface = YES;
		[super touchesBegan:touches withEvent:event];
		//return;
	}
	
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
	_isLongPressRecognized = YES;
	
	if ([self _isNoRequriedLongPress] && !self.panning) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	if (self.state != UIGestureRecognizerStateCancelled 
			&& self.state != UIGestureRecognizerStateFailed 
			&& self.state != UIGestureRecognizerStateRecognized) {
		_firstface = YES;
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
	if ([self _isNoRequriedLongPress]) {
		if (self.panning == NO) {
			if (self.isLongPressRecognized) {
				self.state = UIGestureRecognizerStateFailed;
				return;
			}
			if (self.startTime + self.minimumPressDurationForLongPress <= [[NSDate date] timeIntervalSince1970]) {
				_isLongPressRecognized = YES;
				self.state = UIGestureRecognizerStateFailed;
				return;
			}
			
			_panning = YES;
		}
		
		_firstface = YES;
		[super touchesMoved:touches withEvent:event];
		return;
	}
	
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
			_firstface = YES;
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
	
	if (!SCREENEDGE_ENABLED) {
		%orig;
		return;
	}
	
	SB3DTMFakeForcePressGestureRecognizer *fg = [[%c(SB3DTMFakeForcePressGestureRecognizer) alloc] initWithType:1 target:[%c(SBMainSwitcherGestureCoordinator) sharedInstance] action:@selector(__sb3dtm_handleSwitcherFakeForcePressGesture:)];
	fg.delegate = self;
	fg.minimumNumberOfTouches = 1;
	fg.maximumNumberOfTouches = 1;
	[fg _setHysteresis:0];
	fg.edges = SCREENEDGES_;
	fg._needLongPressForLeft = [userDefaults integerForKey:@"ScreenEdgeLeftInt"] == kScreenEdgeOnWithLongPress;
	fg._needLongPressForRight = [userDefaults integerForKey:@"ScreenEdgeRightInt"] == kScreenEdgeOnWithLongPress;
	fg._needLongPressForTop = [userDefaults integerForKey:@"ScreenEdgeTopInt"] == kScreenEdgeOnWithLongPress;
	fg._needLongPressForBottom = [userDefaults integerForKey:@"ScreenEdgeBottomInt"] == kScreenEdgeOnWithLongPress;
	
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:fg withType:0xD];
	g = (SBSwitcherForcePressSystemGestureRecognizer *)fg;
}

%end

%hook SBMainSwitcherGestureCoordinator

%new
- (void)__sb3dtm_handleSwitcherFakeForcePressGesture:(SB3DTMFakeForcePressGestureRecognizer *)gesture {
	if (SCREENEDGE_ENABLED && !gesture.isFirstFace)
		return;
	
	if (gesture.state == UIGestureRecognizerStateBegan) {
		hapticFeedback();
		[self _forcePressGestureBeganWithGesture:gesture];
	}
	
	SBSwitcherForcePressSystemGestureTransaction *_switcherForcePressTransaction = MSHookIvar<SBSwitcherForcePressSystemGestureTransaction *>(self, "_switcherForcePressTransaction");
	[_switcherForcePressTransaction systemGestureStateChanged:gesture];
}

%end



%hook SBControlCenterController

- (id)init {
	id rtn = %orig;
	
	[self __sb3dtm_addSystemGestureRecognizer];
	
	return rtn;
}

%new
- (void)__sb3dtm_addSystemGestureRecognizer {
	SBScreenEdgePanGestureRecognizer *&g = MSHookIvar<SBScreenEdgePanGestureRecognizer *>(self, "_controlCenterGestureRecognizer");
	if (g) {
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:g];
		[g release];
		g = nil;
	}
	
	if ([userDefaults integerForKey:@"ScreenEdgeBottomInt"] == kScreenEdgeOnWithoutLongPress) {
		SB3DTMFakeForcePressGestureRecognizer *fg = [[%c(SB3DTMFakeForcePressGestureRecognizer) alloc] initWithType:1 target:self action:@selector(_handleShowControlCenterGesture:)];
		fg.delegate = self;
		fg.minimumNumberOfTouches = 1;
		fg.maximumNumberOfTouches = 1;
		[fg _setHysteresis:0];
		[fg _setEdgeRegionSize:20.0f];
		fg.edges = UIRectEdgeBottom;
		fg._needLongPressForBottom = YES;
		
		g = (SBScreenEdgePanGestureRecognizer *)fg;
	}
	else {
		g = [[%c(SBScreenEdgePanGestureRecognizer) alloc] initWithTarget:self action:@selector(_handleShowControlCenterGesture:) type:2];
		g.edges = UIRectEdgeBottom;
		g.delegate = self;
	}
	
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:3];
}

%end

%hook SBNotificationCenterController

- (id)init {
	id rtn = %orig;
	
	[self __sb3dtm_addSystemGestureRecognizer];
	
	return rtn;
}

%new
- (void)__sb3dtm_addSystemGestureRecognizer {
	SBScreenEdgePanGestureRecognizer *&g = MSHookIvar<SBScreenEdgePanGestureRecognizer *>(self, "_showSystemGestureRecognizer");
	if (g) {
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:g];
		[g release];
		g = nil;
	}
	
	if ([userDefaults integerForKey:@"ScreenEdgeTopInt"] == kScreenEdgeOnWithoutLongPress) {
		SB3DTMFakeForcePressGestureRecognizer *fg = [[%c(SB3DTMFakeForcePressGestureRecognizer) alloc] initWithType:1 target:self action:@selector(_handleShowNotificationCenterGesture:)];
		fg.delegate = self;
		fg.minimumNumberOfTouches = 1;
		fg.maximumNumberOfTouches = 1;
		[fg _setHysteresis:0];
		[fg _setEdgeRegionSize:20.0f];
		fg.edges = UIRectEdgeTop;
		fg._needLongPressForTop = YES;
		
		g = (SBScreenEdgePanGestureRecognizer *)fg;
	}
	else {
		g = [[%c(SBScreenEdgePanGestureRecognizer) alloc] initWithTarget:self action:@selector(_handleShowNotificationCenterGesture:)];
		g.edges = UIRectEdgeTop;
		g.delegate = self;
	}
	
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:1];
}

%end



void loadSettings() {
	SBControlCenterController *ccc = [%c(SBControlCenterController) sharedInstanceIfExists];
	if (ccc) {
		[ccc __sb3dtm_addSystemGestureRecognizer];
	}
	
	SBNotificationCenterController *ncc = [%c(SBNotificationCenterController) sharedInstanceIfExists];
	if (ncc) {
		[ncc __sb3dtm_addSystemGestureRecognizer];
	}
	
	SBUIController *uic = [%c(SBUIController) sharedInstanceIfExists];
	if (uic) {
		[uic _addRemoveSwitcherGesture];
	}
}

__attribute__((unused))
static void reloadPrefsNotification(CFNotificationCenterRef center,
									void *observer,
									CFStringRef name,
									const void *object,
									CFDictionaryRef userInfo) {
	loadSettings();
}


%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
	%orig;
	
	loadSettings();
}

%end



%ctor {
	#define kSettingsPListName @"me.devbug.SB3DTouchMenu"
	userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSettingsPListName];
	[userDefaults registerDefaults:@{
		@"Enabled" : @YES,
		@"ShortcutEnabled" : @YES,
		@"ShortcutNoUseEditMode" : @NO,
		@"ScreenEdgeEnabled" : @YES,
		@"UseHaptic" : @YES,
		@"HapticVibLength" : @(35),
		@"ScreenEdgeLeftInt" : @(kScreenEdgeOnWithLongPress),
		@"ScreenEdgeRightInt" : @(kScreenEdgeOff),
		@"ScreenEdgeTopInt" : @(kScreenEdgeOff),
		@"ScreenEdgeBottomInt" : @(kScreenEdgeOff)
	}];
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadPrefsNotification, CFSTR("me.devbug.SB3DTouchMenu.prefnoti"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadSettings();
	
	
	hapticInfo = [@{ @"VibePattern" : @[ @(YES), [userDefaults objectForKey:@"HapticVibLength"] ], @"Intensity" : @(1.0) } retain];
	
	//MSHookFunction(MGGetBoolAnswer, MSHake(MGGetBoolAnswer));
	MSHookFunction(_AXSForceTouchEnabled, MSHake(_AXSForceTouchEnabled));
	
	%init;
}

