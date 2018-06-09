#!/usr/bin/node 

var Chord = require("../../music-diatonic/src/Chord.js") ;

var file = process.argv[2] ;
var fs = require('fs') ;

var seqs = analyze(file) ;
console.log(seqs) ;

function analyze(file){
	var tune = JSON.parse(fs.readFileSync(file).toString()) ;

	var sequences = new Array() ;
	var cur_seq = null ;
	tune.sections.forEach (function(s) {
		cur_seq = new Array() ;
		s.bars.forEach (function(b) {
			if (! b.repeat_last){
				b.chords.forEach (function(c) {
					console.log(c.name) ;
					var crd = new Chord(c.name) ;
					crd.tune_chord = c ;
					cur_seq.push(crd) ;
				}) ;
			}
		}) ;
		sequences.push(cur_seq) ;
	}) ;

	return sequences ;
}
