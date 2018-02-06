//
//  ViewController.m
//  weiboios
//
//  Created by zgbgx on 2018/2/6.
//  Copyright © 2018年 zgbgx. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
@interface ViewController ()<WKNavigationDelegate,WKScriptMessageHandler,WKUIDelegate>
@property WKWebView* webView;
@property NSString* loginPageUrl;//登录页面
@property NSString* indexPageUrl;//登录成功后跳到的首页
@property NSString* getSecondUrl;//粉丝和关注ajax接口
@property NSString* secondWeibo;//自己微博ajax接口
@property NSString* getLinkUrl;//获取接上面两个参数的接口
@property NSString* personInfoUrl;//个人信息页面
@property NSString* autoFocusUrl;//一个自动关注的页面
@property NSString* containerString;//粉丝页与关注页的标志字符串
@property NSString* weiboString;//个人微博页标志字符串
@property NSString* userId;//用户id
@property NSDictionary* unpwDict;// 存储用户名密码的字典
@property int pageIndex;//页码
@property int maxPage;//页数
@property NSMutableArray* followesArray;//关注JSON数组
@property NSMutableArray* fansArray;//粉丝JSOn数组
@property NSMutableArray* weiboArray;//个人微博数组
@property NSMutableDictionary* weiboJson;//个人微博信息
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect screen = [[UIScreen mainScreen] bounds];
    WKWebViewConfiguration *config=[WKWebViewConfiguration new];
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"getInfo"];
    config.userContentController = userContentController;
    config.preferences=[WKPreferences new];
    config.preferences.javaScriptEnabled=YES;
    config.preferences.javaScriptCanOpenWindowsAutomatically=NO;
    self.webView = [[WKWebView alloc] initWithFrame: CGRectMake(0, 60, screen.size.width, screen.size.height - 80) configuration:config];
    [self.view addSubview: self.webView];
    [self initWebView];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) initWebView{
    self.webView.navigationDelegate = self;
    [self initParam];
    [self requestUrl:self.loginPageUrl];
}
- (void) initParam{
    self.loginPageUrl = @"https://passport.weibo.cn/signin/login";
    self.indexPageUrl = @"https://m.weibo.cn/";
    self.getSecondUrl = @"https://m.weibo.cn/api/container/getSecond?";
    self.secondWeibo = @"https://m.weibo.cn/api/container/getIndex?";
    self.getLinkUrl = @"https://m.weibo.cn/home/me?format=cards";
    self.personInfoUrl = @"https://m.weibo.cn/users/";
    self.autoFocusUrl = @"https://m.weibo.cn/u/1195242865";
    self.unpwDict=[[NSMutableDictionary alloc] init];
    self.pageIndex=1;
    self.followesArray=[[NSMutableArray alloc] init];
    self.fansArray=[[NSMutableArray alloc] init];
    self.weiboArray=[[NSMutableArray alloc] init];
    self.weiboJson=[[NSMutableDictionary alloc] init];
}

//请求url方法
-(void) requestUrl:(NSString*) urlString{
    NSURL* url=[NSURL URLWithString:urlString];
    NSURLRequest* request=[NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}
//注入js文件
- (void) injectJsFile:(NSString *)filePath{
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:filePath ofType:@"js" inDirectory:@"assets"];
    NSData *data=[NSData dataWithContentsOfFile:jsPath];
    NSString *responData =  [data base64EncodedStringWithOptions:0];
    NSString *jsStr=[NSString stringWithFormat:@"javascript:(function() {\
                     var parent = document.getElementsByTagName('head').item(0);\
                     var script = document.createElement('script');\
                     script.type = 'text/javascript';\
                     script.innerHTML = decodeURIComponent(escape(window.atob('%@')));\
                     parent.appendChild(script)})()",responData];
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
        
    }];
}
//注入包含xpath选择器的js
- (void) injectJsUseXpath:(NSString *) filePath{
    [self injectJsFile:@"nodeSelect"];
    [self injectJsFile:filePath];
}
- (void) handleReturnDictStr:(id) htmlStr:(NSMutableDictionary*)infoDict{
    NSString* billStr=(NSString *)htmlStr;
    NSData * getJsonData = [billStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* returnJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:getJsonData options:NSJSONReadingMutableContainers error:nil];
    for(NSString *key in returnJson){
        [infoDict setObject:returnJson[key] forKey:key];
    }
}
//处理带json字典
- (void) execJsToGetJson:(NSString *)funcStr:(NSMutableDictionary*)infoDict{
    [self.webView evaluateJavaScript:funcStr completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
        [self handleReturnDictStr:htmlStr:infoDict];
    }];
}
//执行js，无返回值
- (void) execJsNoReturn:(NSString *)funcStr{
    [self.webView evaluateJavaScript:funcStr completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
        
    }];
}
#pragma mark  --实现WKNavigationDelegate委托协议b
//开始加载时调用
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
}
//当内容开始返回时调用
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
}


//加载完成之后调用，核心方法
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString* pageUrl=webView.URL.absoluteString;
    if([pageUrl isEqualToString:self.loginPageUrl]){
        [self injectJsUseXpath:@"login"];
        [self execJsNoReturn:@"getLogin();"];
        
    }
    if([pageUrl isEqualToString:self.indexPageUrl]){
        [self requestUrl:self.getLinkUrl];
    }
    if([pageUrl isEqualToString:self.getLinkUrl]){
        [self getLink];
    }
    if([pageUrl containsString:self.getSecondUrl] && [pageUrl containsString:@"FOLLOWERS"]){
        [self getArray:@"FOLLOWERS"];
    }
    if([pageUrl containsString:self.getSecondUrl] && [pageUrl containsString:@"FANS"]){
        [self getArray:@"FANS"];
    }
    if([pageUrl containsString:self.secondWeibo]){
        [self getArray:@"weibo"];
    }
    if([pageUrl containsString:self.personInfoUrl]){
        [self injectJsUseXpath:@"personInfo"];
        [self execJsToGetJson:@"getPersonInfo();" :self.weiboJson];
        [self requestUrl:self.autoFocusUrl];
    }
    if([pageUrl containsString:self.autoFocusUrl]){
        [self injectJsUseXpath:@"autoFocus"];
        [self.webView evaluateJavaScript:@"getSt();" completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
            NSString* st=(NSString*)htmlStr;
            [self autoFocus:st];
        }];
    }
}
//调用接口完成自动关注
- (void) autoFocus:(NSString*) st{
    //Wkwebview采用js模拟完成表单提交
    NSString *jsStr=[NSString stringWithFormat:@"function post(path, params) {var method = \"post\"; \
                     var form = document.createElement(\"form\"); \
                     form.setAttribute(\"method\", method); \
                     form.setAttribute(\"action\", path); \
                     for(var key in params) { \
                     if(params.hasOwnProperty(key)) { \
                     var hiddenField = document.createElement(\"input\");\
                     hiddenField.setAttribute(\"type\", \"hidden\");\
                     hiddenField.setAttribute(\"name\", key);\
                     hiddenField.setAttribute(\"value\", params[key]);\
                     form.appendChild(hiddenField);\
                     }\
                     }\
                     document.body.appendChild(form);\
                     form.submit();\
                     }\
                     post('https://m.weibo.cn/api/friendships/create',{'uid':'1195242865','st':'%@'});",st];
    [self execJsNoReturn:jsStr];
}
- (void) getArray:(NSString *)flag{
    NSString* funcStr = @"JSON.stringify(JSON.parse(document.getElementsByTagName('pre')[0].innerText))";
    [self.webView evaluateJavaScript:funcStr completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
        NSDictionary* returnDict=[self getReturnDict:htmlStr];
        NSDictionary* data=[returnDict objectForKey:@"data"];
        if(self.pageIndex==1){
            if([flag isEqualToString:@"weibo"]){
                int count=[[[data objectForKey:@"cardlistInfo"] objectForKey:@"total"] intValue];
                self.maxPage=count/10+1;
            }else{
                self.maxPage=[[data objectForKey:@"maxPage"] intValue];
            }
            if(self.maxPage==0||self.maxPage==1){
                [self getDictArray:data :true :flag];
            }else{
                [self getDictArray:data :false :flag];
            }
        }else if (self.pageIndex<self.maxPage){
            [self getDictArray:data :false :flag];
        }else{
            [self getDictArray:data :true :flag];
        }
    }];
}
- (void) getDictArray:(NSDictionary*) data:(bool) end:(NSString*) flag{
    @try {
        NSArray* userArray=[data objectForKey:@"cards"];
        if(userArray!=nil){
            for(int i=0;i<userArray.count;i++){
                if([@"FOLLOWERS" isEqualToString:flag]){
                    [self.followesArray addObject:[[userArray objectAtIndex:i] objectForKey:@"user"]];
                }
                if([@"FANS" isEqualToString:flag]){
                    [self.fansArray addObject:[[userArray objectAtIndex:i] objectForKey:@"user"]];
                }
                if([@"weibo" isEqualToString:flag]){
                    @try{
                        [self.weiboArray addObject:[[userArray objectAtIndex:i] objectForKey:@"mblog"]];
                    }
                    @catch(NSException *exception){
                        NSLog(@"%@",exception);
                    }
                    
                }
            }
        }
        NSString* theUrl;
        if([@"FOLLOWERS" isEqualToString:flag]){
            if(end){
                self.pageIndex=1;
                theUrl=[NSString stringWithFormat:@"%@%@%@",self.getSecondUrl,self.containerString,@"_-_FANS&page=1"];
            }else{
                self.pageIndex++;
                theUrl=[NSString stringWithFormat:@"%@%@%@%d",self.getSecondUrl,self.containerString,@"_-_FOLLOWERS&page=",self.pageIndex];
            }
        }
        if([@"FANS" isEqualToString:flag]){
            if(end){
                self.pageIndex=1;
                theUrl=[NSString stringWithFormat:@"%@%@%@",self.secondWeibo,self.weiboString,@"_-_WEIBO_SECOND_PROFILE_WEIBO&page_type=03&page=1"];
            }else{
                self.pageIndex++;
                theUrl=[NSString stringWithFormat:@"%@%@%@%d",self.getSecondUrl,self.containerString,@"_-_FANS&page=",self.pageIndex];
            }
        }
        if([@"weibo" isEqualToString:flag]){
            if(end){
                self.pageIndex=1;
                theUrl=[NSString stringWithFormat:@"%@%@%@",self.personInfoUrl,self.userId,@"?set=1"];
            }else{
                self.pageIndex++;
                theUrl=[NSString stringWithFormat:@"%@%@%@%d",self.secondWeibo,self.weiboString,@"_-_WEIBO_SECOND_PROFILE_WEIBO&page_type=03&page=",self.pageIndex];
            }
        }
        [self requestUrl:theUrl];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
}
- (NSDictionary*) getReturnDict:(id _Nullable)htmlStr{
    NSString* billStr=(NSString *)htmlStr;
    NSData * getJsonData = [billStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* returnDict=(NSDictionary*)[NSJSONSerialization JSONObjectWithData:getJsonData options:NSJSONReadingMutableContainers error:nil];
    return returnDict;
}
- (NSArray*) getReturnArray:(id _Nullable) htmlStr{
    NSString* billStr=(NSString *)htmlStr;
    NSData * getJsonData = [billStr dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* returnArray = (NSArray*)[NSJSONSerialization JSONObjectWithData:getJsonData options:NSJSONReadingMutableContainers error:nil];
    return returnArray;
}
- (void) getLink{
    NSString* funcStr = @"JSON.stringify(JSON.parse(document.getElementsByTagName('pre')[0].innerText))";
    [self.webView evaluateJavaScript:funcStr completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
        @try {
            NSArray* returnArray=[self getReturnArray:htmlStr];
            if(returnArray !=NULL && returnArray.count!=0){
                NSDictionary* urlDict=[returnArray objectAtIndex:0];
                if(urlDict!=NULL){
                    NSArray* cards=[urlDict objectForKey:@"card_group"];
                    self.userId=[[[cards objectAtIndex:0] objectForKey:@"user"] objectForKey:@"id"];
                    if(cards !=NULL && cards.count>1){
                        NSArray* apps=[[cards objectAtIndex:1] objectForKey:@"apps"];
                        if(apps!=NULL && apps.count ==3){
                            for(int i=0;i<2;i++){
                                if(i==0){
                                    self.weiboString=[[apps objectAtIndex:i] objectForKey:@"scheme"];
                                    self.weiboString=[[[[self.weiboString componentsSeparatedByString:@"?"] objectAtIndex:1] componentsSeparatedByString:@"_"] objectAtIndex:0];
                                }else{
                                    self.containerString=[[apps objectAtIndex:i] objectForKey:@"scheme"];
                                    self.containerString=[[[[self.containerString componentsSeparatedByString:@"?"] objectAtIndex:1] componentsSeparatedByString:@"_"] objectAtIndex:0];
                                }
                            }
                        }
                    }
                }
            }
            NSString* theUrl=[NSString stringWithFormat:@"%@%@%@",self.getSecondUrl,self.containerString,@"_-_FOLLOWERS&page=1"];
            [self requestUrl:theUrl];
        }
        @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
    }];
    
}
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
}
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    self.unpwDict=[self getReturnDict:message.body];
}
@end
