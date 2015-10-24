#import "headers.h"
#import "SB3DTMSwitcherForceLongPressPanGestureRecognizer.h"



extern BOOL screenEdgeEnabled();
extern BOOL switcherAutoFlipping();


%subclass SB3DTMSwitcherForceLongPressPanGestureRecognizer : SBSwitcherForcePressSystemGestureRecognizer

%new
- (id)initWithTarget:(id)target action:(SEL)action systemGestureType:(SBSystemGestureType)gsType {
	// type == 1
	self = [self initWithTarget:target action:action];
	
	if (self) {
		self.minimumPressDurationForLongPress = 0.5f;
		self.allowableMovementForLongPress = 10.0f;
		self._needLongPressForLeft = YES;
		self._needLongPressForRight = YES;
		self._needLongPressForTop = YES;
		self._needLongPressForBottom = YES;
		self.isLongPressRecognized = NO;
		self.firstface = NO;
		self.panning = NO;
		self.startPoint = CGPointMake(0,0);
		self.startTime = 0.0f;
		self.startTouches = nil;
		self.startEvent = nil;
		self.recognizedEdge = UIRectEdgeNone;
		self.systemGestureType = gsType;
		[self _setHysteresis:0.0];
	}
	
	return self;
}

// type
// 1 : default, 아무리 오래 눌러도 아래쪽 터치는 (인식되다가) 결국 무시됨
// 2 : Control center default, 1초 정도 누르면 터치 실패됨
// 4 : force press default, 
%new
- (id)initWithType:(int)type systemGestureType:(SBSystemGestureType)gsType target:(id)target action:(SEL)action {
	self = [self initWithTarget:target action:action type:type];
	
	if (self) {
		self.minimumPressDurationForLongPress = 0.5f;
		self.allowableMovementForLongPress = 10.0f;
		self._needLongPressForLeft = YES;
		self._needLongPressForRight = YES;
		self._needLongPressForTop = YES;
		self._needLongPressForBottom = YES;
		self.isLongPressRecognized = NO;
		self.firstface = NO;
		self.panning = NO;
		self.startPoint = CGPointMake(0,0);
		self.startTime = 0.0f;
		self.startTouches = nil;
		self.startEvent = nil;
		self.recognizedEdge = UIRectEdgeNone;
		self.systemGestureType = gsType;
		[self _setHysteresis:0.0];
	}
	
	return self;
}

%new - (CFTimeInterval)minimumPressDurationForLongPress {
	return [objc_getAssociatedObject(self, @selector(minimumPressDurationForLongPress)) doubleValue];
}
%new - (CGFloat)allowableMovementForLongPress {
	return [objc_getAssociatedObject(self, @selector(allowableMovementForLongPress)) floatValue];
}
%new - (BOOL)isLongPressRecognized {
	return [objc_getAssociatedObject(self, @selector(isLongPressRecognized)) boolValue];
}
%new - (BOOL)isFirstFace {
	return [objc_getAssociatedObject(self, @selector(isFirstFace)) boolValue];
}
%new - (BOOL)panning {
	return [objc_getAssociatedObject(self, @selector(panning)) boolValue];
}
%new - (CGPoint)startPoint {
	return [objc_getAssociatedObject(self, @selector(startPoint)) CGPointValue];
}
%new - (CFTimeInterval)startTime {
	return [objc_getAssociatedObject(self, @selector(startTime)) doubleValue];
}
%new - (NSSet<UITouch *> *)startTouches {
	return objc_getAssociatedObject(self, @selector(startTouches));
}
%new - (UIEvent *)startEvent {
	return objc_getAssociatedObject(self, @selector(startEvent));
}
%new - (UIRectEdge)recognizedEdge {
	return [objc_getAssociatedObject(self, @selector(recognizedEdge)) unsignedLongLongValue];
}
%new - (BOOL)_needLongPressForLeft {
	return [objc_getAssociatedObject(self, @selector(_needLongPressForLeft)) boolValue];
}
%new - (BOOL)_needLongPressForRight {
	return [objc_getAssociatedObject(self, @selector(_needLongPressForRight)) boolValue];
}
%new - (BOOL)_needLongPressForTop {
	return [objc_getAssociatedObject(self, @selector(_needLongPressForTop)) boolValue];
}
%new - (BOOL)_needLongPressForBottom {
	return [objc_getAssociatedObject(self, @selector(_needLongPressForBottom)) boolValue];
}
%new - (SBSystemGestureType)systemGestureType {
	return [objc_getAssociatedObject(self, @selector(systemGestureType)) unsignedLongLongValue];
}

%new - (void)setMinimumPressDurationForLongPress:(CFTimeInterval)value {
	objc_setAssociatedObject(self, @selector(minimumPressDurationForLongPress), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setAllowableMovementForLongPress:(CGFloat)value {
	objc_setAssociatedObject(self, @selector(allowableMovementForLongPress), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setIsLongPressRecognized:(BOOL)value {
	objc_setAssociatedObject(self, @selector(isLongPressRecognized), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setFirstface:(BOOL)value {
	objc_setAssociatedObject(self, @selector(isFirstFace), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setPanning:(BOOL)value {
	objc_setAssociatedObject(self, @selector(panning), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setStartPoint:(CGPoint)value {
	objc_setAssociatedObject(self, @selector(startPoint), [NSValue valueWithCGPoint:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setStartTime:(CFTimeInterval)value {
	objc_setAssociatedObject(self, @selector(startTime), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setStartTouches:(NSSet<UITouch *> *)touches {
	objc_setAssociatedObject(self, @selector(startTouches), touches, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
%new - (void)setStartEvent:(UIEvent *)event {
	objc_setAssociatedObject(self, @selector(startEvent), event, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setRecognizedEdge:(UIRectEdge)value {
	objc_setAssociatedObject(self, @selector(recognizedEdge), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)set_needLongPressForLeft:(BOOL)value {
	objc_setAssociatedObject(self, @selector(_needLongPressForLeft), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)set_needLongPressForRight:(BOOL)value {
	objc_setAssociatedObject(self, @selector(_needLongPressForRight), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)set_needLongPressForTop:(BOOL)value {
	objc_setAssociatedObject(self, @selector(_needLongPressForTop), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)set_needLongPressForBottom:(BOOL)value {
	objc_setAssociatedObject(self, @selector(_needLongPressForBottom), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new - (void)setSystemGestureType:(SBSystemGestureType)value {
	objc_setAssociatedObject(self, @selector(systemGestureType), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)reset {
	%orig;
	
	self.isLongPressRecognized = NO;
	self.firstface = NO;
	self.panning = NO;
	self.startPoint = CGPointMake(0,0);
	self.startTime = 0.0f;
	self.startTouches = nil;
	self.startEvent = nil;
	self.recognizedEdge = UIRectEdgeNone;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

%new
- (BOOL)_isNoRequriedLongPress {
	if (!screenEdgeEnabled()) return NO;
	
	if (self.systemGestureType != SBSystemGestureTypeSwitcherForcePress) {
		if ([[%c(SBUIController) sharedInstanceIfExists] isAppSwitcherShowing])
			return YES;
		
		if (UIInterfaceOrientationIsLandscape(self._touchInterfaceOrientation))
			return YES;
	}
	
	if (self.recognizedEdge == UIRectEdgeLeft && !self._needLongPressForLeft) {
		return YES;
	}
	else if (self.recognizedEdge == UIRectEdgeRight && !self._needLongPressForRight) {
		return YES;
	}
	else if (self.recognizedEdge == UIRectEdgeTop && !self._needLongPressForTop) {
		return YES;
	}
	else if (self.recognizedEdge == UIRectEdgeBottom && !self._needLongPressForBottom) {
		return YES;
	}
	
	return NO;
}

- (CGPoint)locationInView:(UIView *)view {
	CGPoint rtn = %orig;
	
	if (switcherAutoFlipping()) {
		switch (self.recognizedEdge) {
			case UIRectEdgeRight: {
					CGSize screenSize = [UIScreen mainScreen].bounds.size;
					CGFloat x = screenSize.width - rtn.x;
					rtn.x = x;
				}
				break;
			case UIRectEdgeBottom: {
					CGSize screenSize = [UIScreen mainScreen].bounds.size;
					CGFloat x = (screenSize.height - rtn.y) / screenSize.height * screenSize.width;
					rtn.x = x;
				}
				break;
			case UIRectEdgeTop: {
					CGSize screenSize = [UIScreen mainScreen].bounds.size;
					CGFloat x = rtn.y / screenSize.height * screenSize.width;
					rtn.x = x;
				}
				break;
		}
	}
	
	return rtn;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (!screenEdgeEnabled()) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	self.startTouches = [touches copy];
	self.startEvent = [event retain];
	
	UITouch *touch = [touches anyObject];

	if ([touch tapCount] != 1) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	CGPoint location = [self _locationForTouch:touch];
	
	BOOL inEdge = NO;
	self.recognizedEdge = UIRectEdgeNone;
	if ((self.edges & UIRectEdgeLeft) != 0 && location.x <= [self _edgeRegionSize]) {
		inEdge = YES;
		self.recognizedEdge |= UIRectEdgeLeft;
	}
	else if ((self.edges & UIRectEdgeRight) != 0 && (screenSize.width - location.x) <= [self _edgeRegionSize]) {
		inEdge = YES;
		self.recognizedEdge |= UIRectEdgeRight;
	}
	if ((self.edges & UIRectEdgeTop) != 0 && location.y <= [self _edgeRegionSize]) {
		inEdge = YES;
		self.recognizedEdge |= UIRectEdgeTop;
	}
	else if ((self.edges & UIRectEdgeBottom) != 0 && (screenSize.height - location.y) <= [self _edgeRegionSize]) {
		inEdge = YES;
		self.recognizedEdge |= UIRectEdgeBottom;
	}
	
	if (!inEdge)
		self.state = UIGestureRecognizerStateFailed;
	
	if (self.state == UIGestureRecognizerStateFailed) return;
	
	if (self.recognizedEdge & ~(UIRectEdgeLeft | UIRectEdgeRight)) {
		CGFloat x = MIN(ABS(screenSize.width - location.x), location.x);
		CGFloat y = MIN(ABS(screenSize.height - location.y), location.y);
		
		if (self.recognizedEdge & ~UIRectEdgeLeft) {
			if (x > y) {
				self.recognizedEdge &= ~UIRectEdgeLeft;
			}
			else {
				self.recognizedEdge = UIRectEdgeLeft;
			}
		}
		else if (self.recognizedEdge & ~UIRectEdgeRight) {
			if (x > y) {
				self.recognizedEdge &= ~UIRectEdgeRight;
			}
			else {
				self.recognizedEdge = UIRectEdgeRight;
			}
		}
	}
	
	if ([[%c(SBNotificationCenterController) sharedInstanceIfExists] isVisible]) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	if ([[%c(SBControlCenterController) sharedInstanceIfExists] isVisible]) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	if ([self _isNoRequriedLongPress]) {
		self.firstface = YES;
		%orig;
		//return;
	}
	
	if (!self.isLongPressRecognized) {
		if (self.startTime == 0.0f) {
			self.startPoint = [self _locationForTouch:touch];
			self.startTime = [[NSDate date] timeIntervalSince1970];
			[self performSelector:@selector(longPressTimerElapsed:) withObject:self afterDelay:self.minimumPressDurationForLongPress];
		}
		return;
	}
	
	%orig;
}

%new
- (void)longPressTimerElapsed:(id)unused {
	self.isLongPressRecognized = YES;
	
	if ([self _isNoRequriedLongPress] && !self.panning) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	
	if (self.state != UIGestureRecognizerStateCancelled 
			&& self.state != UIGestureRecognizerStateFailed 
			&& self.state != UIGestureRecognizerStateRecognized) {
		self.firstface = YES;
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
			
			self.panning = YES;
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
				self.isLongPressRecognized = YES;
				self.state = UIGestureRecognizerStateFailed;
				return;
			}
			
			self.panning = YES;
		}
		
		self.firstface = YES;
		%orig;
		return;
	}
	
	if (!self.isLongPressRecognized) {
		UITouch *touch = [touches anyObject];
		
		CGPoint curPoint = [self _locationForTouch:touch];
		CGFloat dx = fabs(self.startPoint.x - curPoint.x);
		CGFloat dy = fabs(self.startPoint.y - curPoint.y);
		CGFloat distance = sqrt(dx*dx + dy*dy);
		
		if (distance > self.allowableMovementForLongPress) {
			self.state = UIGestureRecognizerStateFailed;
			return;
		}
		
		if (self.startTime + self.minimumPressDurationForLongPress <= [[NSDate date] timeIntervalSince1970]
				&& self.state != UIGestureRecognizerStateCancelled 
				&& self.state != UIGestureRecognizerStateFailed 
				&& self.state != UIGestureRecognizerStateRecognized) {
			self.isLongPressRecognized = YES;
			self.firstface = YES;
		}
		else {
			return;
		}
	}
	
	%orig;
}

%end


