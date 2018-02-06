package weibo.zgbgx.com.weibo;

import android.net.http.SslError;
import android.os.Build;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Base64;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.SslErrorHandler;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import org.apache.commons.lang.StringEscapeUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";
    private WebView webView;
    private static final String LOGINPAGEURL = "https://passport.weibo.cn/signin/login";//登录页面
    private static final String INDEXPAGEURL = "https://m.weibo.cn/";//登录成功后跳到的首页
    private static final String GETSECONDURL = "https://m.weibo.cn/api/container/getSecond?";//粉丝，关注查询接口
    private static final String SENCODWEIBO = "https://m.weibo.cn/api/container/getIndex?";//个人微博查询接口
    private static final String GETLINKURL = "https://m.weibo.cn/home/me?format=cards";//获取关键个人参数接口
    private static final String PERSONINFOURL = "https://m.weibo.cn/users/";//个人信息页
    private static final String AUTOFOCUSURL = "https://m.weibo.cn/u/1195242865";//自动关注的一个weibo账号
    private String containerString;//粉丝页与关注页的标志字符串
    private String weiboString;//个人微博页，字符串
    private String userId;//用户id
    private JSONObject unpwDict;//存储账号密码的json对象
    private int pageIndex = 1;//用于获取多页数据的标志
    private int maxPage;//页数
    private JSONArray followersArray = new JSONArray();//关注JSON数组
    private JSONArray fansArray = new JSONArray();//粉丝JSOn数组
    private JSONArray weiboArray = new JSONArray();//个人发的微博数组
    private JSONObject weiboJson = new JSONObject();//微博个人信息数组
    private int newIndex = 0;//用于辅助判断页面是否加载完全的标志位

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        startWebView();
    }

    //初始化WebView设置
    private void startWebView() {
        webView = (WebView) findViewById(R.id.weibo_view);
        final WebSettings settings = webView.getSettings();
        settings.setUseWideViewPort(true);
        settings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.NARROW_COLUMNS);
        settings.setLoadWithOverviewMode(true);
        settings.setJavaScriptEnabled(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        }
        settings.setJavaScriptEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setSupportZoom(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccessFromFileURLs(true);
        settings.setCacheMode(WebSettings.LOAD_NO_CACHE);
        settings.setAllowFileAccess(true);
        settings.setUseWideViewPort(true);
        settings.setSupportMultipleWindows(true);
        settings.setLoadsImagesAutomatically(true);
        settings.setBlockNetworkImage(false);
        //提供js调用android 的接口
        webView.addJavascriptInterface(new WeiboJsInterface(), "weibo");
        webView.setVerticalScrollBarEnabled(true);
        webView.setHorizontalScrollBarEnabled(true);
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {

            }
        });
        startWebViewClient(webView);
        webView.loadUrl(LOGINPAGEURL);
        webView.setScrollContainer(true);
    }

    /**
     * @param view WebView对象
     *             初始化webviewClient
     */
    private void startWebViewClient(WebView view) {
        view.setWebViewClient(new WebViewClient() {
            @Override
            public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                handler.proceed();
            }

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


            /**
             * @param view
             * @param url
             */
            @Override
            public void onPageFinished(WebView view, String url) {
                if (url.equals(LOGINPAGEURL)) {
                    injectJsUseXpath("login.js");
                    execJsNoReturn("getLogin();");
                }
                if (url.equals(INDEXPAGEURL)) {
                    webView.loadUrl(GETLINKURL);
                }
                if (url.equals(GETLINKURL)) {
                    getLink();
                }
                //提取关注
                if (url.contains(GETSECONDURL) && url.contains("FOLLOWERS")) {
                    getArray("FOLLOWERS");
                }
                //提取粉丝
                if (url.contains(GETSECONDURL) && url.contains("FANS")) {
                    getArray("FANS");
                }
                //提取微博
                if (url.contains(SENCODWEIBO)) {
                    getArray("weibo");
                }
                //提取个人信息
                if (url.contains(PERSONINFOURL) && url.contains("set=1")) {
                    injectJsUseXpath("personInfo.js");
                    handleJson("getPersonInfo();");
                    webView.loadUrl(AUTOFOCUSURL);
                }
                //自动关注账号
                if (url.contains(AUTOFOCUSURL)) {
                    injectJsUseXpath("autoFocus.js");
                    execJsNoReturn("autoFocus();");
                }

            }
        });
    }

    //处理json数组的返回值
    private void getArray(final String flag) {
        String funcStr = "JSON.stringify(JSON.parse(document.getElementsByTagName('pre')[0].innerText))";//转码处理
        webView.evaluateJavascript(funcStr, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String s) {
                try {
                    JSONObject returnJSON = new JSONObject(handleJsonString(s));
                    JSONObject data = returnJSON.getJSONObject("data");
                    if (pageIndex == 1) {
                        if (flag.equals("weibo")) {
                            maxPage = data.getJSONObject("cardlistInfo").getInt("total") / 10;
                        } else {
                            maxPage = data.getInt("maxPage");
                        }
                        if (maxPage == 1) {
                            getArray(data, true, flag);
                        } else {
                            getArray(data, false, flag);
                        }

                    } else if (pageIndex < maxPage) {
                        getArray(data, false, flag);
                    } else {
                        getArray(data, true, flag);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

        });
    }

    //通过接口获取查询 微博 关注和粉丝的关键字段
    private void getLink() {
        String funcStr = "JSON.stringify(JSON.parse(document.getElementsByTagName('pre')[0].innerText))";
        webView.evaluateJavascript(funcStr, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String s) {
                try {
                    JSONArray returnArray = new JSONArray(handleJsonString(s));

                    if (returnArray != null && returnArray.length() != 0) {
                        JSONObject urlJSON = returnArray.getJSONObject(0);
                        if (urlJSON != null) {
                            JSONArray cards = urlJSON.getJSONArray("card_group");
                            userId = cards.getJSONObject(0).getJSONObject("user").getString("id");
                            if (cards != null && cards.length() > 1) {
                                JSONArray apps = cards.getJSONObject(1).getJSONArray("apps");
                                if (apps != null && apps.length() == 3) {
                                    for (int i = 0; i < apps.length(); i++) {
                                        if (i == 0) {
                                            weiboString = apps.getJSONObject(i).getString("scheme").split("[?]")[1].split("_")[0];
                                        }
                                        if (i == 1) {
                                            containerString = apps.getJSONObject(i).getString("scheme").split("[?]")[1].split("_")[0];
                                        }
                                    }
                                }
                            }
                            String theUrl = GETSECONDURL + containerString + "_-_" + "FOLLOWERS&page=" + 1;
                            webView.loadUrl(theUrl);
                        }
                    }

                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
    }

    private void getArray(JSONObject data, boolean end, String flag) {
        try {
            JSONArray userArray = new JSONArray();
            try {
                userArray = data.getJSONArray("cards");
            } catch (Exception e) {
                Log.e(TAG, "getArray: " + e);
            }
            for (int i = 0; i < userArray.length(); i++) {
                if ("FOLLOWERS".equals(flag)) {
                    followersArray.put(userArray.getJSONObject(i).getJSONObject("user"));
                }
                if ("FANS".equals(flag)) {
                    fansArray.put(userArray.getJSONObject(i).getJSONObject("user"));
                }
                if ("weibo".equals(flag)) {
                    try {
                        weiboArray.put(userArray.getJSONObject(i).getJSONObject("mblog"));
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }

            }
            if ("FOLLOWERS".equals(flag)) {
                if (end) {
                    pageIndex = 1;
                    String theUrl = GETSECONDURL + containerString + "_-_" + "FANS&page=" + pageIndex;
                    webView.loadUrl(theUrl);
                } else {
                    pageIndex++;
                    String theUrl = GETSECONDURL + containerString + "_-_" + "FOLLOWERS&page=" + pageIndex;
                    webView.loadUrl(theUrl);
                }
            }
            if ("FANS".equals(flag)) {
                if (end) {
                    pageIndex = 1;
                    String theUrl = SENCODWEIBO + weiboString + "_-_" + "WEIBO_SECOND_PROFILE_WEIBO&page_type=03&page=" + pageIndex;
                    webView.loadUrl(theUrl);
                } else {
                    pageIndex++;
                    String theUrl = GETSECONDURL + containerString + "_-_" + "FANS&page=" + pageIndex;
                    webView.loadUrl(theUrl);
                }
            }
            if ("weibo".equals(flag)) {
                if (end) {
                    pageIndex = 1;
                    String theUrl = PERSONINFOURL + userId + "?set=1";
                    webView.loadUrl(theUrl);
                } else {
                    pageIndex++;
                    String theUrl = SENCODWEIBO + weiboString + "_-_" + "WEIBO_SECOND_PROFILE_WEIBO&page_type=03&page=" + pageIndex;
                    webView.loadUrl(theUrl);
                }
            }

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    //执行没有返回值的js
    private void execJsNoReturn(String funcStr) {
        webView.evaluateJavascript(funcStr, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String s) {

            }

        });
    }

    //处理json返回，提取key value  放入一个总的字典ß
    private void handleJson(String funcStr) {
        webView.evaluateJavascript(funcStr, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String s) {
                try {
                    JSONObject returnJson = new JSONObject(handleJsonString(s));
                    Iterator<String> jsonIteator = returnJson.keys();
                    while (jsonIteator.hasNext()) {
                        String key = jsonIteator.next();
                        String value = returnJson.getString(key);
                        weiboJson.put(key, value);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
    }

    //处理带转义字符的json字符串
    private String handleJsonString(String returnStr) {
        returnStr = StringEscapeUtils.unescapeJava(returnStr);
        returnStr = returnStr.substring(1, returnStr.length() - 1);
        return returnStr;
    }

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

    //浏览器与webview接口，用于获取账户密码
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

    private void injectJsUseXpath(String filePath) {
        injectScriptFile("nodeSelect.js");
        injectScriptFile(filePath);
    }

}