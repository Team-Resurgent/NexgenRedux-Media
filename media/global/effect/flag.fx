// Cloth in the wind, held along its left side. values[0].x: how hard it blows.
// xbox: flag
#define MOVES
float3 move(float3 place, float3 normal, float2 uv)
{
    float out1 = uv.x * values[0].x;
    return place + float3(0.0, sin(uv.x * 9.0 - time * 7.0) * 0.03 * out1, sin(uv.x * 11.0 - time * 8.0 + uv.y * 2.0) * 0.16 * out1 + sin(uv.x * 5.0 - time * 5.0) * 0.12 * out1);
}

float4 paint(float4 color, float2 uv, float3 place, float3 normal, inout float glow)
{
    float fold = 0.82 + 0.18 * cos(uv.x * 11.0 - time * 8.0 + uv.y * 2.0);
    float stripe = step(0.5, frac(uv.y * 3.0 + uv.x * 0.6));
    return float4(lerp(color.rgb, values[1].rgb, stripe) * fold, 1.0);
}
