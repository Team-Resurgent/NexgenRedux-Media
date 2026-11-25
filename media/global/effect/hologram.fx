// Light in the shape of something. values[0]: its colour.
// xbox: hologram
float4 paint(float4 color, float2 uv, float3 place, float3 normal, inout float glow)
{
    float lines = 0.55 + 0.45 * sin(place.y * 70.0 - time * 6.0);
    float band = smoothstep(0.96, 1.0, sin(place.y * 2.2 - time * 2.4));
    float flicker = 0.9 + 0.1 * sin(time * 37.0);
    float rim = pow(1.0 - abs(normal.z), 2.0);
    glow = 1.0;
    return float4(values[0].rgb * (0.25 + lines * 0.5 + rim * 0.6 + band) * flicker, 0.35 + 0.4 * lines + band * 0.5);
}
