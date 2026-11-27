// God rays: light from the sky streaming past what stands in front of the sun. Use it after Space::draw.
// values[0].x: how strong; values[0].y: how far toward the sun each pixel looks, 0 to 1; values[1].rgb: their colour.
// Needs depthAt and sunPlace, which a GPU has where Space::depthEffects; elsewhere it isn't made.
float4 effect(float2 uv, float4 color)
{
    if (sunInFront < 0.5)
    {
        return color;
    }
    float2 toSun = (sunPlace - uv) * values[0].y;
    float2 stride = toSun / 40.0;
    // A different start for neighbours, so the steps don't show as bands.
    float2 along = uv + stride * frac(sin(dot(uv * size, float2(12.9898, 78.233))) * 43758.5453);
    float3 light = float3(0.0, 0.0, 0.0);
    float fade = 1.0;
    for (int i = 0; i < 40; i++)
    {
        along += stride;
        float sky = depthAt(along) >= farthest * 0.95 ? 1.0 : 0.0;
        light += picture(along).rgb * sky * fade;
        fade *= 0.955;
    }
    // Strongest looking toward the sun.
    float2 apart = (uv - sunPlace) * float2(size.x / size.y, 1.0);
    float near = 1.0 / (1.0 + dot(apart, apart) * 4.0);
    return float4(color.rgb + light / 40.0 * values[1].rgb * values[0].x * near, 1.0);
}
