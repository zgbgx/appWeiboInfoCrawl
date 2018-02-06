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
