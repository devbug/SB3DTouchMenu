#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIGestureRecognizerSubclass.h>



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

@interface SBIconController (NEW)
- (void)__sb3dtm_resetAllIconsGesture;
@end
@interface SBIconView (NEW)
- (void)__sb3dtm_setGestures;
- (UIGestureRecognizer *)__sb3dtm_menuGestureCanceller;
- (void)__sb3dtm_setMenuGestureCanceller:(UIGestureRecognizer *)value;
@end

@interface SBIcon : NSObject @end
@interface SBIconModel : NSObject
- (id)_applicationIcons;
- (id)iconsOfClass:(Class)arg1;
- (id)leafIcons;
@end
@interface SBIconViewMap : NSObject
+ (id)homescreenMap;
@property(readonly, retain, nonatomic) SBIconModel *iconModel;
- (id)mappedIconViewForIcon:(id)arg1;
@end

@interface UIGestureRecognizer (Firmware90_Private)
- (void)setRequiredPreviewForceState:(int)arg1;
@end

@interface UITouch (Private)
@property (nonatomic, readonly) CGFloat majorRadius;
@property (nonatomic, readonly) CGFloat majorRadiusTolerance;
@end


@interface UIScreenEdgePanGestureRecognizer (Private)
- (id)initWithTarget:(id)target action:(SEL)action type:(int)type;
- (CGFloat)_edgeRegionSize;
- (CGPoint)_locationForTouch:(id)arg1;
- (void)_setEdgeRegionSize:(CGFloat)arg1;
- (void)_setHysteresis:(CGFloat)arg1;
- (UIInterfaceOrientation)_touchInterfaceOrientation;
- (BOOL)_shouldUseGrapeFlags;
@end

@protocol SBSystemGestureRecognizerDelegate <UIGestureRecognizerDelegate>
- (UIView *)viewForSystemGestureRecognizer:(UIGestureRecognizer *)arg1;
@end

@protocol SBTouchTemplateGestureRecognizerDelegate <SBSystemGestureRecognizerDelegate>
@optional
- (void)matchFailedWithMorphs:(NSArray *)arg1;
@end

@interface SBScreenEdgePanGestureRecognizer : UIScreenEdgePanGestureRecognizer @end
@interface SBSwitcherForcePressSystemGestureRecognizer : UIScreenEdgePanGestureRecognizer @end


typedef NS_ENUM(NSUInteger, SBSystemGestureType) {
	SBSystemGestureTypeShowNotificationCenter = 1,
	SBSystemGestureTypeDismissBanner,
	SBSystemGestureTypeShowControlCenter,
	SBSystemGestureTypeSuspendApp,					// scrunch
	SBSystemGestureTypeSwitcherSlideUp,
	SBSystemGestureTypeSwitchApp,
	SBSystemGestureTypeSceneResize,
	SBSystemGestureTypeSideAppReveal,
	SBSystemGestureTypeSideAppGrabberReveal,
	SBSystemGestureTypeSideAppOverlayDismiss,
	SBSystemGestureTypeSideSwitcherReveal,
	SBSystemGestureTypeSideSwitcherGrabberPress,
	SBSystemGestureTypeSwitcherForcePress,
	SBSystemGestureTypeCarPlayBannerDismiss
};

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

@interface SBUIController : NSObject <SBTouchTemplateGestureRecognizerDelegate>
+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
- (void)_addRemoveSwitcherGesture;
- (BOOL)isAppSwitcherShowing;
@end

@interface UIGestureRecognizerTarget : NSObject {
	SEL _action;
	id _target;
}
@end

@interface SpringBoard : UIApplication
- (UIInterfaceOrientation)activeInterfaceOrientation;
@end

@interface SBNotificationCenterController : NSObject <SBSystemGestureRecognizerDelegate>
+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
@property(readonly, nonatomic, getter=isVisible) BOOL visible;
@end

@interface SBControlCenterController : UIViewController <SBSystemGestureRecognizerDelegate>
+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
- (BOOL)isVisible;
@end

@interface SBNotificationCenterController (NEW)
- (void)__sb3dtm_addSystemGestureRecognizer;
@end
@interface SBControlCenterController (NEW)
- (void)__sb3dtm_addSystemGestureRecognizer;
@end


@interface SBSwitcherContainerView : UIView @end
@interface SBAppSwitcherScrollView : UIScrollView @end
@interface SBDeckSwitcherPageView : UIView @end
@interface SBSwitcherAppSuggestionBottomBannerView : UIView @end
@interface SBDeckSwitcherIconImageContainerView : UIView @end
@interface SBDeckSwitcherItemContainer : UIView @end

@interface SBMainSwitcherViewController : UIViewController
+ (id)sharedInstance;
- (void)prepareForReuse;
- (void)viewDidLoad;
- (void)loadView;
@end


@interface UIPeripheralHost : NSObject
+ (id)activeInstance;
+ (id)sharedInstance;
+ (struct CGRect)visiblePeripheralFrame;
- (BOOL)isOffScreen;
- (BOOL)isOnScreen;
@end


@interface SBOrientationTransformWrapperView : UIView @end
@interface SBSwitcherAppSuggestionSlideUpView : UIView @end
@interface SBSwitcherAppSuggestionContentView : UIView @end
@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end
@interface SBApplicationController : NSObject
+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
- (SBApplication *)musicApplication;
@end
@interface SBBestAppSuggestion : NSObject @end
@interface SBSwitcherAppSuggestionViewController : UIViewController @end


@interface BSEventQueueEvent : NSObject
+ (id)eventWithName:(NSString *)name handler:(void(^)(void))handler;
- (void)executeFromEventQueue;
- (void)execute;
@end
@interface FBWorkspaceEvent : BSEventQueueEvent
- (void)execute;
@end
@interface BSEventQueue : NSObject
@property(retain, nonatomic) BSEventQueueEvent *executingEvent;
- (BOOL)hasEventWithName:(id)arg1;
- (BOOL)hasEventWithPrefix:(id)arg1;
- (void)cancelEventsWithName:(id)arg1;
@end
@interface FBWorkspaceEventQueue : BSEventQueue
+ (id)sharedInstance;
- (void)executeOrPrependEvent:(id)arg1;
- (void)executeOrAppendEvent:(id)arg1;
@end

