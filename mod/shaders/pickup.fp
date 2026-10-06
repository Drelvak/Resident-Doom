// Original world-only item texels. Self-lit material cannot illuminate the room.
vec4 Process(vec4 color)
{
 vec4 texel=getTexel(vTexCoord.st);
 return vec4(min(texel.rgb*2.0,vec3(1.0)),texel.a);
}
