#import "headers.h"



@interface SB3DTMSwitcherForceLongPressPanGestureRecognizer : SBSwitcherForcePressSystemGestureRecognizer
//@property (nonatomic) NSUInteger numberOfTapsRequired;	// 0
//@property (nonatomic) NSUInteger numberOfTouchesRequired;	// 1
@property (nonatomic) CFTimeInterval minimumPressDurationForLongPress;
@property (nonatomic) CGFloat allowableMovementForLongPress;
@property (nonatomic) BOOL isLongPressRecognized;
@property (nonatomic, getter=isFirstFace) BOOL firstface;
@property (nonatomic) BOOL panning;
@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CFTimeInterval startTime;
@property (nonatomic, copy) NSSet<UITouch *> *startTouches;
@property (nonatomic, retain) UIEvent *startEvent;
@property (nonatomic) UIRectEdge recognizedEdge;
@property (nonatomic) BOOL _needLongPressForLeft;
@property (nonatomic) BOOL _needLongPressForRight;
@property (nonatomic) BOOL _needLongPressForTop;
@property (nonatomic) BOOL _needLongPressForBottom;
@property (nonatomic) BOOL shouldUseGrapeFlags;
@property (nonatomic) SBSystemGestureType systemGestureType;

- (id)initWithTarget:(id)target action:(SEL)action systemGestureType:(SBSystemGestureType)gsType;
- (id)initWithType:(int)type systemGestureType:(SBSystemGestureType)gsType target:(id)target action:(SEL)action;
- (BOOL)_isNoRequriedLongPress;
@end


