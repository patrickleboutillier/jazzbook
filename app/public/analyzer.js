/*
	This module will contain a class that is used to cellect the chords in the tune
	and perform simple harmonic analysis on them
*/

class Analyzer {
	constructor(){
		this.progressions = new Array() ;
	}

	addProgression(){
		var prog = new Array() ;
		this.progressions.push(prog) ;
	}

	addChord(tune_chord, element){
		var matches = tune_chord.name.match(/^[A-G]/) ;
    	if ((matches)&&(matches.length > 0)){
			var music_chord = new Chord(tune_chord.name) ;
			var prog = this.progressions[ this.progressions.length - 1 ] ;
			var obj = {} ;
			obj.tune = tune_chord ;
			obj.chord = music_chord ;
			obj.elem = element ;
			prog.push(obj) ;
		}
	}

	render(){
		var P5 = new Interval("P5") ;
		for (var p = 0 ; p < this.progressions.length ; p++){
			var prog = this.progressions[p] ;
			for (var c = 0 ; c < prog.length ; c++){
				if (c > 0){
					var prev_chord = prog[c-1] ;
					var cur_chord = prog[c] ;

					if (P5.below(prev_chord.chord.root)._semitone_distance(cur_chord.chord.root) == 0){
						if (prev_chord.chord.isDominant()){
						   connectVI(prev_chord.elem, cur_chord.elem, "black") ;
						}
						if ((prev_chord.chord.isMinor())&&(cur_chord.chord.isDominant())){
						   connectIIV(prev_chord.elem, cur_chord.elem, "black") ;
						}
						if ((prev_chord.chord.isMinor7b5())&&(cur_chord.chord.isDominant())){
						   connectIIV(prev_chord.elem, cur_chord.elem, "black") ;
						}
					}
				}
			}
		}
	}
}
