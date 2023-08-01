Shader "NemukeIndustry/ShadowTone_PassWork"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        UsePass "NemukeIndustry/Lighting/FWBase"
        UsePass "NemukeIndustry/Lighting/FWAdd"
        GrabPass { "_GLightVal" }
        pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            //maintexの値を設定..
            sampler2D _MainTex;
            half4 _MainTex_ST;

            sampler2D _GLightVal;
            //ライトカラー..
            half4 _LightColor0;

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
                half4 grabPos : TEXCOORD8;
            };

            //vert :: converts vert, light data to packaged color, uv, screenpos..
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                //ComputeScreenPos : fixed4 -> screenpos x,y , screenwidth w,h
                o.Spos = ComputeScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                            UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i)  : SV_Target
            {
                half4 col = tex2D(_MainTex,i.uv);
                half4 ShadowCol = tex2Dproj(_GLightVal,i.grabPos);
                return col * ShadowCol;
            }
            ENDCG
        }
    }
}
