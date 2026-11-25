// Outlines and flat colours, as if drawn.
// xbox: ink
float level(float2 uv)
{
    return dot(picture(uv).rgb, float3(0.299, 0.587, 0.114));
}

float4 effect(float2 uv, float4 color)
{
    float2 e = 1.25 / size;
    float across = level(uv + float2(e.x, 0.0)) - level(uv - float2(e.x, 0.0));
    float down = level(uv + float2(0.0, e.y)) - level(uv - float2(0.0, e.y));
    float edge = smoothstep(0.06, 0.2, length(float2(across, down)));
    float3 soft = (color.rgb * 2.0 + picture(uv + e * 2.0).rgb + picture(uv - e * 2.0).rgb) * 0.25;
    float3 flat3 = floor(soft * 5.0 + 0.5) / 5.0;
    return float4(lerp(lerp(soft, flat3, 0.7), float3(0.06, 0.05, 0.09), edge), 1.0);
}
