float2 WorldToScreenPos(fixed3 pos);
float2 ToneMapper(half4 in_Screenpos, half _ShadowToneSize, half3 WPos);

float2 ToneMapper(half4 in_Screenpos, half _ShadowToneSize, half3 WPos)
{
    float2 screenPos = (in_Screenpos.xy) / in_Screenpos.w;
    float2 screenResl2 = float2(max(1.0, _ScreenParams.x / _ScreenParams.y),
    max(1.0 , _ScreenParams.y / _ScreenParams.x));
    float2 cellsize = float2(_ShadowToneSize,_ShadowToneSize) * screenResl2;


    //�I�u�W�F�N�g�̃��[�J���|�W�V����..
    float3 ObjLPos = WPos - mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;
    float3 object_CenterWPos = (WPos - ObjLPos);
    float2 object_centerCamPos = WorldToScreenPos(object_CenterWPos);

    float ObjCameraDist = distance(object_CenterWPos , _WorldSpaceCameraPos);

    //��������ŃZ���T�C�Y�ɉ������敪�����o����͂�..
    float2 EXscreenPos = screenPos * cellsize * ObjCameraDist + (half2(0.5,0.5) - object_centerCamPos) * cellsize * ObjCameraDist;
    //���̂܂܂̏�Ԃ��ƃs�N�Z���ʒu�ɒ���t���Ă����Ȃ�..���ςɊg�傳�ꂽ�肷��͖̂����Ȃ�.
    EXscreenPos = frac(EXscreenPos - half2(0.5,0.5) * ObjCameraDist * cellsize );

    // AutoLight�ɒ�`����Ă���}�N���Ō������v�Z����

    return EXscreenPos;
}

//Unity�t�H�[�����ɓ���������.
//���[���h�|�W�V�������J�������W�ɕϊ�.
float2 WorldToScreenPos(fixed3 pos)
{
    pos = normalize(pos - _WorldSpaceCameraPos)*(_ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y))+_WorldSpaceCameraPos;
    float2 uv =0;
    fixed3 toCam = mul(unity_WorldToCamera, pos);
    fixed camPosZ = toCam.z;
    fixed height = 2 * camPosZ / unity_CameraProjection._m11;
    fixed width = _ScreenParams.x / _ScreenParams.y * height;
    uv.x = (toCam.x + width / 2)/width;
    uv.y = (toCam.y + height / 2)/height;
    return uv;
}

float2 UvExpander(half2 uv_In, half UVExp)
{
    half2 uvout = half2(0.5,0.5) + (uv_In - half2(0.5,0.5)) * UVExp;
    return uvout;
}

half3 UVdebugGrid(half2 uv, half exps, half3 colors)
{
    return (abs(uv.x - 0.5) * 2.0 - (1.0 - exps) > 0 | 
    abs(uv.y - 0.5) * 2.0 - (1.0 - exps) > 0) ? colors : 0.0;
}