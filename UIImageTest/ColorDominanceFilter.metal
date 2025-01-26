//
//  ColorDominanceFilter.metal
//  UIImageTest
//
//  Created by Kazi Mashry on 1/26/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void colorDominance(texture2d<float, access::read> input [[texture(0)]],
                           texture2d<float, access::write> output [[texture(1)]],
                           constant float4 &dominance [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
        return;
    }

    // Read the pixel at the current grid position
    float4 pixel = input.read(gid);

    // Apply dominance factor to the pixel's RGBA components
    float4 result = float4(pixel.r * dominance.r,
                           pixel.g * dominance.g,
                           pixel.b * dominance.b,
                           pixel.a * dominance.a);

    // Write the result back to the output texture
    output.write(result, gid);
}



