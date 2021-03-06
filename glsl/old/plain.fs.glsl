//#version 320 es

precision mediump float;
precision mediump samplerBuffer;

uniform samplerBuffer msdf;

in rgba_t vertexRGBA;
flat in int vertexOffsetTex;
flat in ivec2 vertexDimsTex;
flat in vec2 vertexDimsTexOffset;
in uv_t vertexUV;

in vec3 vBC;

layout(location = 0) out vec4 color;

void main()
{
    // Note UV's v coord flipped in vertex shader
    
    // base + ux + (vy * width)
    
    //vec2 size = vec2(57.0,112.0);
    ////vec2 texcoord = vec2(vertexUV.u, vertexUV.v) * size;
    //ivec2 coord = ivec2(texcoord);
    //color = texelFetch(msdf, coord.x + (coord.y * 58));
    
    // Switch B and R due to Pango layout
    vec4 samp = filter_bilinear(msdf, 
                                vertexOffsetTex,
                                vertexDimsTex,
                                vertexUV,
                                vertexDimsTexOffset);
    color = vec4(samp.b, samp.g, samp.r, samp.a);
}

