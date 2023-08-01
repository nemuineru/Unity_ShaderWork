// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"NemukeIndustry/ShadowToned"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _ToneTex ("Tone Texrure", 2D) = "white" {}
        _ShadowToneSize ("ShadowToneSize", float) = 0.2
        _ShadowToneStrength ("Strength", Range(0.0,1.0)) =  0.5
        _ShadowToneLength ("Length", float) =  0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
    
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
                #include "./ShadowTone_CustonCGINC/CustomFunction.cginc"

    struct appdata
            {
                float4 vertex : POSITION0;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {   
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                half3 ambient : TEXCOORD2;
                half3 worldPos : TEXCOORD3;
                float4 diff : COLOR0;
                float4 screenPos : COLOR4;
                //ライティングに必要なメンバ値をv2f構造体として定義する. 
                LIGHTING_COORDS(4,5)
            };

            //maintexの値を設定..
            sampler2D _MainTex;
            sampler2D _ToneTex;
            float _ShadowToneSize;
            float _ShadowToneStrength;
            float _ShadowToneLength;
            half4 _MainTex_ST;
            //ライトカラー..
            half4 _LightColor0;

            v2f vert(appdata v)
            {
                v2f o = (v2f) 0;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);

                //シャドウサンプラを設定する。
                //頂点シェーダが設定されているなら
                #if UNITY_SHOULD_SAMPLE_SH

                #if defined(VERTEXLIGHT_ON)
                
                //unityビルトインのライトポジション数(デフォルトで４)
                //o.ambientはライト情報.

                o.ambient = Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                    unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, o.worldPos, o.normal
                );

                #endif

                o.ambient += max(0, ShadeSH9(float4(o.normal, 1)));
                #else

                o.ambient = 0;

                #endif

                return o;
            }

        fixed4 frag(v2f i) : SV_Target
        {
            //多分これでセルサイズに応じた区分けが出来るはず..
            float2 EXscreenPos = ToneMapper(i.screenPos, _ShadowToneSize, i.worldPos);

            // AutoLightに定義されているマクロで光減衰を計算する。
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
            half3 diff = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz)) * _LightColor0 * attenuation;
            float sdw = diff + i.ambient;
            
            float sTonePower = 1 - sdw;
            
            bool setTone = true;

            half expandness = pow(sdw / _ShadowToneStrength , (_ShadowToneLength) * 2.0);
            if(expandness > 2.0)
            {
                expandness = expandness * expandness;
                if(expandness > 16.0)
                {
                    setTone = false;
                }
            }
            half2 uv_ex = UvExpander(EXscreenPos,expandness);
            half4 col = tex2D(_MainTex, i.uv);
            half4 tone = tex2D(_ToneTex, uv_ex);

            //half lz = UVdebugGrid(uv_ex,0.01,half3(1,1,1));
            if(setTone)
            col.rgb *= tone;
            //col.rgb *= (1 - lz) * tone;
            return col;

        }            
    ENDCG        
    }



    //その後、複数ライトを扱うバージョンをpass2に書く.
    Pass{
        Tags {  "LightMode"="ForwardAdd" }

        Blend One One
        ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
                #include "./ShadowTone_CustonCGINC/CustomFunction.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 diff : COLOR0;
                float3 normal : TEXCOORD1;
                half3 ambient : TEXCOORD2;
                half3 worldPos : TEXCOORD3;
                float4 vertex : SV_POSITION;
                float4 screenPos : COLOR4;
                LIGHTING_COORDS(4,5)
            };

            sampler2D _MainTex;
            sampler2D _ToneTex;
            float _ShadowToneSize;
            float _ShadowToneStrength;
            float _ShadowToneLength;
            half4 _MainTex_ST;
            half4 _LightColor0;

            v2f vert(appdata v)
            {
                //アウトプット用に変数宣言.
                v2f o = (v2f) 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //TRANSFORM_TEXはUnityのタイリングなどをハンドラしてくれるマクロ.
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //ワールド空間上での頂点法線
                o.normal = UnityObjectToWorldNormal(v.normal);
                //ワールド空間上での頂点位置.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                half nl = max(0, dot(o.normal, _WorldSpaceLightPos0.xyz));
                //カラーディヒュージョン設定.
                o.diff = nl * _LightColor0;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
        {
            //_WorldSpaceLightPos0.wはディレクショナルライトなら0、それ以外なら1.
            half3 lightDir;
            if (_WorldSpaceLightPos0.w > 0)
            {
                lightDir = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
            }
            else
            {
                lightDir = _WorldSpaceLightPos0.xyz;
            }
            lightDir = normalize(lightDir);
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
            half3 diff = max(0, dot(i.normal, lightDir)) * _LightColor0 * attenuation;

            //多分これでセルサイズに応じた区分けが出来るはず..
            float2 EXscreenPos = ToneMapper(i.screenPos, _ShadowToneSize, i.worldPos);

            // AutoLightに定義されているマクロで光減衰を計算する
            float sdw = diff + i.ambient;
            float sTonePower = 1 - sdw;

            //得られたこのExScreenPosはそのまま使うとチラツキが発生するので..
            float2 dx = ddx(EXscreenPos);
            float2 dy = ddy(EXscreenPos);

            bool setTone = true;

            half expandness = pow(sdw / _ShadowToneStrength , (_ShadowToneLength) * 2.0);
            if(expandness > 2.0)
            {
                expandness = expandness * expandness;
                if(expandness > 16.0)
                {
                    setTone = false;
                }
            }
            half2 uv_ex = UvExpander(EXscreenPos,expandness);
            half4 col = tex2D(_MainTex, i.uv);
            half4 tone = tex2D(_ToneTex, uv_ex);

            //half lz = UVdebugGrid(uv_ex,0.01,half3(1,1,1));
            if(setTone)
            col.rgb *= tone;
            //col.rgb *= (1 - lz) * tone;
            
            return col;
        }

            ENDCG
        }
    }
}
