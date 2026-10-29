// Menu UIKit cho obscure_engine, dùng đúng struct RenderContextState
// trong ObscureState.h. Các công tắc/thanh trượt chỉ đổi giá trị
// trong struct, không có offset/hook/ghi nhớ nào.
// Các hàm GfxCore gốc vẫn là stub, menu này thay thế phần hiển thị.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include "ObscureState.h"

extern "C" void ObscureShowMenu();

namespace {

UILabel *MakeLabel(NSString *text, CGFloat size, BOOL bold) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    label.textColor = UIColor.whiteColor;
    label.numberOfLines = 0;
    return label;
}

UIView *MakeSwitchRow(NSString *title, bool *flag) {
    UIView *row = [[UIView alloc] init];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *label = MakeLabel(title, 15, YES);
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = *flag;
    [sw addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        *flag = sw.on;
    }] forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:sw];
    [row addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:4],
        [stack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-4],
        [stack.topAnchor constraintEqualToAnchor:row.topAnchor constant:6],
        [stack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-6],
        [stack.heightAnchor constraintGreaterThanOrEqualToConstant:40],
    ]];
    return row;
}

UIView *MakeSliderRow(NSString *title, float *value, float minV, float maxV) {
    UIView *row = [[UIView alloc] init];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *label = MakeLabel(title, 15, YES);
    UILabel *valueLabel = MakeLabel(@"", 13, NO);
    auto updateLabel = ^(float v) {
        *value = v;
        valueLabel.text = [NSString stringWithFormat:@"Giá trị: %.2f", (double)v];
    };
    updateLabel(*value);
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = minV; slider.maximumValue = maxV; slider.value = *value;
    [slider addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        updateLabel(slider.value);
    }] forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:valueLabel];
    [stack addArrangedSubview:slider];
    [row addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:4],
        [stack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-4],
        [stack.topAnchor constraintEqualToAnchor:row.topAnchor constant:6],
        [stack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-6],
    ]];
    return row;
}

UIView *MakeSection(NSString *title, NSArray<UIView *> *rows) {
    UIStackView *section = [[UIStackView alloc] init];
    section.axis = UILayoutConstraintAxisVertical;
    section.spacing = 2;
    UILabel *header = MakeLabel(title, 13, YES);
    header.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    [section addArrangedSubview:header];
    for (UIView *row in rows) [section addArrangedSubview:row];
    UIView *sep = [[UIView alloc] init];
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    [sep.heightAnchor constraintEqualToConstant:1].active = YES;
    [section addArrangedSubview:sep];
    return section;
}

} // namespace

@interface ObscureMenuManager : NSObject
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIButton *floatButton;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic) BOOL panelOpen;
@property (nonatomic) CGPoint dragStart;
@property (nonatomic) BOOL dragged;
+ (instancetype)shared;
- (void)show;
@end

@implementation ObscureMenuManager

+ (instancetype)shared {
    static ObscureMenuManager *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [[ObscureMenuManager alloc] init]; });
    return s;
}

- (void)show {
    if (self.window) return;
    RenderContextState &ctx = ObscureState();
    UIWindow *keyWindow = nil;
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) keyWindow = w;
    }
    CGRect bounds = keyWindow ? keyWindow.bounds : UIScreen.mainScreen.bounds;
    self.window = [[UIWindow alloc] initWithFrame:bounds];
    self.window.windowLevel = UIWindowLevelAlert + 1;
    self.window.backgroundColor = UIColor.clearColor;
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = UIColor.clearColor;
    self.window.rootViewController = vc;
    self.window.hidden = NO;

    self.floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatButton.frame = CGRectMake(bounds.size.width - 64, bounds.size.height * 0.4, 52, 52);
    [self.floatButton setTitle:@"O" forState:UIControlStateNormal];
    self.floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.floatButton.backgroundColor = [UIColor colorWithRed:0.15 green:0.45 blue:0.95 alpha:0.95];
    self.floatButton.layer.cornerRadius = 26;
    self.floatButton.layer.shadowOpacity = 0.4;
    [self.floatButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [self.floatButton addGestureRecognizer:pan];
    [vc.view addSubview:self.floatButton];

    CGFloat panelW = MIN(340, bounds.size.width - 24);
    CGFloat panelH = MIN(560, bounds.size.height - 60);
    self.panel = [[UIView alloc] initWithFrame:CGRectMake((bounds.size.width - panelW) / 2,
                                                          (bounds.size.height - panelH) / 2, panelW, panelH)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.96];
    self.panel.layer.cornerRadius = 16;
    self.panel.hidden = YES;
    self.panel.transform = CGAffineTransformMakeScale(0.9, 0.9);
    self.panel.alpha = 0;
    [vc.view addSubview:self.panel];

    UILabel *title = MakeLabel(@"Graphics Pipeline Diagnostic Panel", 16, YES);
    title.frame = CGRectMake(16, 12, panelW - 72, 24);
    [self.panel addSubview:title];
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"Đóng" forState:UIControlStateNormal];
    close.frame = CGRectMake(panelW - 64, 8, 56, 30);
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:close];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 48, panelW, panelH - 92)];
    [self.panel addSubview:scroll];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-14],
        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:4],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-4],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-28],
    ]];

    [stack addArrangedSubview:MakeSection(@"Core Metrics", @[
        MakeSwitchRow(@"Enable Alpha Pass", &ctx.state_alpha),
        MakeSwitchRow(@"High Precision Sample", &ctx.state_beta),
        MakeSwitchRow(@"Buffer Channel Lock", &ctx.state_gamma),
        MakeSwitchRow(@"Enhanced Filtering", &ctx.state_delta),
        MakeSwitchRow(@"Frame Sync Lock", &ctx.state_epsilon),
        MakeSwitchRow(@"Auto Resolution Match", &ctx.state_zeta),
        MakeSliderRow(@"Metric Scaling Factor", &ctx.metric_scale, 1.0f, 50.0f),
    ])];
    [stack addArrangedSubview:MakeSection(@"Resource Stream", @[
        MakeSwitchRow(@"Cache Stream A", &ctx.data_node_a),
        MakeSwitchRow(@"Cache Stream B", &ctx.data_node_b),
        MakeSwitchRow(@"Cache Stream C", &ctx.data_node_c),
        MakeSwitchRow(@"Cache Stream D", &ctx.data_node_d),
        MakeSwitchRow(@"Cache Stream E", &ctx.data_node_e),
    ])];
    [stack addArrangedSubview:MakeSection(@"Runtime Config", @[
        MakeSwitchRow(@"Extension Protocol Alpha", &ctx.flag_routine_1),
        MakeSwitchRow(@"Dynamic Boost Matrix", &ctx.flag_routine_2),
        MakeSwitchRow(@"Stream Persistence Layer", &ctx.flag_routine_3),
        MakeSwitchRow(@"Telemetry Suppression", &ctx.flag_routine_4),
    ])];
    [stack addArrangedSubview:MakeSection(@"Vector & Speed Tuning", @[
        MakeSwitchRow(@"Simulation Vector Active", &ctx.ctrl_mode_a),
        MakeSliderRow(@"Simulation Clock Rate", &ctx.val_speed_a, 1.0f, 10.0f),
        MakeSwitchRow(@"Engine Clock Sync Active", &ctx.ctrl_mode_b),
        MakeSliderRow(@"Engine Clock Multiplier", &ctx.val_speed_b, 1.0f, 10.0f),
        MakeSwitchRow(@"Viewport Scaling Active", &ctx.view_zoom_en),
        MakeSliderRow(@"Viewport Scale Multiplier", &ctx.view_zoom_factor, 1.0f, 2.5f),
    ])];
    [stack addArrangedSubview:MakeSection(@"Output & Diagnostic", @[
        MakeSwitchRow(@"Refresh Rate 120Hz Force", &ctx.perf_sync_120),
        MakeSwitchRow(@"Telemetry Overlay Stats", &ctx.perf_debug_info),
        MakeSwitchRow(@"Security Handshake Bypass", &ctx.sys_bypass_sec),
        MakeSwitchRow(@"Virtual Environment Identity", &ctx.sys_mock_id),
    ])];

    UILabel *footer = MakeLabel(@"Menu chỉ đổi giá trị trong struct, chưa có offset/hook/ghi nhớ.", 12, NO);
    footer.frame = CGRectMake(16, panelH - 36, panelW - 32, 28);
    [self.panel addSubview:footer];
    [self.window makeKeyAndVisible];
    if (keyWindow) [keyWindow makeKeyWindow];
}

- (void)togglePanel {
    self.panelOpen = !self.panelOpen;
    self.panel.hidden = NO;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        self.panel.alpha = self.panelOpen ? 1 : 0;
        self.panel.transform = self.panelOpen ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(__unused BOOL done) {
        self.panel.hidden = !self.panelOpen;
    }];
}

- (void)onPan:(UIPanGestureRecognizer *)pan {
    CGPoint p = [pan locationInView:self.window.rootViewController.view];
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.dragStart = p; self.dragged = NO;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        if (fabs(p.x - self.dragStart.x) + fabs(p.y - self.dragStart.y) > 8) self.dragged = YES;
        if (self.dragged) {
            CGRect f = self.floatButton.frame;
            f.origin.x = MAX(0, MIN(p.x - 26, self.window.bounds.size.width - 52));
            f.origin.y = MAX(0, MIN(p.y - 26, self.window.bounds.size.height - 52));
            self.floatButton.frame = f;
        }
    } else if (pan.state == UIGestureRecognizerStateEnded && self.dragged) {
        CGRect f = self.floatButton.frame;
        CGFloat midX = f.origin.x + 26;
        f.origin.x = (midX < self.window.bounds.size.width / 2) ? 8 : self.window.bounds.size.width - 60;
        [UIView animateWithDuration:0.2 animations:^{ self.floatButton.frame = f; }];
    }
}

@end

extern "C" void ObscureShowMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ObscureMenuManager shared] show];
    });
}
