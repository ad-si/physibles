include <BOSL2-master/std.scad>

// All measures in mm

type = "plug"; // "cover" or "plug"

pipe_outer_diameter = 26;
pipe_wall_thickness = 2;
cap_wall_thickness = 3;
pad_thickness = 5; // Thickness of the end part of the cap
height = 20;       // Distance from end of pipe to end of cap
rounding = 3;      // Radius of the edge of the cap
chamfer = 2;

eps = 0.01; // Used to prevent z-fighting
$fn = 45;
// $fn = 90;

////////////////////////////////////////////////////////////////////////////////

cap_outer_rad = (pipe_outer_diameter / 2) + cap_wall_thickness;
cap_inner_rad = pipe_outer_diameter / 2;
pipe_inner_rad = cap_inner_rad - pipe_wall_thickness;

module ring(height = 2, outer_r = 10, inner_r = 5) {
  difference() {
    cylinder(h = height, r = outer_r);
    translate([ 0, 0, -eps ]) cylinder(h = height + (2 * eps), r = inner_r);
  }
}

module cut_off_cube(area = "positive-z", size = 10) {
  if (area == "positive-z") {
    translate([ 0, 0, -size / 2 ]) cube(size, center = true);
  }
  else if (area == "negative-z") {
    translate([ 0, 0, -size / 2 ]) cube(size, center = true);
  }
  else if (area == "positive-x") {
    translate([ -size / 2, 0, 0 ]) cube(size, center = true);
  }
  else if (area == "negative-x") {
    translate([ size / 2, 0, 0 ]) cube(size, center = true);
  }
  else if (area == "positive-y") {
    translate([ 0, -size / 2, 0 ]) cube(size, center = true);
  }
  else if (area == "negative-y") {
    translate([ 0, size / 2, 0 ]) cube(size, center = true);
  }
}

module outer_body() {
  // Move to touch xy plane
  translate([ 0, 0, rounding ])
      // Cut off upper rounded part
      difference() {
    minkowski() {
      cylinder(h = height + pad_thickness, r = cap_outer_rad - rounding);
      sphere(rounding);
    }
    translate([ 0, 0, height + pad_thickness - rounding ]) {
      cylinder(h = height, r = cap_outer_rad + eps, center = false);
    }
  }
}

module outer_hull() {
  // Hollow out the centre
  difference() {
    outer_body();
    translate([ 0, 0, pad_thickness ])
        cylinder(h = height * 2, r = cap_inner_rad);
  }
}

module inner_plug() {
  inner_plug_rad = cap_inner_rad - pipe_wall_thickness;

  module inner_plug_body() {
    translate([ 0, 0, pad_thickness - eps ]) {
      union() {
        inner_plug_h = 2 - cap_inner_rad;
        cylinder(h = inner_plug_h, r = inner_plug_rad);
        // Tip of plug
        translate(v = [ 0, 0, inner_plug_h ]) difference() {
          // Make inner sphere a little larger
          // to ensure it presses onto the pipe wall
          extra_width = pipe_wall_thickness * 0.02;
          sphere(r = inner_plug_rad + extra_width);
          translate([ 0, 0, -(inner_plug_rad / 2) - extra_width ]) cube(
              [
                (inner_plug_rad + extra_width) * 2.1,
                (inner_plug_rad + extra_width) * 2.1,
                inner_plug_rad
              ],
              center = true
          );
        }
      }
    }
  }

  module slot() {
    solid_bottom_height = 5;
    slot_height = (height + pad_thickness) * 1.1;
    translate([ 0, 0, (slot_height / 2) + pad_thickness + solid_bottom_height ]
    ) //
        cube(
            [ pipe_wall_thickness, cap_inner_rad * 2, slot_height ],
            center = true
        );
  }

  difference() {
    inner_plug_body();
    // slot();
    // rotate(a = 90) slot();
  }
}

// outer_body();
// outer_hull();
// inner_plug();

module cover() {
  // Add inner slotted pipe to clamp onto pipe wall
  union() {
    outer_hull();
    inner_plug();
  }
}

module plug() {
  // Add inner slotted pipe to clamp onto pipe wall
  union() {
    outer_body();
    inner_plug();
  }
}

module half_plug(
    wedge_thickness = 1, //
    wedge_angle = 2,
    tolerance = 0.2 // Make plug slightly smaller for easier insertion
) {
  translate([ 0, 0, -(wedge_thickness + tolerance) / 2 ]) difference() {
    rotate([ 0, 90 - wedge_angle, 0 ]) difference() {
      outer_body();
      translate([ 0, 0, pad_thickness ]) ring(
          height = height * 1.1,       //
          outer_r = cap_outer_rad * 2, //
          inner_r = pipe_inner_rad
      );
    }
    translate([ 0, 0, (wedge_thickness + tolerance) / 2 ])
        cut_off_cube(area = "negative-z", size = height * 5);
  }
}

// // Must be printed vertically for best layer orientation
// module wedge(
//     wedge_width = 10,    //
//     wedge_depth = 50,    //
//     wedge_thickness = 1, //
//     wedge_angle = 2
// ) {
//   translate([ 0, 0, wedge_width / 2 ]) cube(
//       size = [ wedge_thickness / 2, wedge_depth, wedge_width ], center = true
//   );
// }

if (type == "cover") {
  cover();
}
else {
  minimum_wedge_thickness = pipe_wall_thickness * 0.5;
  wedge_thickness = pipe_wall_thickness * 1.1;
  wedge_angle = 2;

  half_plug(wedge_thickness, wedge_angle);
  translate([ -2 * height, 0, 0 ]) half_plug(wedge_thickness, wedge_angle);
  // translate([ 0, 20, 0 ]) rotate([ 0, 0, 90 ])
  union() {
    translate([ -5, -15, 0 ]) rotate([ 0, -90, 0 ]) union() {
      cube([
        pipe_inner_rad * 2, //
        height + pad_thickness,
        minimum_wedge_thickness
      ]);
      translate([ 0, 0, minimum_wedge_thickness - eps ]) wedge([
        pipe_inner_rad * 2,
        height + pad_thickness,
        (wedge_thickness - minimum_wedge_thickness) / 2,
      ]);
      mirror([ 0, 0, 1 ]) translate([ 0, 0, -eps ]) wedge([
        pipe_inner_rad * 2,
        height + pad_thickness,
        (wedge_thickness - minimum_wedge_thickness) / 2,
      ]);
    }
  }
}
