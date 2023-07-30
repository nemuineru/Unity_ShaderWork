Shader"Unlit/Custom_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SubTex ("ShadowType", 2D) = "white" {}
        _ShadowSize ("ShadowSize", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

//appdata has a vert position, vert normals ,and also Texcoords.(like UV0 , UV1..)
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

            // v2f is pipeline for vert - frag numbers;
struct v2f
{
    float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)    
    float4 Spos : TEXCOORD1;
    float3 normal : NORMAL;
    float4 vertex : SV_POSITION;
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _SubTex;
float4 _SubTex_ST;
float _ShadowSize;

            //surf is the simplest way to emit the shader.
            //vert -> frag is might be complicated, but might be powerful.

            //vert :: converts vert, light data to packaged color, uv, screenpos..
v2f vert(appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    //ComputeScreenPos : fixed4 -> screenpos x,y , screenwidth w,h
    o.Spos = ComputeScreenPos(o.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
    return o;
}
            
            //frag.. : this is like a pixel shader. 
            fixed4 frag(v2f i) : SV_Target
{
    float2 pos = i.vertex.xy;
            //ƒ‰ƒCƒg‚ð•`ŽÊ..
    float Light = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz));
    float ColThread_1 = 0.01f;
    float ColThread_2 = 0.3f;
    //Set the light value.
    Light = Light > ColThread_1 ? Light > ColThread_2 ? 1.0 : 0.5 : 0.0;
    // sample the texture, and LightBakes
    float patternCol = distance(float2(0, 0), pos);
    float4 col = tex2D(_MainTex, i.uv) * Light;
    
    //
    float2 screenResl2 = float2(max(1.0, _ScreenParams.x / _ScreenParams.y),
    max(1.0 , _ScreenParams.y / _ScreenParams.x));
    //projects Screen UV. 
    float2 posUV = float2(i.Spos.x / i.Spos.w * screenResl2.x, i.Spos.y / i.Spos.w * screenResl2.y);
    float4 SCol = tex2D(_SubTex, frac(posUV * _ShadowSize));
    
    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col * SCol;

}
            //Set End of rendering.
            ENDCG
        }
    }
}
