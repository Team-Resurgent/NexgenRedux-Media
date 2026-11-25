// As if seen through water.
// values[0].x: how deep.
float4 effect(float2 uv, float4 color)
{
    float2 p = uv * float2(size.x / size.y, 1.0);
    float2 off = float2(sin(p.y * 22.0 + time * 2.1) + sin(p.y * 11.0 - time * 1.3 + p.x * 6.0), cos(p.x * 18.0 + time * 1.7) + cos(p.x * 9.0 - time * 1.1 + p.y * 5.0)) * 0.0035 * values[0].x;
    float3 seen = picture(uv + off).rgb;
    float light = pow(saturate(0.5 + 0.5 * sin(p.x * 14.0 + sin(p.y * 12.0 + time) * 2.0 + time * 1.2)), 6.0);
    return float4(lerp(seen, seen * float3(0.45, 0.8, 0.95) + float3(0.0, 0.05, 0.09), 0.75) + light * float3(0.05, 0.09, 0.08), 1.0);
}
