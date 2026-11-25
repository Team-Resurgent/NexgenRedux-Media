// Large squares, and few colours.
// xbox: pixels
// values[0].x: how many across; values[0].y: how many steps of each colour.
float4 effect(float2 uv, float4 color)
{
    float across = max(values[0].x, 8.0);
    float2 cells = float2(across, floor(across * size.y / size.x));
    float2 at = (floor(uv * cells) + 0.5) / cells;
    float steps = max(values[0].y, 2.0);
    float2 place = fmod(floor(uv * cells), 2.0);
    float dither = (place.x * 2.0 + place.y * 3.0 - place.x * place.y * 4.0) / 4.0 - 0.375;
    float3 seen = picture(at).rgb + dither / steps * 0.7;
    return float4(floor(saturate(seen) * steps + 0.5) / steps, 1.0);
}
