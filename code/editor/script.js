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
  }
  editor.gotoLine(1);
}







