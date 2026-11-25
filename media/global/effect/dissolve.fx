// Burns away. values[0].x: how far, 0 to 1; values[1]: the colour of the edge.
// xbox: dissolve
float hash3(float3 p)
{
    return frac(sin(dot(p, float3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float noise3(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = lerp(lerp(hash3(i), hash3(i + float3(1.0, 0.0, 0.0)), f.x), lerp(hash3(i + float3(0.0, 1.0, 0.0)), hash3(i + float3(1.0, 1.0, 0.0)), f.x), f.y);
    float b = lerp(lerp(hash3(i + float3(0.0, 0.0, 1.0)), hash3(i + float3(1.0, 0.0, 1.0)), f.x), lerp(hash3(i + float3(0.0, 1.0, 1.0)), hash3(i + float3(1.0, 1.0, 1.0)), f.x), f.y);
    return lerp(a, b, f.z);
}

float4 paint(float4 color, float2 uv, float3 place, float3 normal, inout float glow)
{
    float n = noise3(place * 6.0) * 0.7 + noise3(place * 17.0) * 0.3;
    float left = n - values[0].x * 1.1;
    float edge = 1.0 - smoothstep(0.0, 0.1, left);
    glow = max(glow, edge);
    float3 burnt = lerp(color.rgb, values[1].rgb * (0.6 + edge), edge * step(0.001, values[0].x));
    return float4(burnt, left < 0.0 ? 0.0 : color.a);
}
