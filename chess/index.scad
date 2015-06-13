$fn = 50;

edgeLength = 50;
maxHeight = 100;

/*
0: Empty
1: Pawn
2: Rook
3: Knight
4: Bishop
5: Queen
6: King

Color white: + 10
Color black: + 20
*/

setup = [
[12, 13, 14, 16, 15, 14, 13, 12],
[11, 11, 11, 11, 11, 11, 11, 11],
[0, 0, 0, 0, 0, 0, 0, 0],
[0, 0, 0, 0, 0, 0, 0, 0],
[0, 0, 0, 0, 0, 0, 0, 0],
[0, 0, 0, 0, 0, 0, 0, 0],
[21, 21, 21, 21, 21, 21, 21, 21],
[22, 23, 24, 26, 25, 24, 23, 22]
];


//rook();

chessboard();

module pawn (x, y, color) {
	
	height = 0.5 * maxHeight;
	
	translate([x, y, 0])
	cylinder(d1 = edgeLength * 0.5, d2=20, h=height);
}

module rook (x, y, color) {
	
	height = 0.6 * maxHeight;
	sizeVector = [edgeLength, edgeLength * 0.08, 10];
	
	translate([x, y, 0])
	
	
	difference() {
		cylinder(d1 = edgeLength * 0.6, d2 = edgeLength * 0.5, h = height);
		
		translate([0,0,height])
		union(){
			cube(size=sizeVector, center=true);
			rotate([0,0,60])
			cube(size=sizeVector, center=true);
			rotate([0,0,120])
			cube(size=sizeVector, center=true);
			cylinder(d=edgeLength * 0.3, h = 10, center=true);
		}
	}
}

module knight (x, y, color) {
	
	height = 0.7 * maxHeight;
	
	translate([x, y, 0])
	cylinder(d1 = edgeLength * 0.6, d2 = edgeLength * 0.6, h = height);
}

module bishop (x, y, color) {
	
	height = 0.8 * maxHeight;
	
	translate([x, y, 0])
	cylinder(d1 = edgeLength * 0.6, d2 = edgeLength * 0.2, h = height);
}

module queen (x, y, color) {
	
	height = 0.9 * maxHeight;
	
	translate([x, y, 0])
	cylinder(d1 = edgeLength * 0.6, d2 = edgeLength * 0.4, h = height);
}

module king (x, y, color) {
	
	height = maxHeight;
	
	translate([x, y, 0])
	cylinder(d1 = edgeLength * 0.6, d2 = edgeLength * 0.4, h = height);
}


module chessboard () {

	height = 10;
	
	module square (x, y, edgeLength) {
		translate([x * edgeLength, y * edgeLength, -height])
		cube(size=[edgeLength, edgeLength, height]);
	}
	
	 for (x = [0:7]) {
 		for (y = [0:7]) {
			squareColor = ((x + y) % 2 == 0) ? [0,0,0,1] : [1,1,1,1];
			figureColor = ((setup[y][x] - 20) < 0) ?
                            [0.92, 0.9, 0.85, 1] :
                            [0.2, 0.15, 0.1, 1];

            color(squareColor)
            square(x, y, edgeLength);

            color(figureColor)
            
            if (setup[y][x] % 10 == 1) {
                pawn(
                    x * edgeLength + edgeLength/2,
                    y * edgeLength + edgeLength/2,
                    squareColor);
            }
            else if (setup[y][x] % 10 == 2) {
                rook(
                    x * edgeLength + edgeLength/2,
                    y * edgeLength + edgeLength/2,
                    squareColor
                );
            }
            else if (setup[y][x] % 10 == 3) {
                knight(
                    x * edgeLength + edgeLength/2,
                    y * edgeLength + edgeLength/2,
                    squareColor
                );
            }
            else if (setup[y][x] % 10 == 4) {
                bishop(
                    x * edgeLength + edgeLength/2,
                    y * edgeLength + edgeLength/2,
                    squareColor
                );
            }
            else if (setup[y][x] % 10 == 5) {
                queen(
                    x * edgeLength + edgeLength/2,
                    y * edgeLength + edgeLength/2,
                    squareColor
                );
            }
            else if (setup[y][x] % 10 == 6) {
                king(
                    x * edgeLength + edgeLength/2,
                    y * edgeLength + edgeLength/2,
                    squareColor
                );
            }
		}
	}
}