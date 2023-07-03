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
    
//�܂��A���_���C�e�B���O�E���ʒ��a�̃��C�e�B���O���s���Ă���.
        Pass
{
        
        Tags {  "LightMode"="ForwardBase" }

            CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
            // VERTEXLIGHT_ON�Ȃǂ���`���ꂽ�o���A���g�����������
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
    //���C�e�B���O�ɕK�v�ȃ����o�l��v2f�\���̂Ƃ��Ē�`����. 
    LIGHTING_COORDS(4,5)
};

//maintex�̒l��ݒ�..
sampler2D _MainTex;
half4 _MainTex_ST;
//���C�g�J���[..
half4 _LightColor0;


v2f vert(appdata v)
{
    v2f o = (v2f) 0;

    return o;
}

        ENDCG
}

//���̌�A�������C�g�������o�[�W������pass2�ɏ���.
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
    //�A�E�g�v�b�g�p�ɕϐ��錾.
    v2f o = (v2f)0;
    o.vertex = UnityObjectToClipPos(v.vertex);
    //TRANSFORM_TEX��Unity�̃^�C�����O�Ȃǂ��n���h�����Ă����}�N��.
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    //���[���h��ԏ�ł̒��_�@��
    o.normal = UnityObjectToWorldNormal(v.normal);
    //���[���h��ԏ�ł̒��_�ʒu.
    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
    half nl = max(0, dot(o.normal,_WorldSpaceLightPos0.xyz));
    //�J���[�f�B�q���[�W�����ݒ�.
    o.diff = nl * _LightColor0;
    return o;
}

            fixed4 frag(v2f i) : SV_Target
{
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
    //_WorldSpaceLightPos0.w�̓f�B���N�V���i�����C�g�Ȃ�0�A����ȊO�Ȃ�1.
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
