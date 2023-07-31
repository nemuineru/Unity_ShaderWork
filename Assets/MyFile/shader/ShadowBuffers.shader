Shader"NemukeIndustry/ShadowBuffer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Range ("ShadowRange", float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }        

    
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
                
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                //�V���h�E�T���v����ݒ肷��B
            //���_�V�F�[�_���ݒ肳��Ă���Ȃ�
                #if UNITY_SHOULD_SAMPLE_SH

                #if defined(VERTEXLIGHT_ON)
                
                //unity�r���g�C���̃��C�g�|�W�V������(�f�t�H���g�łS)

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
                half4 col = half4(1,1,1,1);

                // AutoLight�ɒ�`����Ă���}�N���Ō������v�Z����
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
                half3 diff = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz)) * _LightColor0 * attenuation;
                col.rgb *= diff + i.ambient;
                return col;
            }
        ENDCG        
        }



//���̌�A�������C�g�������o�[�W������pass2�ɏ���.
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
                //�A�E�g�v�b�g�p�ɕϐ��錾.
                v2f o = (v2f) 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //TRANSFORM_TEX��Unity�̃^�C�����O�Ȃǂ��n���h�����Ă����}�N��.
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //���[���h��ԏ�ł̒��_�@��
                o.normal = UnityObjectToWorldNormal(v.normal);
                //���[���h��ԏ�ł̒��_�ʒu.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                half nl = max(0, dot(o.normal, _WorldSpaceLightPos0.xyz));
                //�J���[�f�B�q���[�W�����ݒ�.
                o.diff = nl * _LightColor0;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = half4(1,1,1,1);
                //_WorldSpaceLightPos0.w�̓f�B���N�V���i�����C�g�Ȃ�0�A����ȊO�Ȃ�1.
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
        
        GrabPass { "_GPassTex"} 

//���܂ł̃��C�e�B���O�ݒ���l��..
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "./ShadowTone_CustonCGINC/CommonFunction.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                half4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                half4 diff : COLOR0;
                half3 normal : TEXCOORD1;
                half3 ambient : TEXCOORD2;
                half3 worldPos : TEXCOORD3;
                half4 grabpos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _LightColor0;
            float _Range;
            sampler2D _GPassTex;

            v2f vert(appdata v)
            {
                //�A�E�g�v�b�g�p�ɕϐ��錾.
                v2f o = (v2f) 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //TRANSFORM_TEX��Unity�̃^�C�����O�Ȃǂ��n���h�����Ă����}�N��.
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //���[���h��ԏ�ł̒��_�@��
                o.normal = UnityObjectToWorldNormal(v.normal);
                //���[���h��ԏ�ł̒��_�ʒu.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                half nl = max(0, dot(o.normal, _WorldSpaceLightPos0.xyz));
                //�J���[�f�B�q���[�W�����ݒ�.
                o.diff = nl * _LightColor0;
                o.grabpos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex,i.uv);
                half4 sh = tex2Dproj(_GPassTex, i.grabpos);
                float X = RGBA2BW(sh) > _Range ? 1.0 : pow(RGBA2BW(sh),2.0);
                return col * X;
            }            
            ENDCG
        }
    }
}