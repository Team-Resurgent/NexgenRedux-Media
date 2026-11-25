// A signal that is breaking up.
// values[0].x: how badly.
float hash(float2 p)
{
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float4 effect(float2 uv, float4 color)
{
    float beat = floor(time * 12.0);
    float row = floor(uv.y * 24.0);
    float jump = step(0.86, hash(float2(row, beat))) * (hash(float2(beat, row)) - 0.5) * 0.14 * values[0].x;
    float2 at = uv + float2(jump, 0.0);
    float split = (0.003 + 0.012 * step(0.8, hash(float2(beat, 3.0)))) * values[0].x;
    float3 seen = float3(picture(at + float2(split, 0.0)).r, picture(at).g, picture(at - float2(split, 0.0)).b);
    float2 block = floor(uv * float2(20.0, 12.0));
    float bad = step(1.0 - 0.02 * values[0].x, hash(block + beat));
    return float4(lerp(seen, float3(hash(block), hash(block + 1.0), hash(block + 2.0)), bad * 0.7), 1.0);
}
