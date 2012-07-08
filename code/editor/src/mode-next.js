/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Ajax.org Code Editor (ACE).
 *
 * The Initial Developer of the Original Code is
 * Ajax.org B.V.
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *      Fabian Jakobs <fabian AT ajax DOT org>
 *      Shlomo Zalman Heigh <shlomozalmanheigh AT gmail DOT com>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

define('ace/mode/next', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/tokenizer', 'ace/mode/next_highlight_rules', 'ace/mode/matching_brace_outdent', 'ace/range', ], function(require, exports, module) {


var oop = require("../lib/oop");
var TclMode = require("./tcl").Mode;
var Tokenizer = require("../tokenizer").Tokenizer;
var NextHighlightRules = require("./next_highlight_rules").NextHighlightRules;
var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;
var Range = require("../range").Range;

var Mode = function() {
    this.$tokenizer = new Tokenizer(new NextHighlightRules().getRules());
    this.$outdent = new MatchingBraceOutdent();
};
oop.inherits(Mode, TclMode);


exports.Mode = Mode;
});

define('ace/mode/next_highlight_rules', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/lib/lang', 'ace/mode/text_highlight_rules'], function(require, exports, module) {


var oop = require("../lib/oop");
var lang = require("../lib/lang");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var NextHighlightRules = function() {

    var builtinFunctions = lang.arrayToMap(
        ("tell|socket|subst|open|eof|pwd|glob|list|pid|exec|auto_load_index|time|unknown|eval|lassign|lrange|fblocked|lsearch|auto_import|gets|case|lappend|proc|break|variable|llength|auto_execok|return|linsert|error|catch|clock|info|split|array|if|fconfigure|concat|join|lreplace|source|fcopy|global|switch|auto_qualify|update|close|cd|for|auto_load|file|append|lreverse|format|unload|read|package|set|binary|namespace|scan|apply|trace|seek|while|chan|flush|after|vwait|dict|continue|uplevel|foreach|lset|rename|fileevent|regexp|lrepeat|upvar|encoding|expr|unset|load|regsub|interp|exit|puts|incr|lindex|lsort|tclLog|string|round|wide|sqrt|sin|log10|double|hypot|atan|bool|rand|abs|acos|atan2|entier|srand|sinh|log|floor|tanh|tan|isqrt|int|asin|min|ceil|cos|cosh|exp|max|pow|fmod|getExitHandler|setExitHandler|CopyHandler|__exitHandler|unsetExitHandler|uses|method|allinstances|parameter|new|instmixin|alloc|instparametercmd|instforward|create|info|slots|superclass|instinvar|instmixinguard|parameterclass|instfilterguard|instdestroy|unknown|instproc|autoname|recreate|instfilter|subst|isclass|configure|check|eval|requireNamespace|isobject|proc|lappend|instvar|move|exists|volatile|__next|istype|array|cleanup|filterguard|filtersearch|filter|contains|append|noinit|self|hasclass|set|parametercmd|mixin|defaultmethod|trace|ismixin|ismetaclass|procsearch|destroy|vwait|uplevel|extractConfigureArg|copy|init|forward|upvar|unset|mixinguard|invar|incr|abstract|class|Parameter|__unknown|uses|method|allinstances|parameter|new|instmixin|alloc|instparametercmd|instforward|create|info|slots|superclass|instinvar|instmixinguard|parameterclass|instfilterguard|instdestroy|unknown|instproc|autoname|recreate|instfilter|subst|isclass|configure|check|eval|requireNamespace|isobject|proc|lappend|instvar|move|exists|volatile|__next|istype|array|cleanup|filterguard|filtersearch|filter|contains|append|noinit|self|hasclass|set|parametercmd|mixin|defaultmethod|trace|ismixin|ismetaclass|procsearch|destroy|vwait|uplevel|extractConfigureArg|copy|init|forward|upvar|unset|mixinguard|invar|incr|abstract|class").split("|")
    );
    
    this.$rules = {
        "start" : [
            {
                token : "variable.instancce", // variable tcl with braces
                regex : "[$]{?(?:[a-zA-Z_]|\d)+}?"
            }
        ]
    };

    
};

oop.inherits(NextHighlightRules, TextHighlightRules);

exports.NextHighlightRules = NextHighlightRules;
});

define('ace/mode/matching_brace_outdent', ['require', 'exports', 'module' , 'ace/range'], function(require, exports, module) {


var Range = require("../range").Range;

var MatchingBraceOutdent = function() {};

(function() {

    this.checkOutdent = function(line, input) {
        if (! /^\s+$/.test(line))
            return false;

        return /^\s*\}/.test(input);
    };

    this.autoOutdent = function(doc, row) {
        var line = doc.getLine(row);
        var match = line.match(/^(\s*\})/);

        if (!match) return 0;

        var column = match[1].length;
        var openBracePos = doc.findMatchingBracket({row: row, column: column});

        if (!openBracePos || openBracePos.row == row) return 0;

        var indent = this.$getIndent(doc.getLine(openBracePos.row));
        doc.replace(new Range(row, 0, row, column-1), indent);
    };

    this.$getIndent = function(line) {
        var match = line.match(/^(\s+)/);
        if (match) {
            return match[1];
        }

        return "";
    };

}).call(MatchingBraceOutdent.prototype);

exports.MatchingBraceOutdent = MatchingBraceOutdent;
});
