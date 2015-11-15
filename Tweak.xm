#import "headers.h"
#import "SB3DTMScreenEdgeLongPressPanGestureRecognizer.h"
#import "SB3DTMSwitcherForceLongPressPanGestureRecognizer.h"


extern "C" {
	void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);
	void FigVibratorInitialize(void);
	void FigVibratorPlayVibrationWithDictionary(CFDictionaryRef dict, int a, int b, void *c, CFDictionaryRef d);
}


NSUserDefaults *userDefaults = nil;

enum {
	kScreenEdgeOff = 0,
	kScreenEdgeOnWithoutLongPress,
	kScreenEdgeOnWithLongPress
};

#define SHORTCUT_ENABLED			([userDefaults boolForKey:@"Enabled"] && [userDefaults boolForKey:@"ShortcutEnabled"])
#define SCREENEDGE_ENABLED			([userDefaults boolForKey:@"Enabled"] && [userDefaults boolForKey:@"ScreenEdgeEnabled"])
#define HAPTIC_ENABLED				([userDefaults boolForKey:@"Enabled"] && [userDefaults boolForKey:@"UseHaptic"])
#define SCREENEDGES_				(UIRectEdge)(([userDefaults integerForKey:@"ScreenEdgeLeftInt"] != kScreenEdgeOff ? UIRectEdgeLeft : 0) | ([userDefaults integerForKey:@"ScreenEdgeRightInt"] != kScreenEdgeOff ? UIRectEdgeRight : 0) | ([userDefaults integerForKey:@"ScreenEdgeTopInt"] != kScreenEdgeOff ? UIRectEdgeTop : 0) | ([userDefaults integerForKey:@"ScreenEdgeBottomInt"] != kScreenEdgeOff ? UIRectEdgeBottom : 0))
#define AUTOFLIPPING_ENABLED		(SCREENEDGE_ENABLED && [userDefaults boolForKey:@"SwitcherAutoFlipping"])

static NSDictionary *g_hapticInfo = nil;
static BOOL g_hapticInitialized = NO;
static BOOL g_shouldReverseDirection = NO;

static void hapticFeedback() {
	if (HAPTIC_ENABLED) {
		FBWorkspaceEvent *event = [FBWorkspaceEvent eventWithName:@"SB3DTouchMenuHapticNow" handler:^{
			if ([userDefaults boolForKey:@"ForcedHapticMode"]) {
				if (!g_hapticInitialized) {
					FigVibratorInitialize();
					g_hapticInitialized = YES;
				}
				FigVibratorPlayVibrationWithDictionary((CFDictionaryRef)g_hapticInfo, 0, 0, NULL, nil);
			}
			else {
				AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, g_hapticInfo);
			}
		}];
		[[FBWorkspaceEventQueue sharedInstance] executeOrAppendEvent:event];
	}
}


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

%new - (UIGestureRecognizer *)__sb3dtm_menuGestureCanceller {
	return objc_getAssociatedObject(self, @selector(__sb3dtm_menuGestureCanceller));
}
%new - (void)__sb3dtm_setMenuGestureCanceller:(UIGestureRecognizer *)value {
	objc_setAssociatedObject(self, @selector(__sb3dtm_menuGestureCanceller), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)__sb3dtm_setGestures {
	if (self.shortcutMenuPeekGesture) {
		if (self.__sb3dtm_menuGestureCanceller == nil) {
			SB3DTMPeekDetectorForShortcutMenuGestureRecognizer *menuGestureCanceller = [[SB3DTMPeekDetectorForShortcutMenuGestureRecognizer alloc] initWithTarget:self action:@selector(__sb3dtm_handleLongPressGesture:)];
			menuGestureCanceller.minimumPressDuration = 1.0f;
			menuGestureCanceller.delaysTouchesEnded = NO;
			menuGestureCanceller.cancelsTouchesInView = NO;
			menuGestureCanceller.allowableMovement = 0.0f;
			menuGestureCanceller.delegate = (id <UIGestureRecognizerDelegate>)self;
			
			[self __sb3dtm_setMenuGestureCanceller:menuGestureCanceller];
			
			[self addGestureRecognizer:menuGestureCanceller];
			
			[menuGestureCanceller release];
		}
		
		if (SHORTCUT_ENABLED) {
			self.shortcutMenuPeekGesture.minimumPressDuration = 0.75f * 0.5f;
			[self.shortcutMenuPeekGesture removeTarget:[%c(SBIconController) sharedInstance] action:@selector(_handleShortcutMenuPeek:)];
			[self.shortcutMenuPeekGesture addTarget:self action:@selector(__sb3dtm_handleForceTouchGesture:)];
			[self.shortcutMenuPeekGesture setRequiredPreviewForceState:0];
			[self.shortcutMenuPeekGesture requireGestureRecognizerToFail:self.__sb3dtm_menuGestureCanceller];
		}
		else {
			self.shortcutMenuPeekGesture.minimumPressDuration = 0.1f;
			[self.shortcutMenuPeekGesture removeTarget:self action:@selector(__sb3dtm_handleForceTouchGesture:)];
			[self.shortcutMenuPeekGesture addTarget:[%c(SBIconController) sharedInstance] action:@selector(_handleShortcutMenuPeek:)];
			[self.shortcutMenuPeekGesture setRequiredPreviewForceState:1];
		}
	}
}

%new
- (void)__sb3dtm_handleLongPressGesture:(SB3DTMPeekDetectorForShortcutMenuGestureRecognizer *)gesture {
	
}

%new
- (void)__sb3dtm_handleForceTouchGesture:(UILongPressGestureRecognizer *)gesture {
	if (SHORTCUT_ENABLED && [userDefaults boolForKey:@"ShortcutNoUseEditMode"] && gesture.state == UIGestureRecognizerStateBegan) {
		hapticFeedback();
	}
	
	if (!SHORTCUT_ENABLED) return;
	
	[[%c(SBIconController) sharedInstance] _handleShortcutMenuPeek:gesture];
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
	
	%orig;
}

%end

%hook SBIconController

- (void)viewMap:(id)map configureIconView:(SBIconView *)iconView {
	%orig;
	
	[iconView __sb3dtm_setGestures];
}

- (BOOL)iconShouldAllowTap:(SBIconView *)iconView {
	if (SHORTCUT_ENABLED && self.presentedShortcutMenu != nil && !iconView.isHighlighted)
		return NO;
	
	return %orig;
}

- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)imm {
	%orig(iconView, SHORTCUT_ENABLED ? YES : imm);
}

%new
- (void)__sb3dtm_resetAllIconsGesture {
	SBIconViewMap *homescreenMap = [%c(SBIconViewMap) homescreenMap];
	NSArray *icons = [[homescreenMap iconModel] leafIcons];
	
	for (SBIcon *icon in icons) {
		SBIconView *iconView = [homescreenMap mappedIconViewForIcon:icon];
		[iconView __sb3dtm_setGestures];
	}
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



SB3DTMSwitcherForceLongPressPanGestureRecognizer *gg = nil;

%hook SBUIController

- (void)_addRemoveSwitcherGesture {
	SBSwitcherForcePressSystemGestureRecognizer *&g = MSHookIvar<SBSwitcherForcePressSystemGestureRecognizer *>(self, "_switcherForcePressRecognizer");
	if (g) {
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:g];
		[g release];
		g = nil;
	}
	
	NSMutableDictionary *_typeToGesture = MSHookIvar<NSMutableDictionary *>([%c(SBSystemGestureManager) mainDisplayManager], "_typeToGesture");
	
	if (!SCREENEDGE_ENABLED) {
		if (nil != _typeToGesture[@(SBSystemGestureTypeSwitcherForcePress)]) {
			NSLog(@"[SB3DTouchMenu] ERROR! CANNOT add system default SwitcherForcePress gesture. SystemGesture already exists: %@", _typeToGesture[@(SBSystemGestureTypeSwitcherForcePress)]);
			return;
		}
		
		%orig;
		return;
	}
	
	SB3DTMSwitcherForceLongPressPanGestureRecognizer *fg = [[%c(SB3DTMSwitcherForceLongPressPanGestureRecognizer) alloc] 
																						initWithType:1 
																				   systemGestureType:SBSystemGestureTypeSwitcherForcePress 
																							  target:[%c(SBMainSwitcherGestureCoordinator) sharedInstance] 
																							  action:@selector(__sb3dtm_handleSwitcherFakeForcePressGesture:)];
	fg.delegate = self;
	fg.minimumNumberOfTouches = 1;
	fg.maximumNumberOfTouches = 1;
	fg.edges = SCREENEDGES_;
	[fg _setEdgeRegionSize:26.0f];
	fg._needLongPressForLeft = [userDefaults integerForKey:@"ScreenEdgeLeftInt"] == kScreenEdgeOnWithLongPress;
	fg._needLongPressForRight = [userDefaults integerForKey:@"ScreenEdgeRightInt"] == kScreenEdgeOnWithLongPress;
	fg._needLongPressForTop = [userDefaults integerForKey:@"ScreenEdgeTopInt"] == kScreenEdgeOnWithLongPress;
	fg._needLongPressForBottom = [userDefaults integerForKey:@"ScreenEdgeBottomInt"] == kScreenEdgeOnWithLongPress;
	fg.disableOnKeyboard = [userDefaults boolForKey:@"ScreenEdgeDisableOnKeyboard"];
	fg.touchPointMaze = AUTOFLIPPING_ENABLED;
	fg.shouldReverseDirection = g_shouldReverseDirection;
	
	if (nil != _typeToGesture[@(SBSystemGestureTypeSwitcherForcePress)])
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:_typeToGesture[@(SBSystemGestureTypeSwitcherForcePress)]];
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:fg withType:SBSystemGestureTypeSwitcherForcePress];
	g = (SBSwitcherForcePressSystemGestureRecognizer *)fg;
	gg = fg;
}

%end

%hook SBMainSwitcherGestureCoordinator

%new
- (void)__sb3dtm_handleSwitcherFakeForcePressGesture:(SB3DTMSwitcherForceLongPressPanGestureRecognizer *)gesture {
	if (SCREENEDGE_ENABLED && !gesture.isFirstFace)
		return;
	
	if (gesture.state == UIGestureRecognizerStatePossible /*&& ![gesture _isNoRequriedLongPress]*/)
		hapticFeedback();
	
	if (gesture.state == UIGestureRecognizerStateBegan) {
		if ([gesture _isNoRequriedLongPress])
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
	
	if (SCREENEDGE_ENABLED && [userDefaults integerForKey:@"ScreenEdgeBottomInt"] == kScreenEdgeOnWithoutLongPress) {
		SB3DTMScreenEdgeLongPressPanGestureRecognizer *fg = [[%c(SB3DTMScreenEdgeLongPressPanGestureRecognizer) alloc] 
																							initWithType:1 
																					   systemGestureType:SBSystemGestureTypeShowControlCenter 
																								  target:self 
																								  action:@selector(_handleShowControlCenterGesture:)];
		fg.delegate = self;
		fg.minimumNumberOfTouches = 1;
		fg.maximumNumberOfTouches = 1;
		[fg _setEdgeRegionSize:20.0f];
		fg.edges = UIRectEdgeBottom;
		fg.disableOnKeyboard = YES;
		
		g = (SBScreenEdgePanGestureRecognizer *)fg;
	}
	else {
		g = [[%c(SBScreenEdgePanGestureRecognizer) alloc] initWithTarget:self action:@selector(_handleShowControlCenterGesture:) type:2];
		g.edges = UIRectEdgeBottom;
		g.delegate = self;
	}
	
	NSMutableDictionary *_typeToGesture = MSHookIvar<NSMutableDictionary *>([%c(SBSystemGestureManager) mainDisplayManager], "_typeToGesture");
	if (nil != _typeToGesture[@(SBSystemGestureTypeShowControlCenter)])
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:_typeToGesture[@(SBSystemGestureTypeShowControlCenter)]];
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:SBSystemGestureTypeShowControlCenter];
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
	
	if (SCREENEDGE_ENABLED && [userDefaults integerForKey:@"ScreenEdgeTopInt"] == kScreenEdgeOnWithoutLongPress) {
		SB3DTMScreenEdgeLongPressPanGestureRecognizer *fg = [[%c(SB3DTMScreenEdgeLongPressPanGestureRecognizer) alloc] 
																							initWithType:1 
																					   systemGestureType:SBSystemGestureTypeShowNotificationCenter 
																								  target:self 
																								  action:@selector(_handleShowNotificationCenterGesture:)];
		fg.delegate = self;
		fg.minimumNumberOfTouches = 1;
		fg.maximumNumberOfTouches = 1;
		[fg _setEdgeRegionSize:20.0f];
		fg.edges = UIRectEdgeTop;
		
		g = (SBScreenEdgePanGestureRecognizer *)fg;
	}
	else {
		g = [[%c(SBScreenEdgePanGestureRecognizer) alloc] initWithTarget:self action:@selector(_handleShowNotificationCenterGesture:)];
		g.edges = UIRectEdgeTop;
		g.delegate = self;
	}
	
	NSMutableDictionary *_typeToGesture = MSHookIvar<NSMutableDictionary *>([%c(SBSystemGestureManager) mainDisplayManager], "_typeToGesture");
	if (nil != _typeToGesture[@(SBSystemGestureTypeShowNotificationCenter)])
		[[%c(SBSystemGestureManager) mainDisplayManager] removeGestureRecognizer:_typeToGesture[@(SBSystemGestureTypeShowNotificationCenter)]];
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:SBSystemGestureTypeShowNotificationCenter];
}

%end



// switcher flipping
CGAffineTransform g_switcherTransform;
CGAffineTransform g_switcherIconTitleTransform;
UIRectEdge g_recognizedEdge = UIRectEdgeNone;

%hook SBMainSwitcherViewController

- (void)viewWillAppear:(BOOL)animated {
	%orig;
	
	if (AUTOFLIPPING_ENABLED) {
		g_recognizedEdge = gg.recognizedEdge;
		
		if (!g_shouldReverseDirection) {
			switch (g_recognizedEdge) {
				case UIRectEdgeTop:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
					break;
				case UIRectEdgeBottom:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI + M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
					break;
				case UIRectEdgeRight:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(-1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
					break;
				case UIRectEdgeLeft:
				default:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
					break;
			}
		}
		else {
			switch (g_recognizedEdge) {
				case UIRectEdgeBottom:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
					break;
				case UIRectEdgeTop:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI + M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
					break;
				case UIRectEdgeLeft:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(-1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
					break;
				case UIRectEdgeRight:
				default:
					g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
					g_switcherIconTitleTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
					break;
			}
		}
	}
	else {
		g_switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
		g_switcherIconTitleTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	%orig;
	
	g_recognizedEdge = UIRectEdgeNone;
	
	for (UIView *v in self.view.subviews) {
		[v removeFromSuperview];
	}
	[self.view removeFromSuperview];
	SBSwitcherContainerView *_contentView = MSHookIvar<SBSwitcherContainerView *>(self, "_contentView");
	[_contentView release];
	
	[self prepareForReuse];
	[self loadView];
	[self viewDidLoad];
}

%end

%hook SBSwitcherContainerView

- (void)layoutSubviews {
	%orig;
	
	self.transform = g_switcherTransform;
}

%end

%hook SBDeckSwitcherPageView

- (void)layoutSubviews {
	%orig;
	
	self.transform = g_switcherTransform;
}

%end

%hook SBSwitcherAppSuggestionSlideUpView

- (void)layoutSubviews {
	%orig;
	
	if (AUTOFLIPPING_ENABLED) {
		SBOrientationTransformWrapperView *_appViewLayoutWrapper = MSHookIvar<SBOrientationTransformWrapperView *>(self, "_appViewLayoutWrapper");
		CGRect frame = _appViewLayoutWrapper.frame;
		
		if (!g_shouldReverseDirection) {
			switch (g_recognizedEdge) {
				case UIRectEdgeTop:
					self.clipsToBounds = NO;
					frame.origin.x = (MIN(frame.size.width, frame.size.height) / 2.0f) - (MAX(frame.size.width, frame.size.height) / 2.0f);
					frame.origin.y = (MAX(frame.size.width, frame.size.height) / 2.0f) - (MIN(frame.size.width, frame.size.height) / 2.0f);
					_appViewLayoutWrapper.frame = frame;
					break;
				case UIRectEdgeBottom:
					self.clipsToBounds = NO;
					frame.origin.x = (MAX(frame.size.width, frame.size.height) / 2.0f) - (MIN(frame.size.width, frame.size.height) / 2.0f);
					frame.origin.y -= (MAX(frame.size.width, frame.size.height) / 2.0f) - (MIN(frame.size.width, frame.size.height) / 2.0f);
					_appViewLayoutWrapper.frame = frame;
					break;
			}
		}
		else {
			switch (g_recognizedEdge) {
				case UIRectEdgeBottom:
					self.clipsToBounds = NO;
					frame.origin.x = (MIN(frame.size.width, frame.size.height) / 2.0f) - (MAX(frame.size.width, frame.size.height) / 2.0f);
					frame.origin.y = (MAX(frame.size.width, frame.size.height) / 2.0f) - (MIN(frame.size.width, frame.size.height) / 2.0f);
					_appViewLayoutWrapper.frame = frame;
					break;
				case UIRectEdgeTop:
					self.clipsToBounds = NO;
					frame.origin.x = (MAX(frame.size.width, frame.size.height) / 2.0f) - (MIN(frame.size.width, frame.size.height) / 2.0f);
					frame.origin.y -= (MAX(frame.size.width, frame.size.height) / 2.0f) - (MIN(frame.size.width, frame.size.height) / 2.0f);
					_appViewLayoutWrapper.frame = frame;
					break;
			}
		}
	}
}

%end

%hook SBSwitcherAppSuggestionBottomBannerView

- (void)layoutSubviews {
	%orig;
	
	self.transform = g_switcherIconTitleTransform;
}

%end

%hook SBSwitcherAppSuggestionViewController

- (CGRect)_presentedRectForContentView {
	if (AUTOFLIPPING_ENABLED && g_recognizedEdge != UIRectEdgeNone) {
		CGRect rtn = [[UIScreen mainScreen] bounds];
		rtn.origin.x = self.view.bounds.origin.x;
		rtn.origin.y = self.view.bounds.origin.y;
		return rtn;
	}
	
	return %orig;
}

- (NSUInteger)_bottomBannerStyle {
	if (AUTOFLIPPING_ENABLED) {
		switch (g_recognizedEdge) {
			case UIRectEdgeTop:
			case UIRectEdgeBottom:
				return 0;
		}
	}
	
	return %orig;
}

%end

%hook SBDeckSwitcherIconImageContainerView

- (void)layoutSubviews {
	%orig;
	
	self.transform = g_switcherTransform;
}

%end

%hook SBDeckSwitcherItemContainer

- (void)layoutSubviews {
	%orig;
	
	UILabel *_iconTitle = MSHookIvar<UILabel *>(self, "_iconTitle");
	_iconTitle.transform = g_switcherIconTitleTransform;
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
		g_shouldReverseDirection = [[UIApplication sharedApplication] userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft;
		
		[uic _addRemoveSwitcherGesture];
		
		[[%c(SBIconController) sharedInstance] __sb3dtm_resetAllIconsGesture];
	}
	
	[g_hapticInfo release];
	
	if ([userDefaults boolForKey:@"ForcedHapticMode"]) {
		CGFloat duration = [[userDefaults objectForKey:@"HapticVibLength"] floatValue] / 1000.0f;
		g_hapticInfo = [@{ @"OnDuration" : @(0.0f), @"OffDuration" : @(duration), @"TotalDuration" : @(duration), @"Intensity" : @(2.0f) } retain];
	}
	else
		g_hapticInfo = [@{ @"VibePattern" : @[ @(YES), [userDefaults objectForKey:@"HapticVibLength"] ], @"Intensity" : @(2.0) } retain];
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
	
	if (!g_hapticInitialized) {
		FigVibratorInitialize();
		g_hapticInitialized = YES;
	}
	
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
		@"HapticVibLength" : @(40),
		@"ForcedHapticMode" : @(NO),
		@"ScreenEdgeLeftInt" : @(kScreenEdgeOnWithLongPress),
		@"ScreenEdgeRightInt" : @(kScreenEdgeOff),
		@"ScreenEdgeTopInt" : @(kScreenEdgeOff),
		@"ScreenEdgeBottomInt" : @(kScreenEdgeOff),
		@"SwitcherAutoFlipping" : @YES,
		@"ScreenEdgeDisableOnKeyboard" : @NO
	}];
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadPrefsNotification, CFSTR("me.devbug.SB3DTouchMenu.prefnoti"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadSettings();
	
	
	//MSHookFunction(MGGetBoolAnswer, MSHake(MGGetBoolAnswer));
	MSHookFunction(_AXSForceTouchEnabled, MSHake(_AXSForceTouchEnabled));
	
	%init;
}

