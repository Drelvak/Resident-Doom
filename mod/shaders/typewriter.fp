// Presentation exposure only. Original RC1180 bitmap and alpha are unchanged.
vec4 Process(vec4 color)
{
    vec4 texel = getTexel(vTexCoord.st);
    texel.rgb = min(texel.rgb * 1.5, vec3(1.0));
    return texel * color;
}
