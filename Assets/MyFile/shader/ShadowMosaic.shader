Shader"NemukeIndustry/ShadowMosaic"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        PASS
{
    CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

//頂点データ取得.
struct appdata
{
    half4 vertex : POSITION;
    half2 uv : TEXCOORD0;
    half3 normal : NORMAL;
};

struct v2f
{
    half4 vertex : SV_POSITION;
    half2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    half3 worldPos : TEXCOORD3;
            V2F_SHADOW_CASTER;
            UNITY_VERTEX_OUTPUT_STEREO
};

sampler2D _MainTex;
float4 _MainTex_ST;

v2f vert(appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
    return o;
}

fixed4 frag(v2f i) : SV_TARGET
{
    float4 col;
            SHADOW_CASTER_FRAGMENT(i)
    return col;
}
        
        ENDCG
        }
    }
}
