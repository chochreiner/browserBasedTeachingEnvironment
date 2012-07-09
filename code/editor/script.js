function changeLanguage() {
editor.session.setMode("ace/mode/" + document.getElementById("languageselector").value); 
}

function changeScript() {
editor.setValue(document.getElementById(document.getElementById("scriptselector").value).value);
  editor.gotoLine(1);
}

function submitToServer() {
  var xmlhttp;
  if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  } else {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && xmlhttp.status==200) {
      var result = xmlhttp.responseText;
      document.getElementById("result").style.visibility="visible";
      document.getElementById("result").innerHTML=result;
      var line = result.match(/on line: (.*)/);
      editor.gotoLine(line[1]);
    }
  }
  xmlhttp.open("GET","http:/localhost:8081/"+window.btoa(editor.getValue()),true);
  xmlhttp.send();
}