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
