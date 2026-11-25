// Warm lights, cool shadows and darker corners.
// values[0].x: how strongly; values[0].y: how dark the corners.
float4 effect(float2 uv, float4 color)
{
    float3 seen = color.rgb;
    float bright = dot(seen, float3(0.299, 0.587, 0.114));
    float3 toned = lerp(seen * float3(0.86, 0.95, 1.14), seen * float3(1.14, 1.02, 0.84), smoothstep(0.1, 0.8, bright));
    toned = lerp(float3(bright, bright, bright), toned, 1.18);
    toned = toned * toned * (3.0 - 2.0 * toned) * 0.45 + toned * 0.55;
    float2 p = uv - 0.5;
    float corner = 1.0 - values[0].y * smoothstep(0.25, 0.85, length(p));
    return float4(lerp(seen, toned, values[0].x) * corner, 1.0);
}
