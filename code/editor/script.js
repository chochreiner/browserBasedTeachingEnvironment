function changeLanguage() {
  switch (document.getElementById("languageselector").value) {
    case "tcl" : editor.session.setMode("ace/mode/tcl"); break;
    case "xotcl" : editor.session.setMode("ace/mode/xotcl"); break;
    case "nx" : editor.session.setMode("ace/mode/nx"); break;
  }
}

function changeScript() {
  switch (document.getElementById("scriptselector").value) {
    case "none" : editor.setValue(""); break;
    case "xotcl" : editor.setValue(document.getElementById("xotcl").value); break;
    case "nx" : editor.setValue(document.getElementById("nx").value); break;
    case "intro" : editor.setValue(document.getElementById("intro").value); break;
  }
  editor.gotoLine(1);
}


function submitScript() {
  var xmlhttp;
  if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  } else {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && xmlhttp.status==200) {
      var result = xmlhttp.responseText;
      document.getElementById("result").innerHTML=result;
      var line = result.match(/on line: (.*)\$/);
      editor.gotoLine(line[1]);
    }
  }
  xmlhttp.open("GET","http:/localhost:8081/"+window.btoa(editor.getValue()),true);
  xmlhttp.send();
}