Shader"NemukeIndustry/ShadowToned"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowToneSize ("ShadowToneSize", float) = 0.2
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
                float4 screenPos : TexCoord4;
                //ライティングに必要なメンバ値をv2f構造体として定義する. 
                LIGHTING_COORDS(4,5)
            };

            //maintexの値を設定..
            sampler2D _MainTex;
            float _ShadowToneSize;
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
                    half4 col = tex2D(_MainTex, i.uv);
                    //テクスチャのカラー設定..


                    float2 screenPos = i.screenPos.xy / i.screenPos.w;
                    float2 screenResl2 = float2(max(1.0, _ScreenParams.x / _ScreenParams.y),
                    max(1.0 , _ScreenParams.y / _ScreenParams.x));
                    float2 cellsize = float2(_ShadowToneSize,_ShadowToneSize) * screenResl2;

                    //オブジェクトのローカルポジション..
                    float3 ObjLPos = i.worldPos - mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;

                    float ObjCameraDist = distance(ObjLPos , _WorldSpaceCameraPos);

                    screenPos *= cellsize * ObjCameraDist;
                    screenPos = frac(screenPos);

                    // AutoLightに定義されているマクロで減衰を計算する
                    UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
                    half3 diff = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz)) * _LightColor0 * attenuation;
                    col.rgb *= half3(screenPos.x,screenPos.y,0);//diff + i.ambient;
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
                LIGHTING_COORDS(4, 5)  
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
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
                half nl = max(0, dot(o.normal, _WorldSpaceLightPos0.xyz));
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
                lightDir = _WorldSpaceLightPos0.xyz;
            }
            lightDir = normalize(lightDir);
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
            half3 diff = max(0, dot(i.normal, lightDir)) * _LightColor0 * attenuation;
            col.rgb *= diff;
            
            return col;
        }
            ENDCG
        }
    }
}
