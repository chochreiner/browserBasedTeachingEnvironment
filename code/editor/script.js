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

function submitScript() {
  if (Math.round(Math.random())) {
    document.getElementById("result").innerHTML="result"
  } else {
    errorMessage= " Commands:\n"
    + "invalid command name \"fore\"\n"
    + "while executing\n"
    + "fore ach {i} [info functions] {\n"
    + "  if {![info exists availablecommands]} {\n"
    + "    set availablecommands $i\n"
    + "  } else {\n"
    + "     set availablecommands \"$availabl...\"\n"
    + " (file \"generator.tcl\" line 13)";
    var line = errorMessage.match(/line (.*)\)$/);
    editor.gotoLine(line[1]);
    document.getElementById("result").innerHTML=errorMessage;    
  }
}

