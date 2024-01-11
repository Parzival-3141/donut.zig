// Based off https://www.a1k0n.net/2011/07/20/donut-math.html

/// Torus minor radius (i.e. the radius of the tube)
const R1 = 2;
/// Torus major radius
/// (i.e. the distance from the center of the tube to the center of the torus)
const R2 = 3;

/// Distance from camera to the viewing plane. Determines FOV.
// Calculated based off screen size to ensure torus fills the frame
// without clipping the borders.
const K1x = screen_width * K2 * 3 / (8 * (R1 + R2));
const K1y = screen_height * K2 * 3 / (8 * (R1 + R2));

/// Distance of the donut from the camera
const K2 = 15;

/// Good enough approximation...
const PI = 3.1415926;

const theta_increment = 0.07;
const phi_increment = 0.02;

const screen_width = 70;
const screen_height = screen_width / 2;

/// Render buffer
var r_buffer = [_]u8{' '} ** (screen_width * screen_height);
/// Depth buffer
var z_buffer = [_]f32{0} ** (screen_width * screen_height);

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // disable cursor and clear screen
    try stdout.writeAll("\x1B[?25l");
    try stdout.writeAll("\x1B[2J");

    // rotation in radians along x and z axis
    var rot_x: f32 = 0;
    var rot_z: f32 = 0;
    while (true) : ({
        rot_x += 0.05;
        rot_z += 0.03;
    }) {
        const cos_rot_x = @cos(rot_x);
        const sin_rot_x = @sin(rot_x);

        const cos_rot_z = @cos(rot_z);
        const sin_rot_z = @sin(rot_z);

        // Compute points on a circle, rotated around the y-axis
        // to form a torus "point cloud".
        var phi: f32 = 0;
        while (phi <= 2 * PI) : (phi += phi_increment) {
            const cos_phi = @cos(phi);
            const sin_phi = @sin(phi);

            var theta: f32 = 0;
            while (theta <= 2 * PI) : (theta += theta_increment) {
                const cos_theta = @cos(theta);
                const sin_theta = @sin(theta);

                // compute point on circle
                const circle_x = R2 + R1 * cos_theta;
                const circle_y = R1 * sin_theta;
                // implicitly z = 0

                // compute world-space point on torus using circle point,
                // "sweeping" the circle around the local y-axis by phi
                // and applying a rotation matrix.
                const torus_x = circle_x * (cos_rot_z * cos_phi + sin_rot_x * sin_rot_z * sin_phi) - circle_y * cos_rot_x * sin_rot_z;
                const torus_y = circle_x * (cos_phi * sin_rot_z - cos_rot_z * sin_rot_x * sin_phi) + circle_y * cos_rot_x * cos_rot_z;
                const torus_z = cos_rot_x * circle_x * sin_phi + circle_y * sin_rot_x;

                // computing inverse of z avoids extra divisions and makes using the z-buffer easier
                const inverse_z = 1 / (K2 + torus_z);

                // project point from world-space into screen-space
                const scrn_x: usize = @intFromFloat(screen_width / 2 + (K1x * inverse_z * torus_x));
                const scrn_y: usize = @intFromFloat(screen_height / 2 - (K1y * inverse_z * torus_y)); // y is negated since in 3D +y is up, but in 2D -y is up.

                // The dot product of the surface normal and a light vector
                // above and behind the camera (0, 1, -1). The light vector
                // should be normalized but we handle it below. A mouthful, but correct.
                const luminance = (cos_phi * cos_theta * sin_rot_z) - (cos_rot_x * cos_theta * sin_phi) -
                    (sin_rot_x * sin_theta) + (cos_rot_z * (cos_rot_x * sin_theta - cos_theta * sin_rot_x * sin_phi));

                // TODO: some foreground points have <0 luminance when they should be
                // bright. Not entirely sure why, but the effect is exacerbated at higher
                // render resolutions.
                // const screen_idx = scrn_x + screen_width * scrn_y;
                // if (inverse_z > z_buffer[screen_idx] and luminance < 0) {
                //     r_buffer[screen_idx] = if (z_buffer[screen_idx] != 0) 'f' else ' ';
                //     z_buffer[screen_idx] = inverse_z;
                // } else

                // luminance ranges from -sqrt(2) to +sqrt(2).
                // If it's < 0 the surface is pointing away from us, so it's not worth rendering.
                if (luminance > 0) {
                    const screen_idx = scrn_x + screen_width * scrn_y;
                    // test the z-buffer, a larger inverse_z means the point is closer to the camera.
                    if (inverse_z > z_buffer[screen_idx]) {
                        z_buffer[screen_idx] = inverse_z;
                        // multiplying luminance by 8 and casting to an integer puts it in the 0..11 range (8*sqrt(2) == 11.3).
                        r_buffer[screen_idx] = ".,-~:;=!*#$@"[@intFromFloat(luminance * 8)];
                    }
                }
            }
        }

        // reset cursor position
        try stdout.writeAll("\x1B[H");

        // dump r_buffer to screen
        for (0..screen_height) |y| {
            try stdout.print("{s}\n", .{r_buffer[screen_width * y ..][0..screen_width]});
        }

        @memset(&r_buffer, ' '); // clear r_buffer
        @memset(&z_buffer, 0); // clear z_buffer
        // std.time.sleep(16 * std.time.ns_per_ms); // uncomment to add a frame delay if it's spinning too fast
    }

    // reset terminal
    try stdout.writeAll("\x1B[25h");
}

const std = @import("std");
