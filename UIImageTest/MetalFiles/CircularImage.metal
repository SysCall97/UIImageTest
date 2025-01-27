//
//  CircularImage.metal
//  UIImageTest
//
//  Created by Kazi Mashry on 1/27/25.
//

#include <metal_stdlib>
using namespace metal;


//kernel void circularImage(texture2d<float, access::read> input [[texture(0)]],
//                           texture2d<float, access::write> output [[texture(1)]],
//                           constant float4 &boundary [[buffer(0)]],
//                           uint2 gid [[thread_position_in_grid]]) {
//    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
//        return;
//    }
//
//    // Read the pixel at the current grid position
//    float4 pixel = input.read(gid);
//    float alpha = pixel.a;
//
//    // Apply dominance factor to the pixel's RGBA components
//    float lowerX = boundary.r;
//    float upperX = boundary.g;
//    float lowerY = boundary.b;
//    float upperY = boundary.a;
//
//    if (!((float(gid.x) >= lowerX && float(gid.x) <= upperX) &&
//            (float(gid.y) >= lowerY && float(gid.y) <= upperY))) {
//        alpha = 0;
//    }
//
//    float4 result = float4(pixel.r,
//                           pixel.g,
//                           pixel.b,
//                           alpha);
//
//    // Write the result back to the output texture
//    output.write(result, gid);
//}


kernel void circularImage(texture2d<float, access::read> input [[texture(0)]],
                           texture2d<float, access::write> output [[texture(1)]],
                           constant float3 &boundary [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) {
        return;
    }

    // Read the pixel at the current grid position
    float4 pixel = input.read(gid);
    float alpha = pixel.a;

    // Apply dominance factor to the pixel's RGBA components
    float cx = boundary.x;
    float cy = boundary.y;
    float radius = boundary.z;

    float distance = sqrt(pow(gid.x - cx, 2) + pow(gid.y - cy, 2));

    if (distance > radius) {
        alpha = 0;
    }

    float4 result = float4(pixel.r,
                           pixel.g,
                           pixel.b,
                           alpha);

    // Write the result back to the output texture
    output.write(result, gid);
}
