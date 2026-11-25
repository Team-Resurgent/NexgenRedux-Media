// Rock that has not set. values[0].x: how hot.
// xbox: lava
float hash2(float2 p)
{
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float noise2(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(hash2(i), hash2(i + float2(1.0, 0.0)), f.x), lerp(hash2(i + float2(0.0, 1.0)), hash2(i + float2(1.0, 1.0)), f.x), f.y);
}

float4 paint(float4 color, float2 uv, float3 place, float3 normal, inout float glow)
{
    float2 p = place.xy * 2.2 + place.zx * 1.3;
    float n = noise2(p + float2(time * 0.22, 0.0)) * 0.6 + noise2(p * 2.3 - float2(0.0, time * 0.31)) * 0.4;
    float crack = pow(saturate(1.0 - abs(n - 0.5) * 5.0), 2.0) * values[0].x;
    glow = saturate(crack * 1.4);
    float3 rock = float3(0.12, 0.1, 0.1) * (0.6 + n);
    return float4(lerp(rock, lerp(float3(1.0, 0.25, 0.02), float3(1.0, 0.9, 0.4), crack), saturate(crack * 1.6)), 1.0);
}
