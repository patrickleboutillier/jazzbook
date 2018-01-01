/* A tune is composed of:
	- title:
	- composer:
	- style:
	- key:
	- sections: A list of section that build up the tune.

Each section can contain:
	- label: Section label (A, B, I, ...)
	- description: Comment to be displayed at the top of the section, next to the label
	- repeat: number of times the section should be repeated
	- bars: A list of bars

Each bar can contain:
	- coda, segno: symbols that are added to the top of the bar.
	- repeat_last: repeat last bar (1, %) or last two bars (2, %%).
	- meter: Time signature for the bar (4/4). Carries on from the last bar if not specified.
	- beats: number of beats in the bar. Carries on from the last bar if not specified.
	- chords: A list of chords

Each chord can contain:
	- name:
	- beats: Number of beats for the chord. If not specified, remaining time is divided evenly between chords.

*/


var params = parse_query_string() ;
var name = params['t'] ;
var book = params['b'] ;

var _debug = 0 ;
var _beats = 0 ;
var _noalt = 0 ;
var beats_per_bar = 4 ;
var col = 0 ;

var tbody = document.getElementById('tune') ;
var top_tr, mid_tr, bot_tr ;

var dir = "/jazzbooks/" + book + "/" ;
var xmlhttp = new XMLHttpRequest() ;
var tune ;
var fifths_offset = 0 ;

xmlhttp.onreadystatechange = function(){
	if (this.readyState == 4 && this.status == 200){
		tune = JSON.parse(this.responseText) ;
		display(tune) ;
	}
} ;
xmlhttp.open("GET", dir + name + ".json", true) ;
xmlhttp.send() ;


function parse_query_string(){
    var params = {} ;

    if (location.search){
	    var queries = location.search.substring(1).split("&") ;
	    for (var i = 0, l = queries.length ; i < l; i++){
	        var temp = queries[i].split('=') ;
	        params[temp[0]] = temp[1] ;
	    }
	}

    return params ;
}


function display(tune){
	_debug = params['debug'] ;
	_beats = params['beats'] ;
	_noalt = params['noalt'] ;

	header(tune) ;

	for (var i in tune.sections){
		var s = tune.sections[i] ;
		section(s) ;
	}

	if ((_debug)&&(tune.metadata)){
		var tr = tbody.insertRow() ;
		var td = tr.insertCell() ;
		td.setAttribute('colspan', 12) ;
		var pre = document.createElement('pre') ;
		td.appendChild(pre) ;
		pre.innerHTML = tune.metadata.join("\n") ;
	}

	circleOfFifths() ;
}


function header(tune){
	while (tbody.firstChild){
		tbody.removeChild(tbody.firstChild) ;
	}

	if (_debug){
		tbody.setAttribute("border", "1") ;
	}
	else{
		tbody.setAttribute("border", "0") ;
	}

	var tr = tbody.insertRow() ;
	var td = tr.insertCell() ;
	td.setAttribute("colspan", 12) ;
	td.style = "text-align: center" ; 
	td.innerHTML = "<span class='composer'>" + tune.composer + "</span>" +
		"<span class='title'>" + tune.title + "</span>" +
		"<span class='style'>" + tune.style + "</span>" ;
}


/* Each section is a table that is 12 columns wide (4 prebars, 4 bars, 4 postbars)
*/
function section(sect){
	var repeat = (sect.repeat ? sect.repeat : 0) ;
	var label = fix_label(sect.label) ;
	var description = (sect.description ? sect.description : "") ;

	// We go through the bars of the section.
	if ((sect.bars)&&(sect.bars.length > 0)){
		for (var i = 0 ; i < sect.bars.length ; i++){
			var first = (i == 0 ? true : false) ;
			var last = (i == (sect.bars.length - 1) ? true : false) ;

			prebar((first ? label : ""), first, repeat) ;
			bar(sect.bars[i], (first ? description : "")) ;

			if ((last)&&(repeat)&&(sect.sections)&&(sect.sections[0].ending == 1)){
				// Force a plain bar line.
				postbar(0, 0) ;
			}
			else {
				postbar(last, repeat) ;
			}

 			col++ ;
			if (col == 4){
				col = 0 ;
			}
		}
	}


	var padding = [] ;
	if ((sect.sections)&&(sect.sections.length > 0)){
		for (var i = 0 ; i < sect.sections.length ; i++){
			var sub = sect.sections[i] ;
			var ending = sub.ending ;
			var label = fix_label(sub.label) ;
			var description = (sub.description ? sub.description : "") ;

			if (ending > 0){
				// Section ending.
				if ((sub.bars)&&(sub.bars.length > 0)){
					// Add accumulated padding
					for (var j = 0 ; j < padding.length ; j++){
						prebar("", false, false, true) ;
						bar(padding[j], "", false) ;
						postbar(false, false, true) ;
	
						col++ ;
						if (col == 4){
							col = 0 ;
						}
					}

					for (var j = 0 ; j < sub.bars.length ; j++){
						var first = (j == 0 ? true : false) ;
						var last = (j == (sub.bars.length - 1) ? true : false) ;

						// For repeat section, we never use double bar lines or repeats
						prebar((first ? label : ""), ((first)&&(label)), false) ;
						bar(sub.bars[j], (first ? "&nbsp;" + ending + ". " + description : "") , first) ;

						if ((last)&&(ending == 1)){
							// Force a repeat bar line
							postbar(last, true) ;
						}
						else {
							postbar(last, false) ;
						}

						col++ ;
						if (col == 4){
							col = 0 ;
						}
					}

					// Prepare padding.
					padding = [] ;
					if ((i < sect.sections.length - 1)&&((sub.bars.length % 4) > 0)){
						// In order to align the starts of the repeat section, we must ensure the endings
						// are of full line lengths (multiples of 4).
						var extra = 4 - (sub.bars.length % 4) ;
						for (var j = 0 ; j < extra ; j++){
							padding.push({}) ;
						}
					}
		
				}
			}
			else {
				section(sub) ;
			}
		}
	}
}


function fix_label(label){
	label = (label ? label.substring(0, 1).toUpperCase() : "") ;
	// TODO: What to do with the rest on the string?
	switch (label) {
		case "A": return "&#x0391;" ;
		case "B": return "&#x0392;" ;
		case "C": return "&#x0393;" ;
		case "D": return "&#x0394;" ;
		case "E": return "&#x0395;" ;
		case "F": return "&#x0396;" ;
		case "@": return "&#x00A4;" ;
		default : return (label ? "(" + label + ")" : "") ;
	}
}


/* A bar is opened if it is the first bar of a section or of a line.
   Also, if it is the first bar of the section and it is a repeat section, we put the repeat sign.
*/
function prebar(label, first, repeat, white = 0){
	if ((col == 0)||((first)&&(label))){
		// Insert a new tr
		top_tr = tbody.insertRow() ;
		mid_tr = tbody.insertRow() ;
		bot_tr = tbody.insertRow() ;
		col = 0 ;
	}

	var td = top_tr.insertCell() ;
	td.className = "label" ;
	td.innerHTML = label ; // (label ? label : "&nbsp;") ;

	td = mid_tr.insertCell() ;
	if (! white){
	    if ((first)&&(col == 0)){
	        td.className = "prebar2" ;
	    }
	    else if (col == 0){
			td.className = "prebar" ;
	    }

	    if ((first)&&(repeat)){
			td.innerHTML = "<span class='chord'>:</span>" ;
	    }
	}

	td = bot_tr.insertCell() ; // empty cell
}


/* A bar is always closed with a single bar line, except when it is the last bar in the section
   where we need to use a double bar.

   Also, if it is the last bar of the section and it is a repeat section, we put the repeat sign.
*/
function postbar(last, repeat, white = 0){
	var td = top_tr.insertCell() ; // empty cell

    td = mid_tr.insertCell() ;
	if (! white){
	    td.className = "postbar" ;

		if (last){
			td.className = "postbar2" ;
			if (repeat){
				td.innerHTML = "<span class='chord'>:</span>" ;
			}
		}
	}

 	td = bot_tr.insertCell() ; // empty cell
}


/* A bar is a table, that consists, for now, of two rows:
	- Chord names
	- Beat staff
*/
function bar(bar, description, ending = 0){
	if (bar.meter){
		beats_per_bar = bar.meter.split("/")[0] ;
	}
	if (bar.beats > 0){
		beats_per_bar = bar.beats ;
	}

	var td = top_tr.insertCell() ;
	if (ending){
		td.className = "ending" ;
	}
	if (bar.meter){
		td.innerHTML += "<span class='symbol'>" + bar.meter + "</span> " ;
	}
	if (bar.segno){
		td.innerHTML += "<span class='symbol'>&#x00A7;</span> " ;
	}
	if (description){
		td.innerHTML += "<span class='description'>" + description + "</span>" ;
	}
	if (bar.coda){
		td.innerHTML += " <span class='symbol' style='float: right'>&#x00A4;</span>" ;
	}

	td = mid_tr.insertCell() ;
	td.className = "cols" ;
	var tbl = document.createElement('table') ;
	td.appendChild(tbl) ;
	if (_debug){
	    tbl.setAttribute("border", "1") ;
	}
    tbl.style.width = "100%" ;

    // Insert the guide row
    var tr = tbl.insertRow() ;
	for (var i = 0 ; i < beats_per_bar ; i++){
		td = tr.insertCell() ;
		td.height = "1px" ;
		td.style.width = (100 / beats_per_bar) + "%" ;
	}

    alt_tr = tbl.insertRow() ;
    tr = tbl.insertRow() ;
	if (bar.repeat_last == 1){
		td = tr.insertCell() ;
		td.className = "chord" ;
		td.setAttribute('colspan', beats_per_bar) ;
		td.style.textAlign = 'center' ;
		td.innerHTML = "<span class='smaller'>%</span>" ;
	}
	else if (bar.repeat_last == 2){
		td = tr.insertCell() ;
		td.className = "chord" ;
		td.setAttribute('colspan', beats_per_bar) ;
		td.style.textAlign = 'right' ;
		td.innerHTML = "<span class='smaller'>%%</span>" ;
	}
	else {
		if ((bar.chords)&&(bar.chords.length > 0)){
			for (var i in bar.chords){
				var c = bar.chords[i] ;
				var beats = (c.beats > 0 ? c.beats : beats_per_bar) ;
				if (_beats){
					chord(alt_tr, tr, c, 1) ;
					for (var j = 0 ; j < beats - 1 ; j++){
						chord(alt_tr, tr, { name: "/" }, 1) ;
					}
				}
				else {
					chord(alt_tr, tr, c, beats) ;
				}
			}
		}
		else {
			// This can probably happen in other cases...
			//td = tr.insertCell() ;
			//td.className = "chord" ;
			//td.setAttribute('colspan', beats_per_bar) ;
			//td.style.textAlign = 'left' ;
			//td.innerHTML = "%" ;
		}
	}

	td = bot_tr.insertCell() ;
	td.className = "comment" ;
	if ((bar.comments)&&(bar.comments.length > 0)){
		td.innerHTML = bar.comments.join(", ") ;
	}
}


function chord(alt_tr, tr, chord, beats){
	var alt_td = alt_tr.insertCell() ;
	var td = tr.insertCell() ;
	if (beats > 1){
		td.setAttribute("colspan", beats) ;
		alt_td.setAttribute("colspan", beats) ;
		td.className = "chord" ;
		alt_td.className = "chord" ;
	}
	else {
       	td.className = "smallchord" ;
       	alt_td.className = "smallchord" ;
	}

	var c = chord.name ;
	var bass = chord.bass ;
	var alt = chord.altname ;
	td.innerHTML = format_chord(c, bass) ;

	if ((alt)&&(! _noalt)){
		alt_td.innerHTML = "<span class='q' style='color: #808080'>" + format_chord(alt, "") + "</span>" ;
	}

	td.innerHTML += "&nbsp;" ;
}

	
function format_chord(c, bass){
	var html = "" ;

	var matches = c.match(/^(([A-G])(b+|#+|))(.*)$/) ;
	if ((matches)&&(matches.length > 0)){
		var note = matches[1] ;
		var rest = matches[4] ;
		c = transpose(note) + rest ;
	}

	matches = c.match(/^([\sA-G])(b+|#+|)([\^\-h]+|)(.*)$/) ;
	if ((matches)&&(matches.length > 0)){
		var root = matches[1] ;
		var acc = matches[2] ;
		var sym = matches[3] ;
		var rest = matches[4] ;

		acc = acc.replace(/b/g, "&#x044C;") ;

		sym = sym.replace(/\^/g, "&#x00AA;") ;
		sym = sym.replace(/h/g, "&#x00D8;") ;
		sym = sym.replace(/\-/g, "<sup>-</sup>") ;

	    rest = rest.replace(/#/g, "<sup>#</sup>") ;
		rest = rest.replace(/b/g, "<sup>&#x044C;</sup>") ;

		html = root + 
			(acc ? "<span class='q2'><sup>" + acc + "</sup></span>" : "") +
			"<span class='q'>" + sym + "<sup>" + rest + "</sup></span>" ;
	}
	else {
		if ((c == "NC")||(c == "/")){
			html = "<span class='smaller'>" + c + "</span>" ;
		}
		else {
			html = c ;
		}
	}

	if (bass){
		bass = transpose(bass) ;
		bass = bass.replace(/b/g, "&#x044C;") ;
		html += "<span class='q'><sub>/" + bass + "</sub></span>" ; ;
	}

	return html ;
}


var P5 = new Interval("P5") ;
function transpose(note){
	if (fifths_offset == 0){
		return note ;
	}
	else if (fifths_offset > 0){
		for (var i = 0 ; i < fifths_offset ; i++){
			note = P5.above(new Note(note)).toString() ;
		}
	}
	else {
		for (var i = 0 ; i < -fifths_offset ; i++){
			note = P5.below(new Note(note)).toString() ;
		}
	}

	return note ;
}


function toggle(elem, param){
	if (elem.checked){
		params[param] = 1 ;
	}
	if (! elem.checked){
		params[param] = 0 ;
	}

	display(tune) ;
}


function circleOfFifths(){
	var select = document.getElementById('circle') ;
	var key = tune.key ;
	if (! key){
		key = "C" ;
	}
	var minor = (key.indexOf("-") > -1 ? "-" : "") ;
	var note = key.replace("-", "") ;
	
	var c5 = Interval.circleOfFifths(new Note(note)) ;
	for (var i = 0 ; i < c5.length ; i++){
		var t = c5[i].toString() + minor ;
		if (fifths_offset == parseInt(select.options[i].value)){
			select.options[i].selected = true ;
		}
		if (t == tune.key){
			t += " (default)" ;
		}
		select.options[i].text = t ;
	}
}


function setkey(select){
	var idx = select.selectedIndex ;
	fifths_offset = parseInt(select.options[idx].value) ;
	alert(fifths_offset) ;
	
	display(tune) ;
}
