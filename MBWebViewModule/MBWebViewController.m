//
//  MBWebViewController.m
//  MBWebViewController
//
//  Created by hz on 2018/8/9.
//  Copyright © 2018年 hz. All rights reserved.
//

#import "MBWebViewController.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSNotificationCenter+PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
//进度条
#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import <NJKWebViewProgress/NJKWebViewProgressView.h>
//下拉刷新
#import <MJRefresh/MJRefresh.h>
//网络图片
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImagePrefetcher.h>
//选择图片
#import <MBPhotoPicker/HXPhotoPicker.h>
#import "UploadImageTool.h"
//js交互
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
//动态配置
#import "MBWebViewConfigModel.h"
//导航栏标题
#import "MBWebNavigationTitleView.h"
#import "MBWebNavigationTitleTabView.h"
//H5秒开
#import <VasSonic/Sonic.h>
#import "SonicJSContext.h"
//url跳转
#import "NavigatorModule.h"
//选择项目
#import <SelectProject/SelectProjectViewController.h>

@interface MBWebViewController ()<UIWebViewDelegate, QMUINavigationControllerDelegate, UIScrollViewDelegate, NJKWebViewProgressDelegate, QMUIImagePreviewViewDelegate, SonicSessionDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewConstraintTop;

@property (strong, nonatomic) NJKWebViewProgress *progressProxy;
@property (strong, nonatomic) NJKWebViewProgressView *progressView;

//滚动导航栏透明
@property (assign, nonatomic) BOOL scrollTransparentEnable; //默认NO
@property (assign, nonatomic) float scrollTransparentHeight;

//导航栏菜单按钮
@property (nonatomic, strong) QMUIPopupMenuView *popupAtBarButtonItem;

//查看大图
@property (nonatomic, strong) QMUIImagePreviewViewController *imagePreviewViewController;
@property (strong, nonatomic) NSArray *imageUrls;

//选择图片
@property (strong, nonatomic) HXPhotoManager *manager;
//js 交互
@property (strong, nonatomic) WebViewJavascriptBridge *bridge;
//js配置
@property (strong, nonatomic) MBWebViewConfigModel *configModel;
//H5秒开
@property (nonatomic,strong)JSContext *jscontext;
@property (nonatomic,strong)SonicJSContext *sonicContext;
@property (nonatomic,strong) NSNumber *clickTime;

@end

@implementation MBWebViewController

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        _url = url;
        
        //设置ua
        [self setupUserAgent];
        
        //设置秒开
        [self setupSession];
        
        //登录成功刷新页面
        [NSNotificationCenter once:kNotificationUserLoginDone].then(^(id data){
            [self reloadWebView];
        });
        
        [QMUITips showLoading:@"加载中" inView:self.view];
    }
    return self;
}

- (void)setupSession
{
    self.clickTime = @([[NSDate date]timeIntervalSince1970]*1000);
    
    SonicSessionConfiguration *configuration = [SonicSessionConfiguration new];
    
    if ([NSClassFromString(@"MBRequestHeaderModel") respondsToSelector:NSSelectorFromString(@"sharedInstance")])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        JSONModel *model = [NSClassFromString(@"MBRequestHeaderModel") performSelector:NSSelectorFromString(@"sharedInstance")];
        
#pragma clang diagnostic pop
        
        NSDictionary *headersDic = [model toDictionary];
        configuration.customRequestHeaders = headersDic;
    }
    
    configuration.supportCacheControl = YES;
    
    [[SonicEngine sharedEngine] createSessionWithUrl:self.url.absoluteString withWebDelegate:self withConfiguration:configuration];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //返回按钮
    UIBarButtonItem *backItem = [UIBarButtonItem qmui_backItemWithTarget:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backItem;
    
    self.webView.scrollView.showsVerticalScrollIndicator = NO;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    self.webView.scrollView.delegate = self;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    
    SonicSession *session = [[SonicEngine sharedEngine] sessionWithWebDelegate:self];
    if (session)
    {
        [self.webView loadRequest:[SonicUtil sonicWebRequestWithSession:session withOrigin:request]];
    }else{
        [self.webView loadRequest:request];
    }
    
    //添加进度条
    //    self.webView.delegate = self.progressProxy;
    [self.view addSubview:self.progressView];
    
    //添加js交互
    // 开启日志，方便调试
#ifdef DEBUG
    [WebViewJavascriptBridge enableLogging];
#endif
    //注册js调用方法
    [self bridgeRegisterHandler];
    
    self.sonicContext.owner = (id)self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 在横竖屏旋转时，viewDidLayoutSubviews 这个时机还无法获取到正确的 navigationItem 的 frame，所以直接隐藏掉
    if (self.popupAtBarButtonItem.isShowing) {
        [self.popupAtBarButtonItem hideWithAnimated:NO];
    }
}

#pragma mark - bridge registerHandler

- (void)bridgeRegisterHandler
{
    [self.bridge registerHandler:@"navigation" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSError *error;
        self.configModel = [[MBWebViewConfigModel alloc] initWithDictionary:data error:&error];
        
        if (error) {
            [MBTips showTipWithText:error.localizedDescription inView:self.view];
            return;
        }
        
        //下载图片并缓存url图片
        [self cacheUrlIconWithConfig:data completed:^{
            [self jsConfig];
        }];
        
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
    
    //注册js调用方法
#ifdef DEBUG
    //打印日志
    [self.bridge registerHandler:@"javascriptLog" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"html5:\n%@", data);
        
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
#endif
    
    //点击查看大图
    [self.bridge registerHandler:@"previewImage" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSArray *urls = data[@"urls"];
        NSUInteger current = [data[@"current"] integerValue];
        
        [self imagePreviewWithUrls:urls current:current];
        
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
    
    //预约
    [self.bridge registerHandler:@"reservation" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        //        [NavigatorModule URLString:@"meb://reservation" query:data].then(nil);
        [DCURLRouter pushURLString:@"meb://reservation" query:data animated:YES];
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
    
    //咨询
    [self.bridge registerHandler:@"consulting" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        [NavigatorModule URLString:@"meb://advisory"].then(nil);
        
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
    
    //选择图片
    [self.bridge registerHandler:@"chooseImage" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        [self presentAlbumViewControllerWithCount:[data[@"count"] integerValue] sourceType:data[@"sourceType"]].then(^(NSArray *URLStringArray){
            
            if (responseCallback) {
                responseCallback(@{@"messageId":@"1", @"message":@"完成", @"data":URLStringArray});
            }
        }).catch(^(NSError *error){
            [MBTips showTipWithText:error.localizedDescription inView:self.view];
            
            if (responseCallback) {
                responseCallback(@{@"messageId":@"0", @"message":error.localizedDescription ? : @"", @"data":@""});
            }
        });
    }];
    
    //跳转到地图
    [self.bridge registerHandler:@"openLocation" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        [NavigatorModule URLString:@"meb://map" query:data];
        
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
    
    //选择项目
    [self.bridge registerHandler:@"selectProject" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        [QMUITips showError:@"没有集成选项目"];
        
        if (responseCallback) {
            responseCallback(@{});
        }
        
        SelectProjectViewController *vc = [[SelectProjectViewController alloc] init];
        [vc selectProjectAction:^(NSString *projectName, NSString *projectID) {
            
            [self dismissViewControllerAnimated:YES completion:^{
                if (responseCallback) {
                    responseCallback(@{@"name":projectName ?: @"", @"id":projectID ? : @""});
                }
            }];
        }];
        
        QMUINavigationController *nav = [[QMUINavigationController alloc] initWithRootViewController:vc];
        vc.title = @"选择项目";
        UIBarButtonItem *closeItem = [UIBarButtonItem qmui_closeItemWithTarget:vc action:@selector(goBack)];
        vc.navigationItem.leftBarButtonItem = closeItem;
        [self presentViewController:nav animated:YES completion:nil];
        //
        //        [[vc rac_signalForSelector:@selector(goBack)] subscribeNext:^(RACTuple * _Nullable x) {
        //
        //            if (responseCallback) {
        //                responseCallback(@{});
        //            }
        //        }];
    }];
    
    //返回上一页
    [self.bridge registerHandler:@"goBack" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        [self goBack];
        
        if (responseCallback) {
            responseCallback(@{});
        }
    }];
    
    //打电话
    [self.bridge registerHandler:@"tel" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSString *tel = [NSString stringWithFormat:@"tel:%@", data[@"phoneNumber"]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tel] options:@{} completionHandler:^(BOOL success) {
            if (responseCallback) {
                responseCallback(@{});
            }
        }];
    }];
}

#pragma mark - action

/**
 刷新页面
 */
- (void)reloadWebView
{
    [self.webView reload];
    [self hideEmptyView];
}

/**
 下拉刷新
 */
- (void)refreshingAction
{
    NSString *command = self.configModel.pullCommand ? : @"";
    [self.bridge callHandler:@"navigationEvent" data:@{@"command":command} responseCallback:^(id responseData) {
        //停止下拉刷新
        if (self.webView.scrollView.mj_header) {
            [self.webView.scrollView.mj_header endRefreshing];
        }
    }];
    
    [self hideEmptyView];
}

/**
 *  返回上一页
 */
- (void)goBack
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        [self hideEmptyView];
    }
    else
    {
        if([self qmui_isPresented])
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

/**
 显示加载错误提示
 */
- (void)showLoadingErrorEmptyWithCode:(NSInteger)code
{
    [self showEmptyView];
    
    [self.emptyView setActionButtonTitleColor:UIColorMake(255, 102, 102)];
    [self.emptyView setLoadingViewHidden:YES];
    [self.emptyView setLoadingViewInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self.emptyView setActionButtonInsets:UIEdgeInsetsMake(57, 60, 0, 60)];
    
    self.emptyView.backgroundColor = UIColorMake(248, 248, 248);
    self.emptyView.actionButton.contentEdgeInsets = UIEdgeInsetsMake(10, 80, 10, 80);
    self.emptyView.actionButton.layer.borderColor = UIColorMake(255, 102, 102).CGColor;
    self.emptyView.actionButton.layer.borderWidth = 1;
    self.emptyView.actionButton.layer.cornerRadius = 3;
    
    [self.emptyView.actionButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    if (code == 404 || code == 500)
    {
        [self.emptyView setImage:[UIImage imageNamed:@"MBWeb404.png"]];
        [self.emptyView setActionButtonTitle:@"点击返回"];
        [self.emptyView.actionButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [self.emptyView setImage:[UIImage imageNamed:@"MBWeb加载超时.png"]];
        [self.emptyView setActionButtonTitle:@"加载重试"];
        [self.emptyView.actionButton addTarget:self action:@selector(reloadWebView) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)hideEmptyView
{
    [super hideEmptyView];
    
    //停止加载动画
    [QMUITips hideAllTipsInView:self.view];
}

#pragma mark - 添加下拉刷新
- (void)addRefreshing
{
    //添加下拉刷新
    self.webView.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshingAction)];
}

- (void)removeRefreshing
{
    self.webView.scrollView.mj_header = nil;
}

#pragma mark - 导航栏透明度控制

- (void)addScrollTransparentHeight:(CGFloat)height
{
    self.scrollTransparentEnable = YES;
    self.scrollTransparentHeight = height;
    
    [self setNavigationBarBackgroundAlpha:0];
    
    //去掉阴影
    self.navigationController.navigationBar.shadowImage = [UIImage qmui_imageWithColor:UIColorClear size:CGSizeMake(1, 1) cornerRadius:0];
    
    //设置webView顶部位置
    if (@available(iOS 11.0, *))
    {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        
#pragma clang diagnostic pop
        
    }
}

- (void)removeScrollTransparent
{
    self.scrollTransparentEnable = NO;
    
    [self setNavigationBarBackgroundAlpha:1];
    
    //加回阴影
    self.navigationController.navigationBar.shadowImage = [UIImage qmui_imageWithColor:UIColorSeparator size:CGSizeMake(1, 1) cornerRadius:0];
    
    //设置webView顶部位置
    if (@available(iOS 11.0, *))
    {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        self.automaticallyAdjustsScrollViewInsets = YES;
        
#pragma clang diagnostic pop
    }
}

- (void)setNavigationBarBackgroundAlpha:(CGFloat)alpha
{
    if (alpha < 0)
    {
        alpha = 0;
    }
    
    UIImage *image = [UIImage qmui_imageWithColor:[UIColorWhite colorWithAlphaComponent:alpha]];
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    self.titleView.alpha = alpha;
    self.navigationItem.titleView.alpha = alpha;
}

#pragma mark - 设置 navigationItem

/**
 设置一个按钮
 
 @param text 按钮的标题
 */
- (void)setRightBarButtonItemWithText:(NSString *)text
{
    UIBarButtonItem *item = [self barButtonItemWithString:text];
    item.tag = 0;
    
    self.navigationItem.rightBarButtonItem = item;
}

/**
 设置多个按钮 (最多两个)
 
 @param texts 按钮的标题
 */
- (void)setRightBarButtonItemWithTexts:(NSArray *)texts
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:texts.count];
    
    for (NSUInteger i = 0; i < texts.count; i++)
    {
        if (i > 1) {
            break;
        }
        
        NSString *text = texts[i];
        
        UIBarButtonItem *item = [self barButtonItemWithString:text];
        item.tag = i;
        [items addObject:item];
    }
    
    self.navigationItem.rightBarButtonItems = items;
}

/**
 创建barButtonItem, 支持文字和图片
 
 @param string 支持文字和图片
 */
- (UIBarButtonItem *)barButtonItemWithString:(NSString *)string
{
    //图片
    if ([string hasPrefix:@"http://"] || [string hasPrefix:@"https://"]) {
        UIImage *image = [self iconImageWithUrl:[NSURL URLWithString:string]];
        UIBarButtonItem *item = [UIBarButtonItem qmui_itemWithImage:image target:self action:@selector(rightBarButtonAction:)];
        return item;
    }
    //文字
    else
    {
        UIBarButtonItem *item = [UIBarButtonItem qmui_itemWithTitle:string target:self action:@selector(rightBarButtonAction:)];
        return item;
    }
}

- (void)setTitleItemWithTexts:(NSArray *)titles
{
    NSMutableArray *texts = [NSMutableArray array];
    for (MBWebViewConfigNavigationItemModel *model in titles) {
        [texts addObject:model.name];
    }
    
    MBWebNavigationTitleTabView *titleView = [[MBWebNavigationTitleTabView alloc] initButtonsWithItems:texts];
    titleView.selectIndedx = self.configModel.tabCheckd.integerValue;
    
    for (UIButton *button in titleView.buttons)
    {
        [button removeTarget:self action:@selector(centerTitleAction:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(centerTitleAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    self.navigationItem.titleView = titleView;
}

#pragma mark - navigationItem Action

- (void)rightBarButtonAction:(id)sender
{
    NSUInteger index = [sender tag];
    
    if (self.configModel.buttons.count <= index)
    {
        return;
    }
    
    MBWebViewConfigNavigationItemModel *itemModel = self.configModel.buttons[index];
    
    //打开子菜单
    if (itemModel.subMenus && itemModel.subMenus.count)
    {
        if (!self.popupAtBarButtonItem) {
            // 在 UIBarButtonItem 上显示
            self.popupAtBarButtonItem = [[QMUIPopupMenuView alloc] init];
            self.popupAtBarButtonItem.automaticallyHidesWhenUserTap = YES;// 点击空白地方消失浮层
            self.popupAtBarButtonItem.maximumWidth = 180;
            self.popupAtBarButtonItem.shouldShowItemSeparator = YES;
            self.popupAtBarButtonItem.separatorInset = UIEdgeInsetsMake(0, self.popupAtBarButtonItem.padding.left, 0, self.popupAtBarButtonItem.padding.right);
        }
        
        NSMutableArray *popuItems = [NSMutableArray arrayWithCapacity:itemModel.subMenus.count];
        
        for (MBWebViewConfigNavigationItemModel *subItemModel in itemModel.subMenus)
        {
            UIImage *image = [self iconImageWithUrl:subItemModel.icon];
            image = [image qmui_imageResizedInLimitedSize:CGSizeMake(24, 24)];
            
            QMUIPopupMenuButtonItem *item = [QMUIPopupMenuButtonItem itemWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] title:subItemModel.name handler:^(QMUIPopupMenuButtonItem *aItem) {
                
                NSString *command = subItemModel.command ? : @"";
                [self.bridge callHandler:@"navigationEvent" data:@{@"command":command} responseCallback:nil];
            }];
            
            [popuItems addObject:item];
        }
        
        self.popupAtBarButtonItem.items = popuItems;
        
        if (self.popupAtBarButtonItem.isShowing) {
            [self.popupAtBarButtonItem hideWithAnimated:YES];
        } else {
            // 相对于右上角的按钮布局，显示前重新对准布局，避免横竖屏导致位置不准确
            [self.popupAtBarButtonItem layoutWithTargetView:self.navigationItem.rightBarButtonItem.qmui_view];
            [self.popupAtBarButtonItem showWithAnimated:YES];
        }
    }
    else
    {
        NSString *command = itemModel.command ? : @"";
        [self.bridge callHandler:@"navigationEvent" data:@{@"command":command} responseCallback:nil];
    }
}

- (void)centerTitleAction:(id)sender
{
    NSInteger index = [sender tag];
    
    if (self.configModel.tabs.count <= index) {
        return;
    }
    
    MBWebViewConfigNavigationItemModel *itemModel = self.configModel.tabs[index];
    
    NSString *command = itemModel.command ? : @"";
    [self.bridge callHandler:@"navigationEvent" data:@{@"command":command} responseCallback:^(id responseData) {
    }];
}

- (void)setLeftItemsBackAndHome
{
    //不需要x
    /*
     if ([self.webView canGoBack])
     {
     UIBarButtonItem *backItem = [UIBarButtonItem qmui_backItemWithTarget:self action:@selector(goBack)];
     
     UIBarButtonItem *closeItem = [UIBarButtonItem qmui_closeItemWithTarget:self action:@selector(handleCloseButtonEvent:)];
     
     self.navigationItem.leftBarButtonItems = @[backItem, closeItem];
     }
     else
     {
     UIBarButtonItem *backItem = [UIBarButtonItem qmui_backItemWithTarget:self action:@selector(goBack)];
     self.navigationItem.leftBarButtonItem = backItem;
     }
     */
}

- (void)handleCloseButtonEvent:(id)sender
{
    if([self qmui_isPresented])
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 查看大图

- (void)imagePreviewWithUrls:(NSArray *)urls current:(NSUInteger)current
{
    if (!urls) {
        return;
    }
    
    self.imageUrls = urls;
    
    if (!self.imagePreviewViewController) {
        self.imagePreviewViewController = [[QMUIImagePreviewViewController alloc] init];
        self.imagePreviewViewController.imagePreviewView.delegate = self;
        self.imagePreviewViewController.imagePreviewView.backgroundColor = [UIColor blackColor];
    }
    
    self.imagePreviewViewController.imagePreviewView.currentImageIndex = current;// 默认查看的图片的 index
    [self.imagePreviewViewController startPreviewByFadeIn];
}

#pragma mark - <QMUIImagePreviewViewDelegate>

- (NSUInteger)numberOfImagesInImagePreviewView:(QMUIImagePreviewView *)imagePreviewView {
    return self.imageUrls.count;
}

- (void)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView renderZoomImageView:(QMUIZoomImageView *)zoomImageView atIndex:(NSUInteger)index {
    
    zoomImageView.reusedIdentifier = @(index);
    [zoomImageView showLoading];
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:[NSURL URLWithString:self.imageUrls[index]]
                      options:0
                     progress:nil
                    completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                        if (image) {
                            if ([zoomImageView.reusedIdentifier isEqual:@(index)]) {
                                [zoomImageView hideEmptyView];
                                zoomImageView.image = image;
                            }
                        }
                    }];
}

- (QMUIImagePreviewMediaType)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSUInteger)index {
    return QMUIImagePreviewMediaTypeImage;
}

//点击
- (void)singleTouchInZoomingImageView:(QMUIZoomImageView *)zoomImageView location:(CGPoint)location
{
    [self.imagePreviewViewController exitPreviewByFadeOut];
}

#pragma mark - config

- (void)jsConfig
{
    //下拉刷新
    if (self.configModel.pullCommand.length)
    {
        [self addRefreshing];
    }
    else
    {
        [self removeRefreshing];
    }
    
    //--默认配置--
    
    //关闭滚动透明
    self.scrollTransparentEnable = NO;
    [self removeScrollTransparent];
    
    //关闭滚动隐藏导航栏
    self.navigationController.hidesBarsOnSwipe = NO;
    
    //--默认配置--
    
    if (self.configModel.mode.integerValue == 1)
    {
        if (self.configModel.opaqueHeight.integerValue <= 0) {
            self.configModel.opaqueHeight = @(200);
        }
        
        [self addScrollTransparentHeight:self.configModel.opaqueHeight.floatValue];
    }
    else if (self.configModel.mode.integerValue == 2)
    {
        self.navigationController.hidesBarsOnSwipe = YES;
    }
    
    //设置导航栏右侧按钮
    NSMutableArray *itemNames = [NSMutableArray arrayWithCapacity:self.configModel.buttons.count];
    
    for (MBWebViewConfigNavigationItemModel *itemModel in self.configModel.buttons)
    {
        if (itemModel.icon.absoluteString.length)
        {
            [itemNames addObject:itemModel.icon.absoluteString];
        }
        else if (itemModel.name.length)
        {
            [itemNames addObject:itemModel.name];
        }
    }
    [self setRightBarButtonItemWithTexts:itemNames];
    
    //设置导航栏中间TitleView
    if (self.configModel.tabs.count)
    {
        [self setTitleItemWithTexts:self.configModel.tabs];
    }
    else if (self.configModel.icon.absoluteString.length && self.configModel.title.length)
    {
        MBWebNavigationTitleView *titleView = [[MBWebNavigationTitleView alloc] init];
        self.navigationItem.titleView = titleView;
        
        [titleView.imageView sd_setImageWithURL:self.configModel.icon];
        titleView.text.text = self.configModel.title;
    }
    else if (self.configModel.title.length)
    {
        self.navigationItem.titleView = nil;
        self.title = self.configModel.title;
    }
    else
    {
        NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.title = title;
    }
    
    //设置title透明
    if (self.scrollTransparentEnable)
    {
        [self setNavigationBarBackgroundAlpha:0];
    }
    else
    {
        [self setNavigationBarBackgroundAlpha:1];
    }
}

#pragma mark - 选择图片

- (PMKPromise *)presentAlbumViewControllerWithCount:(NSUInteger)count sourceType:(NSString *)sourceType
{
    __block NSUInteger maximumItemCount = count;
    
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        
        BOOL singleSelected = NO; //是否为单选
        
        if (maximumItemCount == 1)
        {
            singleSelected = YES;
        }
        
        //0 为不限制数量
        if (maximumItemCount == 0)
        {
            maximumItemCount = 30;
        }
        
        //清除历史选择记录
        [self.manager clearSelectedList];
        
        //是否为单选模式 默认 NO
        self.manager.configuration.singleSelected = singleSelected;
        
        //图片最大选择数 默认9 - 必填
        self.manager.configuration.photoMaxNum = maximumItemCount;
        
        //是否打开相机功能
        self.manager.configuration.openCamera = !sourceType.length;
        
        self.manager.type = HXPhotoManagerSelectedTypePhoto;
        
        //小图照片清晰度
        self.manager.configuration.clarityScale = 1.4;
        //主题颜色
        self.manager.configuration.themeColor = self.view.tintColor;
        self.manager.configuration.cellSelectedTitleColor = nil;
        
        //导航栏背景颜色
        self.manager.configuration.navBarBackgroudColor = nil;
        self.manager.configuration.statusBarStyle = UIStatusBarStyleDefault;
        self.manager.configuration.sectionHeaderTranslucent = YES;
        self.manager.configuration.cellSelectedBgColor = nil;
        self.manager.configuration.selectedTitleColor = nil;
        self.manager.configuration.sectionHeaderSuspensionBgColor = nil;
        self.manager.configuration.sectionHeaderSuspensionTitleColor = nil;
        
        //导航栏标题颜色
        self.manager.configuration.navigationTitleColor = nil;
        
        //是否过滤iCloud上的资源
        self.manager.configuration.filtrationICloudAsset = NO;
        //下载iCloud上的资源  默认YES
        self.manager.configuration.downloadICloudAsset = YES;
        //是否隐藏原图按钮  默认 NO
        self.manager.configuration.hideOriginalBtn = YES;
        //拍摄的 照片/视频 是否保存到系统相册  默认NO
        self.manager.configuration.saveSystemAblum = YES;
        self.manager.configuration.showDateSectionHeader = YES;
        //照片列表按日期倒序
        self.manager.configuration.reverseDate = YES;
        //导航栏标题颜色是否与主题色同步
        self.manager.configuration.navigationTitleSynchColor = YES;
        self.manager.configuration.replaceCameraViewController = NO;
        
        __weak __typeof(self)weakSelf = self;
        
        [self hx_presentAlbumListViewControllerWithManager:self.manager done:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, NSArray<UIImage *> *imageList, BOOL original, HXAlbumListViewController *viewController) {
            
            //上传到七牛
            [QMUITips showLoading:@"图片上传中" inView:self.view];
            [UploadImageTool uploadImages:imageList
                                     safe:NO
                                 progress:nil
                                  success:^(NSArray *urlArr) {
                                      [QMUITips hideAllTipsInView:weakSelf.view];
                                      resolve(urlArr);
                                  }
                                  failure:^{
                                      [QMUITips hideAllTipsInView:weakSelf.view];
                                      NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:200 userInfo:@{NSLocalizedDescriptionKey:@"图片上传失败"}];
                                      resolve(error);
                                  }];
            
        } cancel:^(HXAlbumListViewController *viewController) {
            [QMUITips hideAllTipsInView:weakSelf.view];
            NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:200 userInfo:@{NSLocalizedDescriptionKey:@"用户取消了照片选择"}];
            resolve(error);
        }];
        
    }];
}

//- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllImage:(NSArray<UIImage *> *)imageList {
//    NSSLog(@"imageList:%@",imageList);
//}
//- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
//    NSSLog(@"all - %@",allList);
//    NSSLog(@"photo - %@",photoList);
//    NSSLog(@"video - %@",videoList);
//}

- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        _manager.configuration.deleteTemporaryPhoto = NO;
        _manager.configuration.lookLivePhoto = NO;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.navigationBar = ^(UINavigationBar *navigationBar) {
        };
        _manager.configuration.requestImageAfterFinishingSelection = YES;
        _manager.configuration.videoCanEdit = NO;
        //照片是否可以编辑   default YES
        _manager.configuration.photoCanEdit = NO;
    }
    return _manager;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    HXPhotoModel *model;
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        model = [HXPhotoModel photoModelWithImage:image];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:model.thumbPhoto];
        }
    }else  if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL];
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
        float second = 0;
        second = urlAsset.duration.value/urlAsset.duration.timescale;
        model = [HXPhotoModel photoModelWithVideoURL:url videoTime:second];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools saveVideoToCustomAlbumWithName:self.manager.configuration.customAlbumName videoURL:url];
        }
    }
    if (self.manager.configuration.useCameraComplete) {
        self.manager.configuration.useCameraComplete(model);
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 加载进度delegate

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [self.progressView setProgress:progress animated:YES];
    
    //开始加载
    if(progress >= NJKInitialProgressValue)
    {
        [self hideEmptyView];
    }
    
    //框架加载完成, 资源还在加载
    if (progress >= NJKInteractiveProgressValue)
    {
        [self webViewComplete:self.webView];
    }
    
    //加载结束
    if(progress >= NJKFinalProgressValue)
    {
        
    }
}

#pragma mark - scrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //滚动导航栏透明
    if (self.scrollTransparentEnable)
    {
        CGFloat offsetY = scrollView.contentOffset.y;
        
        CGFloat bannerHeight = self.scrollTransparentHeight;
        
        CGFloat alpha = 0;
        
        if (offsetY <= 0)
        {
            alpha = 0;
        }
        else if (offsetY >= bannerHeight)
        {
            alpha = 1;
        }
        else
        {
            alpha = 1 - (bannerHeight - offsetY) / bannerHeight;
        }
        
        [self setNavigationBarBackgroundAlpha:alpha];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.jscontext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jscontext[@"sonic"] = self.sonicContext;
    
    //默认jsconfig
    self.configModel = nil;
    [self jsConfig];
    
    NSString *url = request.URL.absoluteString;
    if ([url hasPrefix:@"meb://"]) {
        //跳转到本地
        [NavigatorModule URLString:url].then(nil);
        
        return NO;
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && navigationType == UIWebViewNavigationTypeLinkClicked) {
        MBWebViewController *vc = [[MBWebViewController alloc] initWithURL:request.URL];
        [self.navigationController pushViewController:vc animated:YES];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.jscontext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jscontext[@"sonic"] = self.sonicContext;
    
    [self hideEmptyView];
    
    //获取 404, 500等错误码
    //    NSURLSessionDataTask * dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:webView.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    //        NSHTTPURLResponse *tmpresponse = (NSHTTPURLResponse*)response;
    //
    //        if (tmpresponse.statusCode != 200) {
    //            [self webView:webView errorWithErrorCode:tmpresponse.statusCode];
    //        }
    //    }];
    //    [dataTask resume];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self webViewComplete:webView];
    
    [self webView:webView errorWithErrorCode:error.code];
}

- (void)webView:(UIWebView *)webView errorWithErrorCode:(NSInteger)code
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showLoadingErrorEmptyWithCode:code];
    });
    
    //跳转到登录, 返回时刷新webView
    if (code == 401) {
        [NavigatorModule URLString:@"meb://signin" query:nil openType:NavigatorModuleOpenTypePresent].then(nil);
    }
}

- (void)webViewComplete:(UIWebView *)webView
{
    //停止下拉刷新
    if (self.webView.scrollView.mj_header) {
        [self.webView.scrollView.mj_header endRefreshing];
    }
    
    //设置导航栏左侧按钮
    [self setLeftItemsBackAndHome];
    
    //默认jsConfig, 等待0.5s 后没有title配置使用默认配置
    [PMKPromise pause:0.5].then(^{
        
        if (!self.configModel) {
            [self jsConfig];
            
            NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
            self.navigationItem.titleView = nil;
            self.title = title;
        }
    });
}

#pragma mark - Sonic Session Delegate
/*
 * Call back when Sonic will send request.
 */
- (void)sessionWillRequest:(SonicSession *)session
{
    //This callback can be used to set some information, such as cookie and UA.
}
/*
 * Call back when Sonic require WebView to reload, e.g template changed or error occurred.
 */
- (void)session:(SonicSession *)session requireWebViewReload:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

#pragma mark - UINavigationControllerBackButtonHandlerProtocol

- (BOOL)shouldHoldBackButtonEvent
{
    return NO;
}

- (BOOL)canPopViewController
{
    // 这里不要做一些费时的操作，否则可能会卡顿。
    if ([self.webView canGoBack])
    {
        [self.webView goBack];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)forceEnableInteractivePopGestureRecognizer
{
    return YES;
}

#pragma mark - helper

// 导出网络图片
- (void)cacheUrlIconWithConfig:(NSDictionary *)config completed:(void(^)(void))completed
{
    NSMutableArray <NSURL *> *urls = [NSMutableArray array];
    [urls removeAllObjects];
    
    [self foundIconUrlWithDictionary:config iconArray:urls];
    
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:urls progress:nil completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
        if (completed) {
            completed();
        }
    }];
}

- (void)foundIconUrlWithDictionary:(NSDictionary *)dic iconArray:(NSMutableArray *)iconArray
{
    for (id key in dic.allKeys)
    {
        id value = dic[key];
        
        if ([value isKindOfClass:NSString.class])
        {
            if ([key isEqualToString:@"icon"] && value && [value length])
            {
                [iconArray addObject:[NSURL URLWithString:value]];
            }
        }
        else if ([value isKindOfClass:NSDictionary.class])
        {
            [self foundIconUrlWithDictionary:value iconArray:iconArray];
        }
        else if ([value isKindOfClass:NSArray.class])
        {
            [self foundIconUrlWithArray:value iconArray:iconArray];
        }
    }
}

- (void)foundIconUrlWithArray:(NSArray *)array iconArray:(NSMutableArray *)iconArray
{
    for (id item in array)
    {
        id value = item;
        
        if ([value isKindOfClass:NSDictionary.class])
        {
            [self foundIconUrlWithDictionary:value iconArray:iconArray];
        }
        else if ([value isKindOfClass:NSArray.class])
        {
            [self foundIconUrlWithArray:value iconArray:iconArray];
        }
    }
}

- (UIImage *)iconImageWithUrl:(NSURL *)imageURL
{
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:imageURL];
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:key];
    return image;
}

/**
 设置cookie
 
 @param url HTTPCookieOriginURL
 */
//- (void)setupCookieWithUrl:(NSString *)url
//{
//    NSMutableDictionary *cookiePropertiesUser = [NSMutableDictionary dictionary];
//    [cookiePropertiesUser setObject:@"token" forKey:NSHTTPCookieName];
//    [cookiePropertiesUser setObject:@"123-456-789" forKey:NSHTTPCookieValue];
//    [cookiePropertiesUser setObject:url forKey:NSHTTPCookieOriginURL];
//    [cookiePropertiesUser setObject:@"/" forKey:NSHTTPCookiePath];
//    [cookiePropertiesUser setObject:@"0" forKey:NSHTTPCookieVersion];
//
//    [cookiePropertiesUser setObject:[NSDate dateWithTimeIntervalSinceNow:3600*24*30*12] forKey:NSHTTPCookieExpires];
//
//    NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookiePropertiesUser];
//    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookieuser];
//}
//
///**
// 清除cookie
// */
//- (void)deleteCookie
//{
//    NSHTTPCookie *cookie;
//
//    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//
//    NSArray *cookieAry = [cookieJar cookiesForURL:self.url];
//
//    for (cookie in cookieAry) {
//
//        [cookieJar deleteCookie:cookie];
//    }
//}

/**
 设置 UserAgent
 */
- (void)setupUserAgent
{
    [[SonicEngine sharedEngine] setGlobalUserAgent:[NSString stringWithFormat:@"%@ Meb/1.0.0", SonicDefaultUserAgent]];
}

#pragma mark - init

- (NJKWebViewProgress *)progressProxy
{
    if (!_progressProxy) {
        _progressProxy = [[NJKWebViewProgress alloc] init]; // instance variable
        _progressProxy.webViewProxyDelegate = self;
        _progressProxy.progressDelegate = self;
    }
    return _progressProxy;
}

- (NJKWebViewProgressView *)progressView
{
    if (!_progressView)
    {
        CGFloat progressBarHeight = 2.f;
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, progressBarHeight);
        
        _progressView = [[NJKWebViewProgressView alloc] initWithFrame:frame];
        _progressView.progress = 0;
    }
    return _progressView;
}

- (WebViewJavascriptBridge *)bridge
{
    if (!_bridge) {
        _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
        [_bridge setWebViewDelegate:self.progressProxy];
    }
    
    return _bridge;
}

- (SonicJSContext *)sonicContext
{
    if (!_sonicContext) {
        _sonicContext = [[SonicJSContext alloc]init];
    }
    return _sonicContext;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    //todo: dealloc 不会被调用, 不知道为什么
    self.webView.delegate = nil;
    [self.webView stopLoading];
    self.sonicContext.owner = nil;
    self.sonicContext = nil;
    self.jscontext = nil;
}

- (void)willPopInNavigationControllerWithAnimated:(BOOL)animated
{
    self.bridge = nil;
    [[SonicEngine sharedEngine] removeSessionWithWebDelegate:self];
}

- (void)navigationController:(nonnull QMUINavigationController *)navigationController poppingByInteractiveGestureRecognizer:(nullable UIScreenEdgePanGestureRecognizer *)gestureRecognizer viewControllerWillDisappear:(nullable UIViewController *)viewControllerWillDisappear viewControllerWillAppear:(nullable UIViewController *)viewControllerWillAppear
{
    UIGestureRecognizerState state = gestureRecognizer.state;
    
    if (state == UIGestureRecognizerStateEnded)
    {
        //左滑返回, 取消了手势
        if (CGRectGetMinX(navigationController.topViewController.view.superview.frame) < 0)
        {
            //恢复 bridge
            [self bridgeRegisterHandler];
            //恢复 Session
            [self setupSession];
        }
    }
}

@end

