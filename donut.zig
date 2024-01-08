// TODO: more reductions and make it donut shaped
// zig fmt: off
var rb=[_]u8{32}**2450;
var zb=[_]f32{0}**2450;

pub fn main() !void {
    const w=@import("std").io.getStdOut().writer();
    try w.writeAll("\x1B[?25l");
    try w.writeAll("\x1B[2J");

    var rx:f32=0;var rz:f32=0;while(true):({rx+=0.05;rz+=0.03;}) {
        const crx=@cos(rx);const srx=@sin(rx);
        const crz=@cos(rz);const srz=@sin(rz);

         var p:f32=0;while(p<=6.283):(p+=0.02){
             const cp=@cos(p);const sp=@sin(p);

             var t:f32=0;while(t<=6.283):(t+=0.07) {
                const ct=@cos(t);const st=@sin(t);

                const cx=3+2*ct;
                const tx=cx*(crz*cp+srx*srz*sp)-(2*st)*crx*srz;
                const ty=cx*(srz*cp-srx*crz*sp)+(2*st)*crx*crz;
                const tz=15+crx*cx*sp+(2*st)*srx;
                const iz=1 / tz;
      
                const l=(cp*ct*srz)-(crx*ct*sp)-(srx*st)+(crz*(crx*st-ct*srx*sp));

                if (l>0) {
                    const sx:usize=@intFromFloat(35+(78*iz*tx));
                    const sy:usize=@intFromFloat(17.5-(39*iz*ty));
                    if (iz>zb[sx+70*sy]) {
                        zb[sx+70*sy]=iz;
                        rb[sx+70*sy]=".,-~:;=!*#$@"[@intFromFloat(l*8)];
                    }
                }
            }
         }
        try w.writeAll("\x1B[0;0H");
        for(0..35)|y|{
            try w.print("{s}\n",.{rb[70*y..][0..70]});
        }
        @memset(&rb,32);
        @memset(&zb,0);
    }
    try w.writeAll("\x1B[0m");
}
