// An old television: a curved glass, lines, and colours that don't quite meet.
// xbox: tube
// values[0].x: how strongly.
float4 effect(float2 uv, float4 color)
{
    float much = values[0].x;
    float2 p = uv * 2.0 - 1.0;
    p = p * (1.0 + 0.09 * much * dot(p, p));
    float2 at = p * 0.5 + 0.5;
    if (at.x < 0.0 || at.x > 1.0 || at.y < 0.0 || at.y > 1.0)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }
    float2 off = float2(0.0016 * much, 0.0);
    float3 seen = float3(picture(at + off).r, picture(at).g, picture(at - off).b);
    float lines = 0.5 + 0.5 * sin(at.y * size.y * 1.5708);
    float mask = 0.85 + 0.15 * sin(at.x * size.x * 2.0944);
    seen = lerp(seen, seen * (0.72 + 0.42 * lines) * mask * 1.18, much);
    float edge = saturate(1.15 - dot(p, p) * 0.34);
    return float4(seen * edge, 1.0);
}
