//
//  PreviewImage.metal
//  UIImageTest
//
//  Created by Kazi Mashry on 1/27/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void previewImage(texture2d<float, access::read> input [[texture(0)]],
                         texture2d<float, access::write> output [[texture(1)]],
                         constant float2 &boundary [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
        return;
    }

    float lowerX = boundary.x;
    float lowerY = boundary.y;

    uint2 rGid;
    rGid.x = gid.x - (uint)(lowerX);
    rGid.y = gid.y - (uint)(lowerY);

    if (rGid.x < output.get_width() && rGid.y < output.get_height()) {
        float4 pixel = input.read(gid);
        output.write(pixel, rGid);
    }
}

