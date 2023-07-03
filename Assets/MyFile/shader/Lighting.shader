Shader"NemukeIndustry/Lighting"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Tags { "RenderType" = "Opaque" }
        LOD 100
    
//まず、頂点ライティング・球面調和のライティングを行っている.
        Pass
{
        
        Tags {  "LightMode"="ForwardBase" }

            CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
            // VERTEXLIGHT_ONなどが定義されたバリアントが生成される
           #pragma multi_compile_fwdbase
            
           #include "UnityCG.cginc"
           #include "AutoLight.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL0;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 diff : COLOR0;
    float3 normal : TEXCOORD1;
    half3 ambient : TEXCOORD2;
    half3 worldPos : TEXCOORD3;
    //ライティングに必要なメンバ値をv2f構造体として定義する. 
    LIGHTING_COORDS(4,5)
};

//maintexの値を設定..
sampler2D _MainTex;
half4 _MainTex_ST;
//ライトカラー..
half4 _LightColor0;


v2f vert(appdata v)
{
    v2f o = (v2f) 0;

    return o;
}

        ENDCG
}

//その後、複数ライトを扱うバージョンをpass2に書く.
        Pass
        {
        Tags {  "LightMode"="ForwardAdd" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
           #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc" 
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 diff : COLOR0;
    float3 normal : TEXCOORD1;
    half3 ambient : TEXCOORD2;
    half3 worldPos : TEXCOORD3;
    float4 vertex : SV_POSITION;
};

sampler2D _MainTex;
float4 _MainTex_ST;

v2f vert(appdata v)
{
    //アウトプット用に変数宣言.
    v2f o = (v2f)0;
    o.vertex = UnityObjectToClipPos(v.vertex);
    //TRANSFORM_TEXはUnityのタイリングなどをハンドラしてくれるマクロ.
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    //ワールド空間上での頂点法線
    o.normal = UnityObjectToWorldNormal(v.normal);
    //ワールド空間上での頂点位置.
    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
    half nl = max(0, dot(o.normal,_WorldSpaceLightPos0.xyz));
    //カラーディヒュージョン設定.
    o.diff = nl * _LightColor0;
    return o;
}

            fixed4 frag(v2f i) : SV_Target
{
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
    //_WorldSpaceLightPos0.wはディレクショナルライトなら0、それ以外なら1.
    half3 lightDir;
    if (_WorldSpaceLightPos0.w > 0)
    {
        lightDir = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
    }
    else
    {
        lightDir = _WorldSpaceLightPos0;
    }
    lightDir = normalize(lightDir);
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
    half3 diff = max(0, dot(i.normal, lightDir)) * i.diff * attenuation;
    col.rgb *= diff;
    
    return col ;
}
            ENDCG
        }
    }
}
