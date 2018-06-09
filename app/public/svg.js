

// Create the SVG canvas

var tunepos = null ;

function createSVG() {
  var svg = document.getElementById("svg-canvas");
  if (null == svg) {
	var tune = document.getElementById('tune') ;
	tunepos = findAbsolutePosition(tune, true) ;
	tunepos.w = tune.clientWidth ;
	tunepos.h = tune.clientHeight ;
    svg = document.createElementNS("http://www.w3.org/2000/svg", 
                                   "svg");
    svg.setAttribute('id', 'svg-canvas');
    svg.setAttribute('style', 'position:absolute;top:' + tunepos.y + 'px;left:' + tunepos.x + 'px');
    svg.setAttribute('width', tune.clientWidth);
    svg.setAttribute('height', tune.clientHeight + 10);
    svg.setAttributeNS("http://www.w3.org/2000/xmlns/", 
                       "xmlns:xlink", 
                       "http://www.w3.org/1999/xlink");
    tune.appendChild(svg);
  }
  return svg;
}


function findAbsolutePosition(htmlElement, abs) {
  var x = htmlElement.offsetLeft;
  var y = htmlElement.offsetTop;
  for (var x=0, y=0, el=htmlElement; el != null; el = el.offsetParent) {
         x += el.offsetLeft;
         y += el.offsetTop;
  }

  if (! abs){
		x -= tunepos.x ;
		y -= tunepos.y ;
  }

  return {
      "x": x,
      "y": y
  };
}


function drawCurvedLine(x1, y1, x2, y2, color) {
    var svg = createSVG();
    var shape = document.createElementNS("http://www.w3.org/2000/svg", 
                                         "path");
    var delta = 10 ;
    var hx1=x1+delta;
    var hy1=y1-delta*2;
    var hx2=x2-delta;
    var hy2=y2-delta*2;
    var path = "M "  + x1 + " " + y1 + 
               " C " + hx1 + " " + hy1 
                     + " "  + hx2 + " " + hy2 
               + " " + x2 + " " + y2;
    shape.setAttributeNS(null, "d", path);
    shape.setAttributeNS(null, "fill", "none");
    shape.setAttributeNS(null, "stroke", color);
    shape.setAttributeNS(null, "stroke-width", 2);
    svg.appendChild(shape);
}


function drawLine(x1, y1, x2, y2, color) {
    var svg = createSVG();
    var shape = document.createElementNS("http://www.w3.org/2000/svg", 
                                         "path");
    var leg = 10 ;
    var path = "M "  + x1 + " " + y1 + 
               " L " + x1 + " " + (y1+leg) +
               " L " + x2 + " " + (y2+leg) +
               " L " + x2 + " " + y2 ;
    shape.setAttributeNS(null, "d", path);
    shape.setAttributeNS(null, "fill", "none");
    shape.setAttributeNS(null, "stroke", color);
    shape.setAttributeNS(null, "stroke-width", 2);
    svg.appendChild(shape);
}


function connectIIV(left, right, color) {
  var svg = createSVG();
  var leftPos = findAbsolutePosition(left);
  var x1 = leftPos.x;
  var y1 = leftPos.y;
  x1 += (left.offsetWidth / 2);
  y1 += left.offsetHeight ;
 
  var rightPos = findAbsolutePosition(right);
  var x2 = rightPos.x;
  var y2 = rightPos.y;
  x2 += (right.offsetWidth / 2);
  y2 += right.offsetHeight;

  if (x2 > x1){ 
    drawLine(x1, y1, x2, y2, color);
  }
}


function connectVI(left, right, color) {
  var svg = createSVG();
  var leftPos = findAbsolutePosition(left);
  var x1 = leftPos.x;
  var y1 = leftPos.y;
  x1 += (left.offsetWidth / 2);
 
  var rightPos = findAbsolutePosition(right);
  var x2 = rightPos.x;
  var y2 = rightPos.y;
  x2 += (right.offsetWidth / 2);
 
  if (x2 > x1){ 
    drawCurvedLine(x1, y1, x2, y2, color);
  }
  else {
    drawCurvedLine(x1, y1, tunepos.w + x2, y1, color);
    drawCurvedLine(-(tunepos.w - x1), y2, x2, y2, color);
  }
}


