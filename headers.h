#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIGestureRecognizerSubclass.h>



@interface _UIForceLevelClassifier : NSObject @end
@interface UIInteractionProgress : NSObject
@property (nonatomic, readonly) CGFloat percentComplete;
@property (nonatomic, readonly) CGFloat velocity;
@end
@interface UIPreviewForceInteractionProgress : UIInteractionProgress @end

@interface _UITouchForceObservable : NSObject @end
@interface _UITouchForceObservable (NEW)
- (BOOL)__sb3dtm_needToEmulate;
- (void)__sb3dtm_setNeedToEmulate:(BOOL)value;
@end

@interface SBIconView : UIView
@property(nonatomic, assign) id /*<SBIconViewDelegate>*/ delegate;
@property(retain, nonatomic) UIPreviewForceInteractionProgress *shortcutMenuPresentProgress;
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture;
- (void)cancelLongPressTimer;
- (void)setHighlighted:(BOOL)arg1;
- (BOOL)isHighlighted;
@end

@interface SBApplicationShortcutMenu : NSObject /*<SBIconViewDelegate>*/
@property(nonatomic) NSUInteger presentState;
@property(readonly, retain, nonatomic) UIInteractionProgress *interactionProgress;
- (void)iconHandleLongPress:(id)arg1;
@property(readonly, nonatomic) BOOL isPresented;
@property(nonatomic, weak) SBIconView *iconView;
@end

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

