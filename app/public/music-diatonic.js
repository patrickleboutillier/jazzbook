(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict' ;

module.exports = class Interval {
	constructor(str){
		var matches = str.match(/^([Ad]*)(([AdmM][2367])|([AdP][145]))$/) ;
        if ((matches)&&(matches.length > 0)){
			var pref = matches[1] ;
			var core = matches[2] ;
			var l = core.charAt(0) ;
			var n = parseInt(core.substring(1)) ;

			this.acc = 0 ;
			if (l == "A"){
				if ((n == 2)||(n == 3)||(n == 6)||(n == 7)){
					l = "M" ;
				}
				else {
					l = "P" ;
				}
				this.acc = pref.length + 1 ;
			}
			else if (l == "d"){
				if ((n == 2)||(n == 3)||(n == 6)||(n == 7)){
					l = "m" ;
				}
				else {
					l = "P" ;
				}
				this.acc = -(pref.length + 1) ;
			}

			this.quality = l ;
			this.steps = n - 1 ;
			this.semitones = this._countSemitones(l + n) ;
		}
		else {
			throw new Error("Unknown interval '" + str + "'") ;
		}
	}

	_countSemitones(str){
		switch (str){
			case "P1": return 0 ;
			case "m2": return 1 ;
			case "M2": return 2 ;
			case "m3": return 3 ;
			case "M3": return 4 ;
			case "P4": return 5 ;
			case "P5": return 7 ;
			case "m6": return 8 ;
			case "M6": return 9 ;
			case "m7": return 10 ;
			case "M7": return 11 ;
		}
	}

	toString(){
		return this.getQuality() + (this.getSteps() + 1) ;
	}

	getSteps(){
		return this.steps ;
	}

	getSemitones(){
		return this.semitones + this.acc ;
	}

	getQuality(){
		if (this.acc > 0){
			return "A".repeat(this.acc) ;
		}
		else if (this.acc < 0){
			return "d".repeat(-this.acc) ;
		}
		else {
			return this.quality ;
		}
	}

	augment(){
		var ret = Object.assign(Object.create(Interval.prototype), this) ;
		if ((ret.quality == "m")&&(ret.acc == 0)){
			ret.quality = "M" ;
			ret.semitones += 1 ;
		}
		else {
			ret.acc++ ;
		}
		return ret ;
	}

	diminish(){
		var ret = Object.assign(Object.create(Interval.prototype), this) ;
		if ((ret.quality == "M")&&(ret.acc == 0)){
			ret.quality = "m" ;
			ret.semitones -= 1 ;
		}
		else {
			ret.acc-- ;
		}
		return ret ;
	}

	above(n){
		var n2 = n ;
		var steps = this.getSteps() ;
		for (var j = 0 ; j < steps ; j++){
			n2 = n2.next() ;
		}

		var semis = this.getSemitones() ;
		return n2._adjust(semis - n._semitone_distance(n2)) ;
	}

	below(n){
		var n2 = n ;
		var steps = this.getSteps() ;
		for (var j = 0 ; j < steps ; j++){
			n2 = n2.prev() ;
		}

		var semis = this.getSemitones() ;
		return n2._adjust(n2._semitone_distance(n) - semis) ;
	}

	static circleOfFifths(n){
		var P5 = new Interval("P5") ;
		var ret = new Array() ;
		ret[7] = n ;
		for (var i = 6 ; i >= 0 ; i--){
			ret[i] = P5.below(ret[i+1]) ;
		}
		for (var i = 8 ; i < 15 ; i++){
			ret[i] = P5.above(ret[i-1]) ;
		}
		return ret ;
	}

}

},{}],2:[function(require,module,exports){
'use strict' ;

module.exports = class Note {
	constructor(str){
		var matches = str.match(/^([A-G])(#+|b+|)/) ;
		if ((matches)&&(matches.length > 0)){
			this.note = matches[1] ;
			this.acc = 0 ;
			if (matches[2].length > 0){
				if (matches[2].charAt(0) == 'b'){
					this.acc = -matches[2].length ;
				}
				else {
					this.acc = matches[2].length ;
				}
			}
		}
		else {
			throw new Error("Unknown note '" + str + "'") ;
		}
	}

	toString(){
		return this.getNote() + this.getAccidental() ;
	}

	getNote(){
		return this.note ;
	}

	getAccidental(){
		return (this.acc < 0 ? "b".repeat(-this.acc) : "#".repeat(this.acc)) ;
	}

	isNatural(){
		return (this.acc == 0) ;
	}

	isSharp(){
		return (this.acc > 0) ;
	}

	isFlat(){
		return (this.acc < 0) ;
	}

	natural(){
		return this._adjust(-this.acc) ;
	}

	raise(){
		return this._adjust(1) ;
	}

	sharp(){ 
		return this.raise() ;
	}
	
	lower(){
		return this._adjust(-1) ;
	}

	flat(){ 
		return this.lower() ;
	}

	next(){
		return new Note(this.note == "G" ? "A" : String.fromCharCode(this.note.charCodeAt(0) + 1)) ;
	}

	prev(){
		return new Note(this.note == "A" ? "G" : String.fromCharCode(this.note.charCodeAt(0) - 1)) ;
	}


	// Adjusts the note by the given number of semitones (>0 is sharp, <0 is flat)
	_adjust(i){
		var ret = Object.assign(Object.create(Note.prototype), this) ;
		ret.acc += i ;
		return ret ;
	}


	_step_distance(n){
		if (this.natural().toString() == n.natural().toString()){
			return 0 ;
		}
		else {
			return 1 + this.next()._step_distance(n) ;
		}
	}

	_semitone_distance(n){
		if (this.isSharp()){
			return this.lower()._semitone_distance(n) - 1 ;
		}
		if (this.isFlat()){
			return this.raise()._semitone_distance(n) + 1 ;
		}
		if (n.isSharp()){
			return this._semitone_distance(n.lower()) + 1 ;
		}
		if (n.isFlat()){
			return this._semitone_distance(n.raise()) - 1 ;
		}

		// All accidentals are gone.
		var steps = this._step_distance(n) ;
		switch (steps){
			case 0: return 0 ;
			case 1: return (((this.note == "E")||(this.note == "B")) ? 1 : 2) ;
			default:
				var nn = this.next() ;
				return this._semitone_distance(nn) + nn._semitone_distance(n) ;
		}
	}
}

},{}],3:[function(require,module,exports){
Interval = require("../src/Interval.js") ;
Note = require('../src/Note.js') ;

},{"../src/Interval.js":1,"../src/Note.js":2}]},{},[3]);
