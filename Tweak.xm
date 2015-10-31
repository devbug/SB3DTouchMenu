#import "headers.h"
#import "SB3DTMScreenEdgeLongPressPanGestureRecognizer.h"
#import "SB3DTMSwitcherForceLongPressPanGestureRecognizer.h"


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


BOOL screenEdgeEnabled() {
	return SCREENEDGE_ENABLED;
}

BOOL switcherAutoFlipping() {
	return [userDefaults boolForKey:@"SwitcherAutoFlipping"];
}

BOOL screenEdgeDisableOnKeyboard() {
	return [userDefaults boolForKey:@"ScreenEdgeDisableOnKeyboard"];
}


%hook SBIconView 

- (void)addGestureRecognizer:(UIGestureRecognizer *)toAddGesture {
	if (toAddGesture != nil && toAddGesture == self.shortcutMenuPeekGesture) {
		self.shortcutMenuPeekGesture.minimumPressDuration = 0.75f * 0.5f;
		[toAddGesture removeTarget:[%c(SBIconController) sharedInstance] action:@selector(_handleShortcutMenuPeek:)];
		[toAddGesture addTarget:self action:@selector(__sb3dtm_handleForceTouchGesture:)];
	}
	
	%orig;
}

%new
- (void)__sb3dtm_handleForceTouchGesture:(UILongPressGestureRecognizer *)gesture {
	if (!SHORTCUT_ENABLED) return;
	
	if (gesture.state == UIGestureRecognizerStateBegan) {
		hapticFeedback();
	}
	
	[[%c(SBIconController) sharedInstance] _handleShortcutMenuPeek:gesture];
}

%end

%hook _UITouchForceObservable

- (CGFloat)_maximumPossibleForceForTouches:(NSSet<UITouch *> *)touches {
	return 10.0f;
}

- (CGFloat)_unclampedTouchForceForTouches:(NSSet<UITouch *> *)touches {
	UITouch *touch = [touches anyObject];
	
	CGFloat rtn = touch.majorRadius / 12.5f;
	if (rtn <= 0.f) rtn = 90.0f / 12.5f;
	
	return rtn;
}

%end

%hook _UILinearForceLevelClassifier

- (CGFloat)_calculateProgressOfTouchForceValue:(CGFloat)arg1 toForceLevel:(int)arg2 minimumRequiredForceLevel:(int)arg3 {
	CGFloat rtn = %orig;
	//%log(@(rtn));
	return rtn;
}

- (CGFloat)revealThreshold {
	return 1.0f;
}

- (CGFloat)standardThreshold {
	return 1.0f;
}

- (CGFloat)strongThreshold {
	return 1.75f;
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
	
	if (!SCREENEDGE_ENABLED) {
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
		
		g = (SBScreenEdgePanGestureRecognizer *)fg;
	}
	else {
		g = [[%c(SBScreenEdgePanGestureRecognizer) alloc] initWithTarget:self action:@selector(_handleShowControlCenterGesture:) type:2];
		g.edges = UIRectEdgeBottom;
		g.delegate = self;
	}
	
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
	
	if ([userDefaults integerForKey:@"ScreenEdgeTopInt"] == kScreenEdgeOnWithoutLongPress) {
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
	
	[[%c(SBSystemGestureManager) mainDisplayManager] addGestureRecognizer:g withType:SBSystemGestureTypeShowNotificationCenter];
}

%end



// switcher flipping
CGAffineTransform switcherTransform;
CGAffineTransform switcherIconTitleTransform;
CGAffineTransform switcherAppSuggestionTransform;
UIRectEdge recognizedEdge = UIRectEdgeNone;

%hook SBMainSwitcherViewController

- (void)viewWillAppear:(BOOL)animated {
	%orig;
	
	if (switcherAutoFlipping()) {
		recognizedEdge = gg.recognizedEdge;
		switch (gg.recognizedEdge) {
			case UIRectEdgeTop:
				switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
				switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
				switcherAppSuggestionTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
				break;
			case UIRectEdgeBottom:
				switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI + M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
				switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
				switcherAppSuggestionTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI + M_PI_2), CGAffineTransformMakeScale(-1.0f, 1.0f));
				break;
			case UIRectEdgeRight:
				switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(-1.0f, 1.0f));
				switcherIconTitleTransform = CGAffineTransformMakeScale(-1.0f, 1.0f);
				switcherAppSuggestionTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
				break;
			case UIRectEdgeLeft:
			default:
				switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
				switcherIconTitleTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
				switcherAppSuggestionTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
				break;
		}
	}
	else {
		switcherTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
		switcherIconTitleTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
		switcherAppSuggestionTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.0f), CGAffineTransformMakeScale(1.0f, 1.0f));
	}
}

%new
- (void)viewDidDisappear:(BOOL)animated {
	for (UIView *v in self.view.subviews) {
		[v removeFromSuperview];
	}
	[self.view removeFromSuperview];
	SBSwitcherContainerView *_contentView = MSHookIvar<SBSwitcherContainerView *>(self, "_contentView");
	[_contentView release];
	
	[self loadView];
	[self viewDidLoad];
}

%end

%hook SBSwitcherContainerView

- (void)layoutSubviews {
	%orig;
	
	self.transform = switcherTransform;
}

%end

%hook SBDeckSwitcherPageView

- (void)layoutSubviews {
	%orig;
	
	self.transform = switcherTransform;
}

%end

%hook SBSwitcherAppSuggestionSlideUpView

- (void)layoutSubviews {
	%orig;
	
	if (switcherAutoFlipping()) {
		SBOrientationTransformWrapperView *_appViewLayoutWrapper = MSHookIvar<SBOrientationTransformWrapperView *>(self, "_appViewLayoutWrapper");
		CGRect frame = _appViewLayoutWrapper.frame;
		switch (recognizedEdge) {
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
}

%end

%hook SBSwitcherAppSuggestionBottomBannerView

- (void)layoutSubviews {
	%orig;
	
	self.transform = switcherIconTitleTransform;
}

%end

%hook SBSwitcherAppSuggestionViewController

- (CGRect)_presentedRectForContentView {
	if (switcherAutoFlipping() && recognizedEdge != UIRectEdgeNone) {
		CGRect rtn = [[UIScreen mainScreen] bounds];
		rtn.origin.x = self.view.bounds.origin.x;
		rtn.origin.y = self.view.bounds.origin.y;
		return rtn;
	}
	
	return %orig;
}

- (NSUInteger)_bottomBannerStyle {
	if (switcherAutoFlipping()) {
		switch (recognizedEdge) {
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
	
	self.transform = switcherTransform;
}

%end

%hook SBDeckSwitcherItemContainer

- (void)layoutSubviews {
	%orig;
	
	UILabel *_iconTitle = MSHookIvar<UILabel *>(self, "_iconTitle");
	_iconTitle.transform = switcherIconTitleTransform;
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
	
	[hapticInfo release];
	hapticInfo = [@{ @"VibePattern" : @[ @(YES), [userDefaults objectForKey:@"HapticVibLength"] ], @"Intensity" : @(2.0) } retain];
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
		@"ScreenEdgeEnabled" : @YES,
		@"UseHaptic" : @YES,
		@"HapticVibLength" : @(40),
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

